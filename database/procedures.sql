SET NAMES utf8mb4;
USE qlst;

-- Chỉ triển khai hai Stored Procedure của Module 2.
-- Module đăng ký thành viên sẽ xử lý bằng Python OOP (UserDAO/CustomerDAO).
DROP PROCEDURE IF EXISTS sp_get_product_revenue_stats;
DROP PROCEDURE IF EXISTS sp_get_product_transactions;

DELIMITER $$

-- ============================================================================
-- 1. Thống kê mặt hàng theo doanh thu trong khoảng ngày (bao gồm cả hai đầu).
--    Doanh thu bán: hóa đơn completed, dòng chi tiết còn hiệu lực,
--                   ghi nhận theo invoices.invoice_date.
--    Hoàn trả:      returns completed, ghi nhận theo returns.completed_at.
--    Không dùng invoice_details.returned_quantity để trừ ngược kỳ bán.
--    Các giá trị ròng là DECIMAL có dấu; có thể âm.
-- ============================================================================
CREATE PROCEDURE sp_get_product_revenue_stats(
    IN p_start_date DATE,
    IN p_end_date   DATE
)
BEGIN
    IF p_start_date IS NULL
       OR p_end_date IS NULL
       OR p_start_date > p_end_date THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Khoang ngay thong ke khong hop le';
    END IF;

    SELECT
        p.product_id,
        p.name,
        p.brand,
        p.barcode,
        c.category_id,
        c.name AS category_name,
        p.price AS current_list_price,
        SUM(tx.quantity_sold) AS quantity_sold,
        SUM(tx.quantity_returned) AS quantity_returned,
        SUM(tx.quantity_sold) - SUM(tx.quantity_returned) AS net_quantity,
        SUM(tx.sales_revenue) AS sales_revenue,
        SUM(tx.refund_amount) AS refund_amount,
        SUM(tx.sales_revenue) - SUM(tx.refund_amount) AS net_revenue
    FROM (
        -- Một dòng hóa đơn là một giao dịch bán, không JOIN với returns.
        SELECT
            d.product_id,
            CAST(d.quantity AS DECIMAL(20, 0)) AS quantity_sold,
            CAST(0 AS DECIMAL(20, 0)) AS quantity_returned,
            (
                CAST(d.quantity AS DECIMAL(20, 0))
                * CAST(d.unit_price AS DECIMAL(30, 0))
                - CAST(d.discount_amount AS DECIMAL(30, 0))
            ) AS sales_revenue,
            CAST(0 AS DECIMAL(50, 0)) AS refund_amount
        FROM invoices AS i
        INNER JOIN invoice_details AS d
            ON d.invoice_id = i.invoice_id
           AND d.is_active = TRUE
        WHERE i.status = 'completed'
          AND i.invoice_date >= p_start_date
          AND i.invoice_date < DATE_ADD(p_end_date, INTERVAL 1 DAY)

        UNION ALL

        -- Mỗi phiếu trả completed là một giao dịch hoàn trả độc lập.
        SELECT
            d.product_id,
            CAST(0 AS DECIMAL(20, 0)) AS quantity_sold,
            CAST(r.quantity AS DECIMAL(20, 0)) AS quantity_returned,
            CAST(0 AS DECIMAL(50, 0)) AS sales_revenue,
            CAST(r.refund_amount AS DECIMAL(50, 0)) AS refund_amount
        FROM returns AS r
        INNER JOIN invoice_details AS d
            ON d.invoice_detail_id = r.invoice_detail_id
           AND d.is_active = TRUE
        INNER JOIN invoices AS i
            ON i.invoice_id = d.invoice_id
           AND i.status = 'completed'
        WHERE r.status = 'completed'
          AND r.completed_at >= p_start_date
          AND r.completed_at < DATE_ADD(p_end_date, INTERVAL 1 DAY)
    ) AS tx
    INNER JOIN products AS p
        ON p.product_id = tx.product_id
    INNER JOIN categories AS c
        ON c.category_id = p.category_id
    GROUP BY
        p.product_id,
        p.name,
        p.brand,
        p.barcode,
        c.category_id,
        c.name,
        p.price
    ORDER BY net_revenue DESC, quantity_sold DESC, p.product_id ASC;
END$$

-- ============================================================================
-- 2. Chi tiết các giao dịch của một mặt hàng trong khoảng ngày.
--    Mỗi hàng là một giao dịch bán hoặc một phiếu hoàn trả completed.
--    Các cột quantity_sold, quantity_returned, sales_revenue, refund_amount
--    cùng ngữ nghĩa với procedure tổng hợp nên có thể cộng để đối soát.
--    net_quantity / net_revenue có dấu: hoàn trả cho giá trị âm.
-- ============================================================================
CREATE PROCEDURE sp_get_product_transactions(
    IN p_product_id INT UNSIGNED,
    IN p_start_date DATE,
    IN p_end_date   DATE
)
BEGIN
    IF p_product_id IS NULL
       OR p_start_date IS NULL
       OR p_end_date IS NULL
       OR p_start_date > p_end_date THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Tham so thong ke khong hop le';
    END IF;

    SELECT
        tx.transaction_type,
        tx.transaction_at,
        tx.document_type,
        tx.document_id,
        tx.document_code,
        tx.product_id,
        p.name AS product_name,
        tx.invoice_id,
        tx.invoice_detail_id,
        tx.return_id,
        tx.channel,
        tx.quantity_sold,
        tx.quantity_returned,
        tx.quantity_sold - tx.quantity_returned AS net_quantity,
        tx.sales_revenue,
        tx.refund_amount,
        tx.sales_revenue - tx.refund_amount AS net_revenue,
        tx.unit_price,
        tx.original_line_discount,
        tx.unit_id,
        pu.serial_number,
        c.full_name AS customer_name,
        c.phone AS customer_phone
    FROM (
        SELECT
            'sale' AS transaction_type,
            i.invoice_date AS transaction_at,
            'invoice' AS document_type,
            i.invoice_id AS document_id,
            CONCAT('INV-', i.invoice_id) AS document_code,
            d.product_id,
            i.invoice_id,
            d.invoice_detail_id,
            NULL AS return_id,
            i.channel,
            CAST(d.quantity AS DECIMAL(20, 0)) AS quantity_sold,
            CAST(0 AS DECIMAL(20, 0)) AS quantity_returned,
            (
                CAST(d.quantity AS DECIMAL(20, 0))
                * CAST(d.unit_price AS DECIMAL(30, 0))
                - CAST(d.discount_amount AS DECIMAL(30, 0))
            ) AS sales_revenue,
            CAST(0 AS DECIMAL(50, 0)) AS refund_amount,
            d.unit_price,
            d.discount_amount AS original_line_discount,
            d.unit_id,
            i.customer_id
        FROM invoices AS i
        INNER JOIN invoice_details AS d
            ON d.invoice_id = i.invoice_id
           AND d.is_active = TRUE
        WHERE i.status = 'completed'
          AND d.product_id = p_product_id
          AND i.invoice_date >= p_start_date
          AND i.invoice_date < DATE_ADD(p_end_date, INTERVAL 1 DAY)

        UNION ALL

        SELECT
            'return' AS transaction_type,
            r.completed_at AS transaction_at,
            'return' AS document_type,
            r.return_id AS document_id,
            CONCAT('RET-', r.return_id) AS document_code,
            d.product_id,
            i.invoice_id,
            d.invoice_detail_id,
            r.return_id,
            i.channel,
            CAST(0 AS DECIMAL(20, 0)) AS quantity_sold,
            CAST(r.quantity AS DECIMAL(20, 0)) AS quantity_returned,
            CAST(0 AS DECIMAL(50, 0)) AS sales_revenue,
            CAST(r.refund_amount AS DECIMAL(50, 0)) AS refund_amount,
            d.unit_price,
            d.discount_amount AS original_line_discount,
            d.unit_id,
            i.customer_id
        FROM returns AS r
        INNER JOIN invoice_details AS d
            ON d.invoice_detail_id = r.invoice_detail_id
           AND d.is_active = TRUE
        INNER JOIN invoices AS i
            ON i.invoice_id = d.invoice_id
           AND i.status = 'completed'
        WHERE r.status = 'completed'
          AND d.product_id = p_product_id
          AND r.completed_at >= p_start_date
          AND r.completed_at < DATE_ADD(p_end_date, INTERVAL 1 DAY)
    ) AS tx
    INNER JOIN products AS p
        ON p.product_id = tx.product_id
    LEFT JOIN product_units AS pu
        ON pu.unit_id = tx.unit_id
    LEFT JOIN customers AS c
        ON c.customer_id = tx.customer_id
    ORDER BY
        tx.transaction_at DESC,
        tx.transaction_type ASC,
        tx.document_id DESC,
        tx.invoice_detail_id DESC;
END$$

DELIMITER ;
