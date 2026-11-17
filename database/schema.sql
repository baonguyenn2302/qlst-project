SET NAMES utf8mb4;
USE qlst;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS
    stock_movements, warranty_claim_history, warranty_claims, warranties,
    returns, payments, invoice_details, invoices,
    delivery_status_history, delivery_items, deliveries,
    order_status_history, order_details, orders, cart_items,
    shifts, import_details, imports, promotions, product_price_history,
    product_units, products, categories, suppliers,
    customers, employees, users, positions, roles;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Vai trò (quyết định chức năng được dùng)
CREATE TABLE roles (
    role_id  INT UNSIGNED NOT NULL AUTO_INCREMENT,
    code     VARCHAR(30)  NOT NULL,
    name     VARCHAR(100) NOT NULL,
    PRIMARY KEY (role_id),
    UNIQUE KEY uq_roles_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Chức vụ của nhân viên
CREATE TABLE positions (
    position_id  INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name         VARCHAR(50)  NOT NULL,
    PRIMARY KEY (position_id),
    UNIQUE KEY uq_positions_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Tài khoản đăng nhập (dùng chung cho nhân viên và khách hàng)
CREATE TABLE users (
    user_id        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    username       VARCHAR(50)  NOT NULL,
    password_hash  VARCHAR(255) NOT NULL,
    role_id        INT UNSIGNED NOT NULL,
    is_active      BOOLEAN      NOT NULL DEFAULT TRUE,
    last_login_at  DATETIME,
    created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id),
    UNIQUE KEY uq_users_username (username),
    CONSTRAINT fk_users_role
        FOREIGN KEY (role_id) REFERENCES roles (role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Nhân viên (admin, quản lí, kho, bán hàng, giao hàng)
CREATE TABLE employees (
    employee_id  INT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id      INT UNSIGNED NOT NULL,
    full_name    VARCHAR(100) NOT NULL,
    phone        VARCHAR(15),
    email        VARCHAR(100),
    hire_date    DATE         NOT NULL,
    position_id  INT UNSIGNED NOT NULL,
    is_active    BOOLEAN      NOT NULL DEFAULT TRUE,
    PRIMARY KEY (employee_id),
    UNIQUE KEY uq_employees_user (user_id),
    CONSTRAINT fk_employees_user
        FOREIGN KEY (user_id) REFERENCES users (user_id),
    CONSTRAINT fk_employees_position
        FOREIGN KEY (position_id) REFERENCES positions (position_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Khách hàng (thành viên có user_id; khách vãng lai có user_id = NULL)
CREATE TABLE customers (
    customer_id     INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    user_id         INT UNSIGNED,
    full_name       VARCHAR(100)    NOT NULL,
    phone           VARCHAR(15)     NOT NULL,
    email           VARCHAR(100),
    address         VARCHAR(255),
    loyalty_points  BIGINT UNSIGNED NOT NULL DEFAULT 0,
    registered_at   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    member_since    DATETIME,
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    PRIMARY KEY (customer_id),
    UNIQUE KEY uq_customers_user (user_id),
    UNIQUE KEY uq_customers_phone (phone),
    -- CV18: hồ sơ có tài khoản phải có ngày trở thành thành viên (và ngược lại).
    CONSTRAINT chk_customers_membership CHECK (
        (user_id IS NULL AND member_since IS NULL)
        OR (user_id IS NOT NULL AND member_since IS NOT NULL)
    ),
    -- Vấn đề B: ngày thành viên không trước ngày tạo hồ sơ.
    CONSTRAINT chk_customers_member_date CHECK (
        member_since IS NULL OR member_since >= registered_at
    ),
    CONSTRAINT fk_customers_user
        FOREIGN KEY (user_id) REFERENCES users (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Nhà cung cấp
CREATE TABLE suppliers (
    supplier_id  INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name         VARCHAR(100) NOT NULL,
    tax_code     VARCHAR(20),
    phone        VARCHAR(15),
    email        VARCHAR(100),
    address      VARCHAR(255),
    is_active    BOOLEAN      NOT NULL DEFAULT TRUE,
    PRIMARY KEY (supplier_id),
    UNIQUE KEY uq_suppliers_tax_code (tax_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. Danh mục sản phẩm
CREATE TABLE categories (
    category_id  INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name         VARCHAR(100) NOT NULL,
    is_active    BOOLEAN      NOT NULL DEFAULT TRUE,
    PRIMARY KEY (category_id),
    UNIQUE KEY uq_categories_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. Sản phẩm (mẫu máy). Nguồn nhập lưu ở imports/import_details, không lưu ở đây.
--    Không có CHECK price >= cost_price để cho phép xả kho.
CREATE TABLE products (
    product_id       INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    name             VARCHAR(150)     NOT NULL,
    brand            VARCHAR(50),
    barcode          VARCHAR(30),
    description      TEXT,
    image_url        VARCHAR(255),
    category_id      INT UNSIGNED     NOT NULL,
    price            BIGINT UNSIGNED  NOT NULL,
    cost_price       BIGINT UNSIGNED  NOT NULL,
    warranty_months  TINYINT UNSIGNED NOT NULL DEFAULT 12,
    is_serialized    BOOLEAN          NOT NULL DEFAULT TRUE,
    stock_quantity   INT UNSIGNED     NOT NULL DEFAULT 0,
    is_active        BOOLEAN          NOT NULL DEFAULT TRUE,
    PRIMARY KEY (product_id),
    UNIQUE KEY uq_products_barcode (barcode),
    KEY idx_products_category (category_id),
    FULLTEXT KEY ft_products_search (name, brand),
    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id) REFERENCES categories (category_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8.1 Khuyến mãi (áp dụng cho một sản phẩm hoặc một danh mục)
CREATE TABLE promotions (
    promotion_id     INT UNSIGNED NOT NULL AUTO_INCREMENT,
    product_id       INT UNSIGNED,
    category_id      INT UNSIGNED,
    discount_percent DECIMAL(5,2) NOT NULL,
    start_date       DATETIME     NOT NULL,
    end_date         DATETIME     NOT NULL,
    PRIMARY KEY (promotion_id),
    CONSTRAINT chk_promotions_target CHECK (
        (product_id IS NOT NULL AND category_id IS NULL)
        OR (product_id IS NULL AND category_id IS NOT NULL)
    ),
    CONSTRAINT chk_promotions_percent
        CHECK (discount_percent > 0 AND discount_percent <= 100),
    CONSTRAINT chk_promotions_dates CHECK (end_date > start_date),
    CONSTRAINT fk_promotions_product
        FOREIGN KEY (product_id) REFERENCES products (product_id),
    CONSTRAINT fk_promotions_category
        FOREIGN KEY (category_id) REFERENCES categories (category_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8.2 Lịch sử giá bán (effective_to NULL = đang có hiệu lực)
CREATE TABLE product_price_history (
    price_history_id  INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    product_id        INT UNSIGNED    NOT NULL,
    price             BIGINT UNSIGNED NOT NULL,
    effective_from    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    effective_to      DATETIME,
    PRIMARY KEY (price_history_id),
    KEY idx_price_history_product (product_id, effective_from),
    CONSTRAINT chk_price_history_dates
        CHECK (effective_to IS NULL OR effective_to > effective_from),
    CONSTRAINT fk_price_history_product
        FOREIGN KEY (product_id) REFERENCES products (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. Máy cụ thể có serial
CREATE TABLE product_units (
    unit_id           INT UNSIGNED NOT NULL AUTO_INCREMENT,
    product_id        INT UNSIGNED NOT NULL,
    serial_number     VARCHAR(50)  NOT NULL,
    status            ENUM('in_stock', 'reserved', 'sold', 'returned', 'damaged')
                      NOT NULL DEFAULT 'in_stock',
    import_detail_id  INT UNSIGNED NOT NULL,
    PRIMARY KEY (unit_id),
    UNIQUE KEY uq_product_units_serial (serial_number),
    UNIQUE KEY uq_product_units_unit_product (unit_id, product_id),
    KEY idx_product_units_product_status (product_id, status),
    KEY idx_product_units_import_detail_product (import_detail_id, product_id),
    CONSTRAINT fk_product_units_product
        FOREIGN KEY (product_id) REFERENCES products (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. Phiếu nhập hàng (mỗi phiếu có một nhà cung cấp; một sản phẩm có thể nhập từ nhiều nhà cung cấp)
CREATE TABLE imports (
    import_id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    import_date  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    supplier_id  INT UNSIGNED NOT NULL,
    employee_id  INT UNSIGNED NOT NULL,
    PRIMARY KEY (import_id),
    CONSTRAINT fk_imports_supplier
        FOREIGN KEY (supplier_id) REFERENCES suppliers (supplier_id),
    CONSTRAINT fk_imports_employee
        FOREIGN KEY (employee_id) REFERENCES employees (employee_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10.1 Chi tiết phiếu nhập
CREATE TABLE import_details (
    import_detail_id  INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    import_id         INT UNSIGNED    NOT NULL,
    product_id        INT UNSIGNED    NOT NULL,
    quantity          INT UNSIGNED    NOT NULL,
    unit_cost         BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (import_detail_id),
    UNIQUE KEY uq_import_details_detail_product (import_detail_id, product_id),
    CONSTRAINT chk_import_details_qty CHECK (quantity > 0),
    CONSTRAINT fk_import_details_import
        FOREIGN KEY (import_id) REFERENCES imports (import_id),
    CONSTRAINT fk_import_details_product
        FOREIGN KEY (product_id) REFERENCES products (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- CV5: import_details được tạo sau product_units nên FK ghép phải thêm ở đây.
ALTER TABLE product_units
    ADD CONSTRAINT fk_product_units_import_detail
        FOREIGN KEY (import_detail_id) REFERENCES import_details (import_detail_id),
    ADD CONSTRAINT fk_product_units_import_detail_product
        FOREIGN KEY (import_detail_id, product_id)
        REFERENCES import_details (import_detail_id, product_id);

-- 11. Ca làm việc của nhân viên bán hàng
CREATE TABLE shifts (
    shift_id      INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    employee_id   INT UNSIGNED    NOT NULL,
    opened_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    closed_at     DATETIME,
    opening_cash  BIGINT UNSIGNED NOT NULL DEFAULT 0,
    closing_cash  BIGINT UNSIGNED,
    status        ENUM('open', 'closed') NOT NULL DEFAULT 'open',
    PRIMARY KEY (shift_id),
    UNIQUE KEY uq_shifts_employee (shift_id, employee_id),
    CONSTRAINT chk_shifts_status_consistency CHECK (
        (status = 'open' AND closed_at IS NULL AND closing_cash IS NULL)
        OR (status = 'closed' AND closed_at IS NOT NULL AND closing_cash IS NOT NULL)
    ),
    CONSTRAINT chk_shifts_closed_after_opened
        CHECK (closed_at IS NULL OR closed_at >= opened_at),
    CONSTRAINT fk_shifts_employee
        FOREIGN KEY (employee_id) REFERENCES employees (employee_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 12. Giỏ hàng của khách
CREATE TABLE cart_items (
    customer_id  INT UNSIGNED NOT NULL,
    product_id   INT UNSIGNED NOT NULL,
    quantity     INT UNSIGNED NOT NULL,
    added_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (customer_id, product_id),
    CONSTRAINT chk_cart_items_qty CHECK (quantity > 0),
    CONSTRAINT fk_cart_items_customer
        FOREIGN KEY (customer_id) REFERENCES customers (customer_id),
    CONSTRAINT fk_cart_items_product
        FOREIGN KEY (product_id) REFERENCES products (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 13. Đơn hàng trực tuyến
--     Các CHECK viết dưới dạng không có phép trừ để tránh lỗi tràn BIGINT UNSIGNED.
CREATE TABLE orders (
    order_id                 INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    order_code               VARCHAR(20)     NOT NULL,
    customer_id              INT UNSIGNED    NOT NULL,
    order_date               DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    shipping_name            VARCHAR(100)    NOT NULL,
    shipping_phone           VARCHAR(15)     NOT NULL,
    shipping_address         VARCHAR(255)    NOT NULL,
    subtotal_amount          BIGINT UNSIGNED NOT NULL DEFAULT 0,
    discount_amount          BIGINT UNSIGNED NOT NULL DEFAULT 0,
    shipping_fee             BIGINT UNSIGNED NOT NULL DEFAULT 0,
    total_amount             BIGINT UNSIGNED NOT NULL DEFAULT 0,
    payment_method           ENUM('cash', 'card', 'bank_transfer', 'cod') NOT NULL,
    payment_status           ENUM('unpaid', 'paid') NOT NULL DEFAULT 'unpaid',
    status                   ENUM('pending', 'approved', 'delivering', 'delivered', 'cancelled')
                             NOT NULL DEFAULT 'pending',
    cancel_reason            VARCHAR(255),
    approved_by_employee_id  INT UNSIGNED,
    approved_at              DATETIME,
    PRIMARY KEY (order_id),
    UNIQUE KEY uq_orders_code (order_code),
    UNIQUE KEY uq_orders_order_customer (order_id, customer_id),
    KEY idx_orders_customer (customer_id),
    KEY idx_orders_status (status),
    CONSTRAINT chk_orders_discount
        CHECK (discount_amount <= subtotal_amount),
    CONSTRAINT chk_orders_total
        CHECK (total_amount + discount_amount = subtotal_amount + shipping_fee),
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers (customer_id),
    CONSTRAINT fk_orders_approved_by
        FOREIGN KEY (approved_by_employee_id) REFERENCES employees (employee_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 13.1 Chi tiết đơn hàng
CREATE TABLE order_details (
    order_detail_id  INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    order_id         INT UNSIGNED    NOT NULL,
    product_id       INT UNSIGNED    NOT NULL,
    quantity         INT UNSIGNED    NOT NULL,
    unit_price       BIGINT UNSIGNED NOT NULL,
    discount_amount  BIGINT UNSIGNED NOT NULL DEFAULT 0,
    promotion_id     INT UNSIGNED,
    PRIMARY KEY (order_detail_id),
    UNIQUE KEY uq_order_details_order_product (order_id, product_id),
    CONSTRAINT chk_order_details_qty CHECK (quantity > 0),
    CONSTRAINT chk_order_details_discount
        CHECK (discount_amount <= quantity * unit_price),
    CONSTRAINT fk_order_details_order
        FOREIGN KEY (order_id) REFERENCES orders (order_id),
    CONSTRAINT fk_order_details_product
        FOREIGN KEY (product_id) REFERENCES products (product_id),
    CONSTRAINT fk_order_details_promotion
        FOREIGN KEY (promotion_id) REFERENCES promotions (promotion_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 13.2 Lịch sử thay đổi trạng thái đơn hàng
CREATE TABLE order_status_history (
    history_id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    order_id            INT UNSIGNED NOT NULL,
    from_status         VARCHAR(20),
    to_status           VARCHAR(20)  NOT NULL,
    changed_by_user_id  INT UNSIGNED NOT NULL,
    reason              VARCHAR(255),
    changed_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (history_id),
    KEY idx_order_status_history_order (order_id),
    CONSTRAINT fk_order_status_history_order
        FOREIGN KEY (order_id) REFERENCES orders (order_id),
    CONSTRAINT fk_order_status_history_user
        FOREIGN KEY (changed_by_user_id) REFERENCES users (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 14. Phiếu xuất giao hàng
CREATE TABLE deliveries (
    delivery_id              INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    order_id                 INT UNSIGNED    NOT NULL,
    exported_by_employee_id  INT UNSIGNED    NOT NULL,
    delivery_staff_id        INT UNSIGNED    NOT NULL,
    exported_at              DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    delivered_at             DATETIME,
    status                   ENUM('delivering', 'delivered', 'failed')
                             NOT NULL DEFAULT 'delivering',
    failed_reason            VARCHAR(255),
    cod_collected_amount     BIGINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (delivery_id),
    KEY idx_deliveries_order (order_id),
    KEY idx_deliveries_staff_status (delivery_staff_id, status),
    CONSTRAINT chk_deliveries_status_consistency CHECK (
        (status = 'delivering' AND delivered_at IS NULL AND failed_reason IS NULL)
        OR (status = 'delivered' AND delivered_at IS NOT NULL AND failed_reason IS NULL)
        OR (status = 'failed' AND delivered_at IS NULL
            AND failed_reason IS NOT NULL AND TRIM(failed_reason) <> '')
    ),
    CONSTRAINT chk_deliveries_date CHECK (
        delivered_at IS NULL OR delivered_at >= exported_at
    ),
    CONSTRAINT fk_deliveries_order
        FOREIGN KEY (order_id) REFERENCES orders (order_id),
    CONSTRAINT fk_deliveries_exported_by
        FOREIGN KEY (exported_by_employee_id) REFERENCES employees (employee_id),
    CONSTRAINT fk_deliveries_staff
        FOREIGN KEY (delivery_staff_id) REFERENCES employees (employee_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 14.1 Chi tiết phiếu xuất
--     unit_id có khi hàng có serial. Một máy chỉ nằm trong một phiếu đang giao: kiểm tra trong code.
CREATE TABLE delivery_items (
    delivery_item_id  INT UNSIGNED NOT NULL AUTO_INCREMENT,
    delivery_id       INT UNSIGNED NOT NULL,
    order_detail_id   INT UNSIGNED NOT NULL,
    unit_id           INT UNSIGNED,
    quantity          INT UNSIGNED NOT NULL,
    PRIMARY KEY (delivery_item_id),
    KEY idx_delivery_items_unit (unit_id),
    CONSTRAINT chk_delivery_items_qty CHECK (quantity > 0),
    CONSTRAINT chk_delivery_items_unit_qty CHECK (unit_id IS NULL OR quantity = 1),
    CONSTRAINT fk_delivery_items_delivery
        FOREIGN KEY (delivery_id) REFERENCES deliveries (delivery_id),
    CONSTRAINT fk_delivery_items_order_detail
        FOREIGN KEY (order_detail_id) REFERENCES order_details (order_detail_id),
    CONSTRAINT fk_delivery_items_unit
        FOREIGN KEY (unit_id) REFERENCES product_units (unit_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 14.2 Lịch sử thay đổi trạng thái phiếu giao hàng
CREATE TABLE delivery_status_history (
    history_id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    delivery_id         INT UNSIGNED NOT NULL,
    from_status         VARCHAR(20),
    to_status           VARCHAR(20)  NOT NULL,
    changed_by_user_id  INT UNSIGNED NOT NULL,
    reason              VARCHAR(255),
    changed_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (history_id),
    KEY idx_delivery_status_history_delivery (delivery_id),
    CONSTRAINT fk_delivery_status_history_delivery
        FOREIGN KEY (delivery_id) REFERENCES deliveries (delivery_id),
    CONSTRAINT fk_delivery_status_history_user
        FOREIGN KEY (changed_by_user_id) REFERENCES users (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 15. Hóa đơn (quầy hoặc online)
--     Đơn online không có nhân viên bán quầy: người duyệt là orders.approved_by_employee_id,
--     người giao là deliveries.delivery_staff_id.
--     Hủy hóa đơn: status = 'cancelled' và is_active của các dòng chi tiết = FALSE (trong transaction).
CREATE TABLE invoices (
    invoice_id       INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    invoice_date     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    channel          ENUM('counter', 'online') NOT NULL,
    employee_id      INT UNSIGNED,                 -- NOT NULL với quầy, NULL với online
    customer_id      INT UNSIGNED,
    shift_id         INT UNSIGNED,                 -- bắt buộc với quầy
    order_id         INT UNSIGNED,                 -- bắt buộc với online
    subtotal_amount  BIGINT UNSIGNED NOT NULL DEFAULT 0,
    discount_amount  BIGINT UNSIGNED NOT NULL DEFAULT 0,
    shipping_fee     BIGINT UNSIGNED NOT NULL DEFAULT 0,
    total_amount     BIGINT UNSIGNED NOT NULL DEFAULT 0,
    status           ENUM('completed', 'cancelled') NOT NULL DEFAULT 'completed',
    PRIMARY KEY (invoice_id),
    UNIQUE KEY uq_invoices_order (order_id),
    KEY idx_invoices_order_customer (order_id, customer_id),
    KEY idx_invoices_shift_employee (shift_id, employee_id),
    KEY idx_invoices_date (invoice_date),
    CONSTRAINT chk_invoices_discount
        CHECK (discount_amount <= subtotal_amount),
    CONSTRAINT chk_invoices_total
        CHECK (total_amount + discount_amount = subtotal_amount + shipping_fee),
    CONSTRAINT chk_invoices_channel CHECK (
        (channel = 'counter' AND employee_id IS NOT NULL AND shift_id IS NOT NULL AND order_id IS NULL)
        OR (channel = 'online' AND employee_id IS NULL AND shift_id IS NULL AND order_id IS NOT NULL)
    ),
    -- CV13: online bắt buộc có khách hàng để FK ghép không bị bỏ qua do NULL.
    CONSTRAINT chk_invoices_online_customer CHECK (
        channel <> 'online' OR customer_id IS NOT NULL
    ),
    CONSTRAINT fk_invoices_employee
        FOREIGN KEY (employee_id) REFERENCES employees (employee_id),
    CONSTRAINT fk_invoices_customer
        FOREIGN KEY (customer_id) REFERENCES customers (customer_id),
    CONSTRAINT fk_invoices_shift
        FOREIGN KEY (shift_id) REFERENCES shifts (shift_id),
    CONSTRAINT fk_invoices_shift_employee
        FOREIGN KEY (shift_id, employee_id) REFERENCES shifts (shift_id, employee_id),
    CONSTRAINT fk_invoices_order
        FOREIGN KEY (order_id) REFERENCES orders (order_id),
    CONSTRAINT fk_invoices_order_customer
        FOREIGN KEY (order_id, customer_id) REFERENCES orders (order_id, customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 15.1 Chi tiết hóa đơn
--     Hàng có serial: unit_id khác NULL, quantity = 1.
--     active_unit_id chỉ có giá trị khi dòng còn hiệu lực (hóa đơn không bị hủy)
--     và máy chưa bị trả. Nhờ đó máy bị hủy hoặc trả có thể bán lại.
CREATE TABLE invoice_details (
    invoice_detail_id  INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    invoice_id         INT UNSIGNED    NOT NULL,
    product_id         INT UNSIGNED    NOT NULL,
    unit_id            INT UNSIGNED,
    quantity           INT UNSIGNED    NOT NULL DEFAULT 1,
    returned_quantity  INT UNSIGNED    NOT NULL DEFAULT 0,
    unit_price         BIGINT UNSIGNED NOT NULL,
    discount_amount    BIGINT UNSIGNED NOT NULL DEFAULT 0,
    promotion_id       INT UNSIGNED,
    is_active          BOOLEAN         NOT NULL DEFAULT TRUE,   -- FALSE khi hóa đơn bị hủy
    active_unit_id     INT UNSIGNED AS (
        CASE WHEN is_active = TRUE AND returned_quantity = 0 THEN unit_id END
    ) STORED,
    PRIMARY KEY (invoice_detail_id),
    KEY idx_invoice_details_unit (unit_id),
    KEY idx_invoice_details_unit_product (unit_id, product_id),
    UNIQUE KEY uq_invoice_details_active_unit (active_unit_id),
    CONSTRAINT chk_invoice_details_qty CHECK (quantity > 0),
    CONSTRAINT chk_invoice_details_returned CHECK (returned_quantity <= quantity),
    CONSTRAINT chk_invoice_details_unit_qty CHECK (unit_id IS NULL OR quantity = 1),
    CONSTRAINT chk_invoice_details_discount
        CHECK (discount_amount <= quantity * unit_price),
    CONSTRAINT fk_invoice_details_invoice
        FOREIGN KEY (invoice_id) REFERENCES invoices (invoice_id),
    CONSTRAINT fk_invoice_details_product
        FOREIGN KEY (product_id) REFERENCES products (product_id),
    CONSTRAINT fk_invoice_details_unit
        FOREIGN KEY (unit_id) REFERENCES product_units (unit_id),
    CONSTRAINT fk_invoice_details_unit_product
        FOREIGN KEY (unit_id, product_id) REFERENCES product_units (unit_id, product_id),
    CONSTRAINT fk_invoice_details_promotion
        FOREIGN KEY (promotion_id) REFERENCES promotions (promotion_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 16. Thanh toán (một hóa đơn có thể trả nhiều hình thức; cod = thu khi giao hàng)
CREATE TABLE payments (
    payment_id  INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    invoice_id  INT UNSIGNED    NOT NULL,
    method      ENUM('cash', 'card', 'bank_transfer', 'cod') NOT NULL,
    amount      BIGINT UNSIGNED NOT NULL,
    paid_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (payment_id),
    CONSTRAINT chk_payments_amount CHECK (amount > 0),
    CONSTRAINT fk_payments_invoice
        FOREIGN KEY (invoice_id) REFERENCES invoices (invoice_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 17. Phiếu đổi trả (trả một phần hoặc toàn bộ số lượng của một dòng hóa đơn)
CREATE TABLE returns (
    return_id          INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    invoice_detail_id  INT UNSIGNED    NOT NULL,
    quantity           INT UNSIGNED    NOT NULL,
    return_date        DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at       DATETIME,
    reason             VARCHAR(255),
    refund_amount      BIGINT UNSIGNED NOT NULL DEFAULT 0,
    status             ENUM('pending', 'approved', 'rejected', 'completed')
                       NOT NULL DEFAULT 'pending',
    employee_id        INT UNSIGNED    NOT NULL,
    PRIMARY KEY (return_id),
    CONSTRAINT chk_returns_qty CHECK (quantity > 0),
    CONSTRAINT chk_returns_completed_at CHECK (
        (status = 'completed' AND completed_at IS NOT NULL)
        OR (status <> 'completed' AND completed_at IS NULL)
    ),
    CONSTRAINT chk_returns_completed_date CHECK (
        completed_at IS NULL OR completed_at >= return_date
    ),
    CONSTRAINT fk_returns_invoice_detail
        FOREIGN KEY (invoice_detail_id) REFERENCES invoice_details (invoice_detail_id),
    CONSTRAINT fk_returns_employee
        FOREIGN KEY (employee_id) REFERENCES employees (employee_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 18. Thẻ bảo hành
--     Mỗi máy chỉ có một thẻ đang hiệu lực (is_void = FALSE).
--     invoice_detail_id là dòng hóa đơn gốc; máy đổi mới dùng lại invoice_detail_id gốc.
CREATE TABLE warranties (
    warranty_id        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    unit_id            INT UNSIGNED NOT NULL,
    invoice_detail_id  INT UNSIGNED NOT NULL,
    start_date         DATE         NOT NULL,
    end_date           DATE         NOT NULL,
    is_void            BOOLEAN      NOT NULL DEFAULT FALSE,
    active_unit_id     INT UNSIGNED AS (CASE WHEN is_void = FALSE THEN unit_id END) STORED,
    PRIMARY KEY (warranty_id),
    KEY idx_warranties_unit (unit_id),
    UNIQUE KEY uq_warranties_active_unit (active_unit_id),
    CONSTRAINT chk_warranty_dates CHECK (end_date > start_date),
    CONSTRAINT fk_warranties_unit
        FOREIGN KEY (unit_id) REFERENCES product_units (unit_id),
    CONSTRAINT fk_warranties_invoice_detail
        FOREIGN KEY (invoice_detail_id) REFERENCES invoice_details (invoice_detail_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 19. Yêu cầu bảo hành (replacement_unit_id có khi status = replaced)
CREATE TABLE warranty_claims (
    claim_id                 INT UNSIGNED NOT NULL AUTO_INCREMENT,
    warranty_id              INT UNSIGNED NOT NULL,
    received_at              DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    issue                    VARCHAR(255) NOT NULL,
    status                   ENUM('received', 'repairing', 'repaired', 'replaced', 'returned', 'rejected')
                             NOT NULL DEFAULT 'received',
    replacement_unit_id      INT UNSIGNED,
    handled_by_employee_id   INT UNSIGNED,
    resolved_at              DATETIME,
    PRIMARY KEY (claim_id),
    KEY idx_warranty_claims_warranty (warranty_id),
    CONSTRAINT chk_warranty_claims_replacement CHECK (
        (status IN ('received', 'repairing', 'repaired', 'rejected')
            AND replacement_unit_id IS NULL)
        OR (status = 'replaced' AND replacement_unit_id IS NOT NULL)
        OR (status = 'returned')
    ),
    CONSTRAINT chk_warranty_claims_resolved_date CHECK (
        resolved_at IS NULL OR resolved_at >= received_at
    ),
    CONSTRAINT fk_warranty_claims_warranty
        FOREIGN KEY (warranty_id) REFERENCES warranties (warranty_id),
    CONSTRAINT fk_warranty_claims_replacement_unit
        FOREIGN KEY (replacement_unit_id) REFERENCES product_units (unit_id),
    CONSTRAINT fk_warranty_claims_handler
        FOREIGN KEY (handled_by_employee_id) REFERENCES employees (employee_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 19.1 Lịch sử thay đổi trạng thái yêu cầu bảo hành
CREATE TABLE warranty_claim_history (
    history_id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    claim_id            INT UNSIGNED NOT NULL,
    from_status         VARCHAR(20),
    to_status           VARCHAR(20)  NOT NULL,
    changed_by_user_id  INT UNSIGNED NOT NULL,
    reason              VARCHAR(255),
    changed_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (history_id),
    KEY idx_warranty_claim_history_claim (claim_id),
    CONSTRAINT fk_warranty_claim_history_claim
        FOREIGN KEY (claim_id) REFERENCES warranty_claims (claim_id),
    CONSTRAINT fk_warranty_claim_history_user
        FOREIGN KEY (changed_by_user_id) REFERENCES users (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 20. Lịch sử xuất nhập tồn (dương = tăng, âm = giảm)
--     Mỗi loại biến động phải có đúng chứng từ tương ứng.
--     Hủy hóa đơn dùng movement_type = 'adjustment' (không có chứng từ bắt buộc).
CREATE TABLE stock_movements (
    movement_id        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    product_id         INT UNSIGNED NOT NULL,
    movement_type      ENUM('import', 'sale', 'return', 'adjustment') NOT NULL,
    quantity           INT          NOT NULL,
    import_detail_id   INT UNSIGNED,
    invoice_detail_id  INT UNSIGNED,
    return_id          INT UNSIGNED,
    employee_id        INT UNSIGNED NOT NULL,
    reason             VARCHAR(255),
    created_at         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (movement_id),
    KEY idx_stock_movements_product (product_id, created_at),
    -- CV7: đúng dấu biến động, đúng loại chứng từ và các chứng từ khác phải NULL.
    CONSTRAINT chk_stock_movements_valid CHECK (
        (movement_type = 'import' AND quantity > 0
            AND import_detail_id IS NOT NULL
            AND invoice_detail_id IS NULL AND return_id IS NULL)
        OR (movement_type = 'sale' AND quantity < 0
            AND import_detail_id IS NULL
            AND invoice_detail_id IS NOT NULL AND return_id IS NULL)
        OR (movement_type = 'return' AND quantity > 0
            AND import_detail_id IS NULL AND invoice_detail_id IS NULL
            AND return_id IS NOT NULL)
        OR (movement_type = 'adjustment' AND quantity <> 0
            AND import_detail_id IS NULL AND invoice_detail_id IS NULL
            AND return_id IS NULL)
    ),
    -- Vấn đề A: biến động điều chỉnh bắt buộc ghi rõ nguyên nhân.
    CONSTRAINT chk_stock_movements_adjustment_reason CHECK (
        movement_type <> 'adjustment'
        OR (reason IS NOT NULL AND TRIM(reason) <> '')
    ),
    CONSTRAINT fk_stock_movements_product
        FOREIGN KEY (product_id) REFERENCES products (product_id),
    CONSTRAINT fk_stock_movements_import_detail
        FOREIGN KEY (import_detail_id) REFERENCES import_details (import_detail_id),
    CONSTRAINT fk_stock_movements_invoice_detail
        FOREIGN KEY (invoice_detail_id) REFERENCES invoice_details (invoice_detail_id),
    CONSTRAINT fk_stock_movements_return
        FOREIGN KEY (return_id) REFERENCES returns (return_id),
    CONSTRAINT fk_stock_movements_employee
        FOREIGN KEY (employee_id) REFERENCES employees (employee_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;