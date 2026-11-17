SET NAMES utf8mb4;
USE qlst;

-- 1. Vai trò (roles)
INSERT INTO roles (role_id, code, name) VALUES
    (1, 'admin',     'Quản trị hệ thống'),
    (2, 'manager',   'Nhân viên quản lý'),
    (3, 'warehouse', 'Nhân viên kho'),
    (4, 'sales',     'Nhân viên bán hàng'),
    (5, 'delivery',  'Nhân viên giao hàng'),
    (6, 'customer',  'Khách hàng');

-- 2. Chức vụ (positions)
INSERT INTO positions (position_id, name) VALUES
    (1, 'Quản trị viên hệ thống'),
    (2, 'Quản lý siêu thị'),
    (3, 'Thủ kho'),
    (4, 'Thu ngân tại quầy'),
    (5, 'Nhân viên giao hàng');

-- 3. Tài khoản đăng nhập (users) - Chỉ dùng cho DEMO: mật khẩu 123456.
--    Password hash được tạo bằng argon2-cffi (Argon2id), mỗi tài khoản có salt riêng.
INSERT INTO users (user_id, username, password_hash, role_id, is_active, last_login_at, created_at) VALUES
    (1, 'admin',       '$argon2id$v=19$m=65536,t=3,p=4$xS9cgK/IaZof2kzPwrg2Hg$X9pABDryUROxLnT3W/mx3U4izHpUK8tZ4hbvj3+PZns', 1, TRUE, '2026-10-01 08:00:00', '2026-09-01 08:00:00'),
    (2, 'quanly01',    '$argon2id$v=19$m=65536,t=3,p=4$uqzsY5k5cYxRYJX1PHAWww$pthYQvtXWMZrju3Gj1GTrDmW13Fk8VAaHBE4Hu/zCz8', 2, TRUE, '2026-10-25 08:30:00', '2026-09-01 08:05:00'),
    (3, 'kho01',       '$argon2id$v=19$m=65536,t=3,p=4$aqjVr459Vtl/32XwBkaNYA$xG9wFUcoXAVt/GuiFa93rO8D8zSg6F2ebDW7/Rv71Qc', 3, TRUE, '2026-10-25 07:45:00', '2026-09-01 08:10:00'),
    (4, 'banhang01',   '$argon2id$v=19$m=65536,t=3,p=4$W4LZ2HISSbafeuvqU90z2A$VNBamwjxFpO8kFxkbh0pNw79QJ5n2fcc1xehaooyK5g', 4, TRUE, '2026-10-25 08:00:00', '2026-09-01 08:15:00'),
    (5, 'giaohang01',  '$argon2id$v=19$m=65536,t=3,p=4$0M6X+nw/X0ow+E60fIzCyg$8bC2oi8NHH7nmCA31K586uwv6epWQdJ3j3ZShm/BIgI', 5, TRUE, '2026-10-25 09:00:00', '2026-09-01 08:20:00'),
    (6, 'khachhang01', '$argon2id$v=19$m=65536,t=3,p=4$mK6+PEv9oX958+tIdNI7Vg$c/mJiLl9dmFoM1wzjBEH7jCKgQs4jKi8hp5A1ZmdbgA', 6, TRUE, '2026-10-15 10:00:00', '2026-09-15 09:00:00'),
    (7, 'khachhang02', '$argon2id$v=19$m=65536,t=3,p=4$S6PHBaFMRjpKsBnzSOmtnQ$G0txe16A3RjeFdhP57hO3iiu9U7zofiFor0F16+v0qc', 6, TRUE, '2026-10-18 14:00:00', '2026-09-20 11:30:00');

-- 4. Nhân viên (employees)
INSERT INTO employees (employee_id, user_id, full_name, phone, email, hire_date, position_id, is_active) VALUES
    (1, 1, 'Nguyễn Quản Trị',    '0911000001', 'admin@qlst.vn',    '2024-01-10', 1, TRUE),
    (2, 2, 'Trần Minh Quản Lý',  '0911000002', 'quanly01@qlst.vn', '2024-02-01', 2, TRUE),
    (3, 3, 'Lê Văn Kho',         '0911000003', 'kho01@qlst.vn',    '2024-03-15', 3, TRUE),
    (4, 4, 'Phạm Thị Thu Ngân',  '0911000004', 'banhang01@qlst.vn','2024-04-01', 4, TRUE),
    (5, 5, 'Hoàng Văn Giao',     '0911000005', 'giaohang01@qlst.vn','2024-05-10', 5, TRUE);

-- 5. Khách hàng (customers) - Gồm 2 thành viên có tài khoản và 1 khách vãng lai
INSERT INTO customers (customer_id, user_id, full_name, phone, email, address, loyalty_points, registered_at, member_since, is_active) VALUES
    (1, 6,    'Nguyễn Văn An',  '0901234567', 'nguyenvanan@gmail.com',  '123 Nguyễn Trãi, Thanh Xuân, Hà Nội', 320, '2026-09-15 09:00:00', '2026-09-15 09:00:00', TRUE),
    (2, 7,    'Trần Thị Bình',  '0902345678', 'tranthibinh@gmail.com',  '45 Cầu Giấy, Cầu Giấy, Hà Nội',       295, '2026-09-20 11:30:00', '2026-09-20 11:30:00', TRUE),
    (3, NULL, 'Lê Hoàng Nam',   '0903456789', NULL,                     '88 Giải Phóng, Hai Bà Trưng, Hà Nội',   0, '2026-10-10 15:15:00', NULL, TRUE);

-- 6. Nhà cung cấp (suppliers)
INSERT INTO suppliers (supplier_id, name, tax_code, phone, email, address, is_active) VALUES
    (1, 'Công ty TNHH Apple Việt Nam',         '0313510827', '02838231111', 'contact@apple.vn',     'Quận 1, TP. Hồ Chí Minh', TRUE),
    (2, 'Công ty Điện tử Samsung Vina',        '0300741991', '02839157310', 'support@samsung.vn',   'Quận 1, TP. Hồ Chí Minh', TRUE),
    (3, 'Công ty Cổ phần Thế Giới Số Digiworld','0302861742', '02439726666', 'info@digiworld.com.vn','Đống Đa, Hà Nội',          TRUE);

-- 7. Danh mục sản phẩm (categories)
INSERT INTO categories (category_id, name, is_active) VALUES
    (1, 'Điện thoại di động',     TRUE),
    (2, 'Tivi & Âm thanh',        TRUE),
    (3, 'Laptop & Máy tính',      TRUE),
    (4, 'Điện lạnh & Gia dụng',   TRUE),
    (5, 'Phụ kiện công nghệ',     TRUE);

-- 8. Sản phẩm (products)
INSERT INTO products (
    product_id, name, brand, barcode, description, image_url,
    category_id, price, cost_price, warranty_months, is_serialized, stock_quantity, is_active
) VALUES
    (1, 'iPhone 16 Pro Max 256GB VN/A',        'Apple',   '8938505970011', 'Điện thoại iPhone 16 Pro Max 256GB Titan Tự Nhiên', '/static/img/iphone16pm.png', 1, 32000000, 28000000, 12, TRUE,  1, TRUE),
    (2, 'Samsung Galaxy S24 Ultra 5G 256GB',   'Samsung', '8938505970028', 'Điện thoại Samsung Galaxy S24 Ultra tích hợp AI',   '/static/img/s24ultra.png',   1, 28000000, 24000000, 12, TRUE,  2, TRUE),
    (3, 'Smart Tivi Samsung 4K 55 inch UA55',  'Samsung', '8938505970035', 'Smart Tivi Crystal UHD 4K 55 inch',                 '/static/img/tv55.png',       2, 15000000, 12000000, 24, TRUE,  1, TRUE),
    (4, 'MacBook Air M3 13 inch 16GB/256GB',   'Apple',   '8938505970042', 'Laptop Apple MacBook Air 13 inch chip M3',          '/static/img/macbookm3.png',  3, 27000000, 23500000, 12, TRUE,  2, TRUE),
    (5, 'Củ sạc nhanh Apple 20W USB-C',        'Apple',   '8938505970059', 'Adapter sạc nhanh 20W USB-C chính hãng',            '/static/img/charger20w.png', 5,   500000,   350000, 12, FALSE, 15, TRUE),
    (6, 'Tủ lạnh LG Inverter 315 Lít GN-M312', 'LG',      '8938505970066', 'Tủ lạnh ngăn đá trên tiết kiệm điện Inverter',      '/static/img/lgfridge.png',   4, 11000000,  8800000, 24, TRUE,  2, TRUE);

-- 8.1 Khuyến mãi (promotions)
INSERT INTO promotions (promotion_id, product_id, category_id, discount_percent, start_date, end_date) VALUES
    (1, 1,    NULL,  3.13, '2026-10-01 00:00:00', '2026-10-31 23:59:59'),
    (2, NULL, 2,    10.00, '2026-10-01 00:00:00', '2026-10-31 23:59:59');

-- 8.2 Lịch sử giá bán (product_price_history)
INSERT INTO product_price_history (price_history_id, product_id, price, effective_from, effective_to) VALUES
    (1, 1, 33000000, '2026-09-01 00:00:00', '2026-10-01 00:00:00'),
    (2, 1, 32000000, '2026-10-01 00:00:00', NULL),
    (3, 2, 28000000, '2026-09-01 00:00:00', NULL),
    (4, 3, 15000000, '2026-09-01 00:00:00', NULL),
    (5, 4, 27000000, '2026-09-01 00:00:00', NULL),
    (6, 5,   500000, '2026-09-01 00:00:00', NULL),
    (7, 6, 11000000, '2026-09-01 00:00:00', NULL);

-- 10. Phiếu nhập hàng (imports)
INSERT INTO imports (import_id, import_date, supplier_id, employee_id) VALUES
    (1, '2026-10-01 09:00:00', 1, 3),
    (2, '2026-10-02 10:00:00', 2, 3),
    (3, '2026-10-03 11:00:00', 3, 3);

-- 10.1 Chi tiết phiếu nhập (import_details)
INSERT INTO import_details (import_detail_id, import_id, product_id, quantity, unit_cost) VALUES
    (1, 1, 1,  3, 28000000),
    (2, 1, 4,  2, 23500000),
    (3, 1, 5, 20,   350000),
    (4, 2, 2,  3, 24000000),
    (5, 2, 3,  2, 12000000),
    (6, 3, 6,  2,  8800000);

-- 9. Máy cụ thể có serial (product_units)
INSERT INTO product_units (unit_id, product_id, serial_number, status, import_detail_id) VALUES
    (1,  1, 'SN-IP16PM-001', 'sold',     1),
    (2,  1, 'SN-IP16PM-002', 'sold',     1),
    (3,  1, 'SN-IP16PM-003', 'in_stock', 1),
    (4,  2, 'SN-S24U-001',   'sold',     4),
    (5,  2, 'SN-S24U-002',   'in_stock', 4),
    (6,  2, 'SN-S24U-003',   'in_stock', 4),
    (7,  3, 'SN-TVSS55-001', 'sold',     5),
    (8,  3, 'SN-TVSS55-002', 'in_stock', 5),
    (9,  4, 'SN-MBA13-001',  'in_stock', 2),
    (10, 4, 'SN-MBA13-002',  'in_stock', 2),
    (11, 6, 'SN-LG315-001',  'in_stock', 6),
    (12, 6, 'SN-LG315-002',  'in_stock', 6);

-- 11. Ca làm việc (shifts)
INSERT INTO shifts (shift_id, employee_id, opened_at, closed_at, opening_cash, closing_cash, status) VALUES
    (1, 4, '2026-10-05 07:30:00', '2026-10-05 17:30:00', 5000000, 37000000, 'closed'),
    (2, 4, '2026-10-10 07:30:00', '2026-10-10 17:30:00', 5000000,  5000000, 'closed'),
    (3, 4, '2026-10-20 07:30:00', '2026-10-20 17:30:00', 5000000,  5000000, 'closed');

-- 12. Giỏ hàng (cart_items)
INSERT INTO cart_items (customer_id, product_id, quantity, added_at) VALUES
    (1, 4, 1, '2026-10-25 09:00:00');

-- 13. Đơn hàng trực tuyến (orders)
INSERT INTO orders (
    order_id, order_code, customer_id, order_date,
    shipping_name, shipping_phone, shipping_address,
    subtotal_amount, discount_amount, shipping_fee, total_amount,
    payment_method, payment_status, status, cancel_reason,
    approved_by_employee_id, approved_at
) VALUES
    (1, 'ORD-20261015-001', 2, '2026-10-15 10:00:00',
     'Trần Thị Bình', '0902345678', '45 Cầu Giấy, Cầu Giấy, Hà Nội',
     30000000, 0, 50000, 30050000,
     'cod', 'paid', 'delivered', NULL,
     3, '2026-10-15 10:30:00');

-- 13.1 Chi tiết đơn hàng trực tuyến (order_details)
INSERT INTO order_details (
    order_detail_id, order_id, product_id, quantity, unit_price, discount_amount, promotion_id
) VALUES
    (1, 1, 2, 1, 28000000, 0, NULL),
    (2, 1, 5, 4,   500000, 0, NULL);

-- 13.2 Lịch sử trạng thái đơn hàng (order_status_history)
INSERT INTO order_status_history (history_id, order_id, from_status, to_status, changed_by_user_id, reason, changed_at) VALUES
    (1, 1, NULL,         'pending',    7, 'Khách đặt đơn hàng trực tuyến', '2026-10-15 10:00:00'),
    (2, 1, 'pending',    'approved',   3, 'Nhân viên kho duyệt đơn',       '2026-10-15 10:30:00'),
    (3, 1, 'approved',   'delivering', 3, 'Xuất kho cho nhân viên giao',   '2026-10-15 11:00:00'),
    (4, 1, 'delivering', 'delivered',  5, 'Giao hàng và thu COD thành công','2026-10-15 16:00:00');

-- 14. Phiếu xuất giao hàng (deliveries)
INSERT INTO deliveries (
    delivery_id, order_id, exported_by_employee_id, delivery_staff_id,
    exported_at, delivered_at, status, failed_reason, cod_collected_amount
) VALUES
    (1, 1, 3, 5, '2026-10-15 11:00:00', '2026-10-15 16:00:00', 'delivered', NULL, 30050000);

-- 14.1 Chi tiết phiếu xuất (delivery_items)
INSERT INTO delivery_items (delivery_item_id, delivery_id, order_detail_id, unit_id, quantity) VALUES
    (1, 1, 1, 4,    1),
    (2, 1, 2, NULL, 4);

-- 14.2 Lịch sử trạng thái giao hàng (delivery_status_history)
INSERT INTO delivery_status_history (history_id, delivery_id, from_status, to_status, changed_by_user_id, reason, changed_at) VALUES
    (1, 1, NULL,         'delivering', 3, 'Bàn giao hàng cho shipper', '2026-10-15 11:00:00'),
    (2, 1, 'delivering', 'delivered',  5, 'Đã giao tận tay khách',     '2026-10-15 16:00:00');

-- 15. Hóa đơn (invoices)
INSERT INTO invoices (
    invoice_id, invoice_date, channel, employee_id, customer_id, shift_id, order_id,
    subtotal_amount, discount_amount, shipping_fee, total_amount, status
) VALUES
    (1, '2026-10-05 09:30:00', 'counter', 4,    1, 1,    NULL, 33000000, 1000000,     0, 32000000, 'completed'),
    (2, '2026-10-10 15:20:00', 'counter', 4,    3, 2,    NULL, 47000000, 1500000,     0, 45500000, 'completed'),
    (3, '2026-10-15 16:00:00', 'online',  NULL, 2, NULL, 1,    30000000,       0, 50000, 30050000, 'completed'),
    (4, '2026-10-20 11:00:00', 'counter', 4,    1, 3,    NULL, 27000000,       0,     0, 27000000, 'cancelled');

-- 15.1 Chi tiết hóa đơn (invoice_details)
INSERT INTO invoice_details (
    invoice_detail_id, invoice_id, product_id, unit_id,
    quantity, returned_quantity, unit_price, discount_amount, promotion_id, is_active
) VALUES
    (1, 1, 1, 1,    1, 0, 32000000, 1000000, 1,    TRUE),
    (2, 1, 5, NULL, 2, 0,   500000,       0, NULL, TRUE),
    (3, 2, 1, 2,    1, 0, 32000000,       0, NULL, TRUE),
    (4, 2, 3, 7,    1, 0, 15000000, 1500000, 2,    TRUE),
    (5, 3, 2, 4,    1, 0, 28000000,       0, NULL, TRUE),
    (6, 3, 5, NULL, 4, 2,   500000,       0, NULL, TRUE),
    (7, 4, 4, 9,    1, 0, 27000000,       0, NULL, FALSE);

-- 16. Thanh toán (payments)
INSERT INTO payments (payment_id, invoice_id, method, amount, paid_at) VALUES
    (1, 1, 'cash',          32000000, '2026-10-05 09:31:00'),
    (2, 2, 'bank_transfer', 45500000, '2026-10-10 15:22:00'),
    (3, 3, 'cod',           30050000, '2026-10-15 16:00:00');

-- 17. Phiếu đổi trả (returns)
--    Hoàn tiền theo completed_at; chỉ hoàn tiền/ghi nhận số lượng trả khi completed.
--    Return #2 hoàn tất tháng 11 nhưng CHƯA nhập lại kho (không có stock_movement return).
--    Return #3 pending không tham gia returned_quantity / doanh thu hoàn trả.
INSERT INTO returns (
    return_id, invoice_detail_id, quantity, return_date, completed_at,
    reason, refund_amount, status, employee_id
) VALUES
    (1, 6, 1, '2026-10-17 10:00:00', '2026-10-17 10:00:00', 'Khách mua dư 1 củ sạc, còn nguyên hộp', 500000, 'completed', 4),
    (2, 6, 1, '2026-11-05 10:00:00', '2026-11-05 10:30:00', 'Khách trả thêm 1 củ sạc; chưa nhập lại kho', 500000, 'completed', 4),
    (3, 6, 1, '2026-11-10 09:00:00', NULL, 'Khách đề nghị trả thêm 1 củ sạc; đang chờ duyệt', 0, 'pending', 4);

-- 18. Thẻ bảo hành (warranties)
INSERT INTO warranties (warranty_id, unit_id, invoice_detail_id, start_date, end_date, is_void) VALUES
    (1, 1, 1, '2026-10-05', '2027-10-05', FALSE),
    (2, 2, 3, '2026-10-10', '2027-10-10', FALSE),
    (3, 7, 4, '2026-10-10', '2028-10-10', FALSE),
    (4, 4, 5, '2026-10-15', '2027-10-15', FALSE);

-- 19. Yêu cầu bảo hành (warranty_claims)
INSERT INTO warranty_claims (
    claim_id, warranty_id, received_at, issue, status, replacement_unit_id, handled_by_employee_id, resolved_at
) VALUES
    (1, 3, '2026-10-22 09:00:00', 'Điều khiển giọng nói kết nối chập chờn', 'repaired', NULL, 3, '2026-10-23 15:00:00');

-- 19.1 Lịch sử yêu cầu bảo hành (warranty_claim_history)
INSERT INTO warranty_claim_history (history_id, claim_id, from_status, to_status, changed_by_user_id, reason, changed_at) VALUES
    (1, 1, NULL,        'received',  3, 'Tiếp nhận bảo hành tại quầy',       '2026-10-22 09:00:00'),
    (2, 1, 'received',  'repairing', 3, 'Kiểm tra và cập nhật firmware',      '2026-10-22 14:00:00'),
    (3, 1, 'repairing', 'repaired',  3, 'Đã khắc phục xong lỗi kết nối',     '2026-10-23 15:00:00');

-- 20. Lịch sử xuất nhập tồn (stock_movements)
INSERT INTO stock_movements (
    movement_id, product_id, movement_type, quantity,
    import_detail_id, invoice_detail_id, return_id, employee_id, reason, created_at
) VALUES
    (1,  1, 'import',     3,  1,    NULL, NULL, 3, NULL, '2026-10-01 09:00:00'),
    (2,  4, 'import',     2,  2,    NULL, NULL, 3, NULL, '2026-10-01 09:00:00'),
    (3,  5, 'import',    20,  3,    NULL, NULL, 3, NULL, '2026-10-01 09:00:00'),
    (4,  2, 'import',     3,  4,    NULL, NULL, 3, NULL, '2026-10-02 10:00:00'),
    (5,  3, 'import',     2,  5,    NULL, NULL, 3, NULL, '2026-10-02 10:00:00'),
    (6,  6, 'import',     2,  6,    NULL, NULL, 3, NULL, '2026-10-03 11:00:00'),
    (7,  1, 'sale',      -1,  NULL, 1,    NULL, 4, NULL, '2026-10-05 09:30:00'),
    (8,  5, 'sale',      -2,  NULL, 2,    NULL, 4, NULL, '2026-10-05 09:30:00'),
    (9,  1, 'sale',      -1,  NULL, 3,    NULL, 4, NULL, '2026-10-10 15:20:00'),
    (10, 3, 'sale',      -1,  NULL, 4,    NULL, 4, NULL, '2026-10-10 15:20:00'),
    (11, 2, 'sale',      -1,  NULL, 5,    NULL, 3, NULL, '2026-10-15 16:00:00'),
    (12, 5, 'sale',      -4,  NULL, 6,    NULL, 3, NULL, '2026-10-15 16:00:00'),
    (13, 5, 'return',     1,  NULL, NULL, 1,    4, NULL, '2026-10-17 10:00:00'),
    (14, 4, 'sale',      -1,  NULL, 7,    NULL, 4, NULL, '2026-10-20 11:00:00'),
    (15, 4, 'adjustment', 1,  NULL, NULL, NULL, 4, 'Hoàn kho do hủy hóa đơn', '2026-10-20 11:05:00');