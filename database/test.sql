-- QLST / database/test.sql - Kiem thu CSDL theo QUES.md va 20 + 2 quyet dinh.
-- Yeu cau: MySQL 8.0.16+ (CHECK ENFORCED), InnoDB, CSDL qlst da khoi tao
-- bang schema.sql, procedures.sql va seed.sql da phe duyet (126 ban ghi).
-- Thu tu chay: init.sql -> schema.sql -> procedures.sql -> seed.sql -> test.sql.
-- Chu y: init.sql co DROP DATABASE: CHI CHAY LAI TREN DATABASE DEMO.
-- File nay CHI DOC (SELECT, CALL); khong INSERT/UPDATE/DELETE/CREATE/TEMP TABLE.
-- Ket qua PASS/FAIL la ket qua THUC TE cua truy van tai thoi diem chay,
-- KHONG PHAI ket qua duoc dien san. Ky vong co dinh chi dung cho seed 126 ban ghi.
-- Metadata PASS chi cho thay constraint duoc khai bao ENFORCED; khong chung minh
-- rang moi thao tac sai deu bi MySQL tu choi. Test phu dinh can Python integration.
-- Kiem thu SQL DOC LAP khong the lay result set cua CALL vao SELECT de tu dong
-- so sanh 2 procedure. CALL cuoi file de xem thuc te; so sanh tu dong can Python.
-- Cot result=PASS trong test T07/T08 chi xac nhan ORACLE truy van du lieu nguon,
-- KHONG duoc hieu la Stored Procedure da PASS.
SET NAMES utf8mb4;
USE qlst;


-- -----------------------------------------------------------------------------------
-- T01 - THANH VIEN VA TAI KHOAN
-- Ba truong hop dang ky duoc chung minh qua du lieu nen; luong INSERT/UPDATE phai test Python.
-- -----------------------------------------------------------------------------------

SELECT
  'T01-01' AS test_id,
  'Phone bat buoc, khong rong' AS purpose,
  'customers.phone' AS test_input,
  '0 vi pham' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM customers WHERE phone IS NULL OR TRIM(phone) = ''
) AS x;

SELECT
  'T01-02' AS test_id,
  'Khong co so dien thoai trung' AS purpose,
  'customers.phone' AS test_input,
  '0 nhom trung' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM (SELECT phone FROM customers GROUP BY phone HAVING COUNT(*) > 1) AS dup
) AS x;

SELECT
  'T01-03' AS test_id,
  'Quan he user_id va member_since nhat quan' AS purpose,
  'customers' AS test_input,
  '0 vi pham' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM customers WHERE (user_id IS NULL AND member_since IS NOT NULL) OR (user_id IS NOT NULL AND member_since IS NULL)
) AS x;

SELECT
  'T01-04' AS test_id,
  'Member_since khong som hon ngay tao ho so' AS purpose,
  'customers' AS test_input,
  '0 vi pham' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM customers WHERE member_since < registered_at
) AS x;

SELECT
  'T01-05' AS test_id,
  'Khach ho so chua co tai khoan' AS purpose,
  'customer_id=3' AS test_input,
  '1 ho so hop le' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 1) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM customers WHERE customer_id=3 AND user_id IS NULL AND member_since IS NULL AND phone='0903456789'
) AS x;

SELECT
  'T01-06' AS test_id,
  'Khach da co tai khoan' AS purpose,
  'customer_id IN (1,2)' AS test_input,
  '2 ho so' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 2) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM customers WHERE customer_id IN (1,2) AND user_id IS NOT NULL AND member_since IS NOT NULL
) AS x;

SELECT
  'T01-07' AS test_id,
  'So dien thoai dang ky moi chua ton tai' AS purpose,
  '0909999999' AS test_input,
  '0 ho so' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM customers WHERE phone='0909999999'
) AS x;

SELECT
  'T01-08' AS test_id,
  'Tai khoan khach la vai tro customer' AS purpose,
  'khachhang01, khachhang02' AS test_input,
  '2 tai khoan' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 2) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM customers c JOIN users u ON u.user_id=c.user_id JOIN roles r ON r.role_id=u.role_id WHERE c.customer_id IN (1,2) AND r.code='customer'
) AS x;

SELECT
  'T01-09' AS test_id,
  'Hash mat khau mau dung dang Argon2id' AS purpose,
  'users' AS test_input,
  '7 hash Argon2id' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 7) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM users WHERE password_hash LIKE '$argon2id$%'
) AS x;

SELECT
  'T01-10' AS test_id,
  'Salt/hash rieng cho tung user' AS purpose,
  'users.password_hash' AS test_input,
  '7 hash phan biet' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 7) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(DISTINCT password_hash) AS actual FROM users
) AS x;

SELECT
  'T01-11' AS test_id,
  'Cot member_since, reason, completed_at va phone NOT NULL' AS purpose,
  'information_schema.columns' AS test_input,
  '4 cot dung' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 4) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND (
    (TABLE_NAME='customers' AND COLUMN_NAME='member_since' AND DATA_TYPE='datetime' AND IS_NULLABLE='YES') OR
    (TABLE_NAME='customers' AND COLUMN_NAME='phone' AND IS_NULLABLE='NO') OR
    (TABLE_NAME='returns' AND COLUMN_NAME='completed_at' AND DATA_TYPE='datetime' AND IS_NULLABLE='YES') OR
    (TABLE_NAME='stock_movements' AND COLUMN_NAME='reason' AND DATA_TYPE='varchar' AND IS_NULLABLE='YES')
  )
) AS x;

SELECT
  'T01-12' AS test_id,
  'UNIQUE phone va user cua khach' AS purpose,
  'information_schema.table_constraints' AS test_input,
  '2 UNIQUE' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 2) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM information_schema.TABLE_CONSTRAINTS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='customers' AND CONSTRAINT_TYPE='UNIQUE' AND CONSTRAINT_NAME IN ('uq_customers_user','uq_customers_phone')
) AS x;

-- -----------------------------------------------------------------------------------
-- T02 - KHOA NGOAI GHEP
-- Kiem tra schema metadata va cac du lieu lien ket hop le.
-- -----------------------------------------------------------------------------------

SELECT
  'T02-01' AS test_id,
  'Du bon UNIQUE ghep o bang cha' AS purpose,
  'schema metadata' AS test_input,
  '4 UNIQUE' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 4) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM information_schema.TABLE_CONSTRAINTS
  WHERE TABLE_SCHEMA=DATABASE() AND CONSTRAINT_TYPE='UNIQUE' AND (
   (TABLE_NAME='import_details' AND CONSTRAINT_NAME='uq_import_details_detail_product') OR
   (TABLE_NAME='product_units' AND CONSTRAINT_NAME='uq_product_units_unit_product') OR
   (TABLE_NAME='orders' AND CONSTRAINT_NAME='uq_orders_order_customer') OR
   (TABLE_NAME='shifts' AND CONSTRAINT_NAME='uq_shifts_employee')
  )
) AS x;

SELECT
  'T02-02' AS test_id,
  'Du 4 FK ghep (8 thanh phan cot)' AS purpose,
  'information_schema.key_column_usage' AS test_input,
  '8 tham chieu' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 8) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM information_schema.KEY_COLUMN_USAGE k
  WHERE k.TABLE_SCHEMA=DATABASE() AND (
   (k.CONSTRAINT_NAME='fk_product_units_import_detail_product' AND k.TABLE_NAME='product_units' AND k.ORDINAL_POSITION=1 AND k.COLUMN_NAME='import_detail_id' AND k.REFERENCED_TABLE_NAME='import_details' AND k.REFERENCED_COLUMN_NAME='import_detail_id') OR
   (k.CONSTRAINT_NAME='fk_product_units_import_detail_product' AND k.TABLE_NAME='product_units' AND k.ORDINAL_POSITION=2 AND k.COLUMN_NAME='product_id' AND k.REFERENCED_TABLE_NAME='import_details' AND k.REFERENCED_COLUMN_NAME='product_id') OR
   (k.CONSTRAINT_NAME='fk_invoice_details_unit_product' AND k.TABLE_NAME='invoice_details' AND k.ORDINAL_POSITION=1 AND k.COLUMN_NAME='unit_id' AND k.REFERENCED_TABLE_NAME='product_units' AND k.REFERENCED_COLUMN_NAME='unit_id') OR
   (k.CONSTRAINT_NAME='fk_invoice_details_unit_product' AND k.TABLE_NAME='invoice_details' AND k.ORDINAL_POSITION=2 AND k.COLUMN_NAME='product_id' AND k.REFERENCED_TABLE_NAME='product_units' AND k.REFERENCED_COLUMN_NAME='product_id') OR
   (k.CONSTRAINT_NAME='fk_invoices_order_customer' AND k.TABLE_NAME='invoices' AND k.ORDINAL_POSITION=1 AND k.COLUMN_NAME='order_id' AND k.REFERENCED_TABLE_NAME='orders' AND k.REFERENCED_COLUMN_NAME='order_id') OR
   (k.CONSTRAINT_NAME='fk_invoices_order_customer' AND k.TABLE_NAME='invoices' AND k.ORDINAL_POSITION=2 AND k.COLUMN_NAME='customer_id' AND k.REFERENCED_TABLE_NAME='orders' AND k.REFERENCED_COLUMN_NAME='customer_id') OR
   (k.CONSTRAINT_NAME='fk_invoices_shift_employee' AND k.TABLE_NAME='invoices' AND k.ORDINAL_POSITION=1 AND k.COLUMN_NAME='shift_id' AND k.REFERENCED_TABLE_NAME='shifts' AND k.REFERENCED_COLUMN_NAME='shift_id') OR
   (k.CONSTRAINT_NAME='fk_invoices_shift_employee' AND k.TABLE_NAME='invoices' AND k.ORDINAL_POSITION=2 AND k.COLUMN_NAME='employee_id' AND k.REFERENCED_TABLE_NAME='shifts' AND k.REFERENCED_COLUMN_NAME='employee_id')
  )
) AS x;

SELECT
  'T02-03' AS test_id,
  'Serial khop san pham cua chi tiet nhap' AS purpose,
  'product_units/import_details' AS test_input,
  '0 sai lech' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM product_units pu JOIN import_details d ON d.import_detail_id=pu.import_detail_id WHERE pu.product_id <> d.product_id
) AS x;

SELECT
  'T02-04' AS test_id,
  'Serial hoa don khop san pham' AS purpose,
  'invoice_details/product_units' AS test_input,
  '0 sai lech' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM invoice_details d JOIN product_units pu ON pu.unit_id=d.unit_id WHERE d.unit_id IS NOT NULL AND d.product_id <> pu.product_id
) AS x;

SELECT
  'T02-05' AS test_id,
  'Khach hang hoa don online dung don hang' AS purpose,
  'invoices channel=online' AS test_input,
  '0 sai lech' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM invoices i LEFT JOIN orders o ON o.order_id=i.order_id WHERE i.channel='online' AND (i.order_id IS NULL OR i.customer_id IS NULL OR o.order_id IS NULL OR i.customer_id<>o.customer_id)
) AS x;

SELECT
  'T02-06' AS test_id,
  'Nhan vien hoa don quay dung ca' AS purpose,
  'invoices channel=counter' AS test_input,
  '0 sai lech' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM invoices i LEFT JOIN shifts s ON s.shift_id=i.shift_id WHERE i.channel='counter' AND (i.shift_id IS NULL OR i.employee_id IS NULL OR s.shift_id IS NULL OR i.employee_id<>s.employee_id)
) AS x;

SELECT
  'T02-07' AS test_id,
  'CHECK online bat buoc co khach' AS purpose,
  'invoices' AS test_input,
  '0 sai lech' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM invoices WHERE channel='online' AND (customer_id IS NULL OR order_id IS NULL)
) AS x;

-- -----------------------------------------------------------------------------------
-- T03 - RANG BUOC CHECK
-- Metadata ENFORCED va hien trang hop le; negative-insert test bang Python.
-- -----------------------------------------------------------------------------------

SELECT
  'T03-01' AS test_id,
  '12 CHECK moi da ENFORCED' AS purpose,
  'information_schema.table_constraints' AS test_input,
  '12 CHECK' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 12) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM information_schema.TABLE_CONSTRAINTS WHERE TABLE_SCHEMA=DATABASE() AND CONSTRAINT_TYPE='CHECK' AND ENFORCED='YES' AND (
    (TABLE_NAME='customers' AND CONSTRAINT_NAME='chk_customers_membership') OR
    (TABLE_NAME='customers' AND CONSTRAINT_NAME='chk_customers_member_date') OR
    (TABLE_NAME='returns' AND CONSTRAINT_NAME='chk_returns_completed_at') OR
    (TABLE_NAME='returns' AND CONSTRAINT_NAME='chk_returns_completed_date') OR
    (TABLE_NAME='stock_movements' AND CONSTRAINT_NAME='chk_stock_movements_valid') OR
    (TABLE_NAME='stock_movements' AND CONSTRAINT_NAME='chk_stock_movements_adjustment_reason') OR
    (TABLE_NAME='shifts' AND CONSTRAINT_NAME='chk_shifts_status_consistency') OR
    (TABLE_NAME='deliveries' AND CONSTRAINT_NAME='chk_deliveries_status_consistency') OR
    (TABLE_NAME='deliveries' AND CONSTRAINT_NAME='chk_deliveries_date') OR
    (TABLE_NAME='invoices' AND CONSTRAINT_NAME='chk_invoices_online_customer') OR
    (TABLE_NAME='warranty_claims' AND CONSTRAINT_NAME='chk_warranty_claims_replacement') OR
    (TABLE_NAME='warranty_claims' AND CONSTRAINT_NAME='chk_warranty_claims_resolved_date')
  )
) AS x;

SELECT
  'T03-02' AS test_id,
  'Bien dong kho: dau va chung tu dung loai' AS purpose,
  'stock_movements' AS test_input,
  '0 vi pham' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM stock_movements s WHERE NOT (
   (movement_type='import' AND quantity>0 AND import_detail_id IS NOT NULL AND invoice_detail_id IS NULL AND return_id IS NULL) OR
   (movement_type='sale' AND quantity<0 AND import_detail_id IS NULL AND invoice_detail_id IS NOT NULL AND return_id IS NULL) OR
   (movement_type='return' AND quantity>0 AND import_detail_id IS NULL AND invoice_detail_id IS NULL AND return_id IS NOT NULL) OR
   (movement_type='adjustment' AND quantity<>0 AND import_detail_id IS NULL AND invoice_detail_id IS NULL AND return_id IS NULL)
  )
) AS x;

SELECT
  'T03-03' AS test_id,
  'Adjustment phai co reason' AS purpose,
  'stock_movements' AS test_input,
  '0 vi pham' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM stock_movements WHERE movement_type='adjustment' AND (reason IS NULL OR TRIM(reason)='')
) AS x;

SELECT
  'T03-04' AS test_id,
  'Ca mo/dong nhat quan voi tien va ngay' AS purpose,
  'shifts' AS test_input,
  '0 vi pham' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM shifts WHERE NOT ((status='open' AND closed_at IS NULL AND closing_cash IS NULL) OR (status='closed' AND closed_at IS NOT NULL AND closing_cash IS NOT NULL)) OR (closed_at IS NOT NULL AND closed_at < opened_at)
) AS x;

SELECT
  'T03-05' AS test_id,
  'Giao hang: trang thai va moc thoi gian' AS purpose,
  'deliveries' AS test_input,
  '0 vi pham' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM deliveries WHERE NOT (
   (status='delivering' AND delivered_at IS NULL AND failed_reason IS NULL) OR
   (status='delivered' AND delivered_at IS NOT NULL AND failed_reason IS NULL) OR
   (status='failed' AND delivered_at IS NULL AND failed_reason IS NOT NULL AND TRIM(failed_reason)<>'')
  ) OR (delivered_at IS NOT NULL AND delivered_at < exported_at)
) AS x;

SELECT
  'T03-06' AS test_id,
  'Hoan tra: completed_at va return_date' AS purpose,
  'returns' AS test_input,
  '0 vi pham' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM returns WHERE NOT ((status='completed' AND completed_at IS NOT NULL) OR (status<>'completed' AND completed_at IS NULL)) OR (completed_at IS NOT NULL AND completed_at < return_date)
) AS x;

SELECT
  'T03-07' AS test_id,
  'Bao hanh: replacement_unit_id dung trang thai' AS purpose,
  'warranty_claims' AS test_input,
  '0 vi pham' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM warranty_claims WHERE NOT (
   (status IN ('received','repairing','repaired','rejected') AND replacement_unit_id IS NULL) OR
   (status='replaced' AND replacement_unit_id IS NOT NULL) OR
   (status='returned')
  ) OR (resolved_at IS NOT NULL AND resolved_at < received_at)
) AS x;

SELECT
  'T03-08' AS test_id,
  'Hoa don tinh tong theo CHECK' AS purpose,
  'invoices' AS test_input,
  '0 vi pham' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM invoices WHERE discount_amount>subtotal_amount OR total_amount+discount_amount<>subtotal_amount+shipping_fee
) AS x;

-- -----------------------------------------------------------------------------------
-- T04 - TON KHO
-- Tinh kho tu stock_movements; hang da refund khong dong nghia da nhap kho.
-- -----------------------------------------------------------------------------------

SELECT
  'T04-01' AS test_id,
  'Stock hien tai khop tong bien dong' AS purpose,
  'products so voi stock_movements' AS test_input,
  '0 san pham lech' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM products p LEFT JOIN (
   SELECT product_id, SUM(quantity) AS movement_qty
   FROM stock_movements GROUP BY product_id
  ) s ON s.product_id=p.product_id WHERE p.stock_quantity<>COALESCE(s.movement_qty,0)
) AS x;

SELECT
  'T04-02' AS test_id,
  'Serial in_stock/reserved khop stock_quantity' AS purpose,
  'products.is_serialized=TRUE' AS test_input,
  '0 san pham lech' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM products p LEFT JOIN (
   SELECT product_id, SUM(CASE WHEN status IN ('in_stock','reserved') THEN 1 ELSE 0 END) AS available_units
   FROM product_units GROUP BY product_id
  ) u ON u.product_id=p.product_id
  WHERE p.is_serialized=TRUE AND p.stock_quantity<>COALESCE(u.available_units,0)
) AS x;

SELECT
  'T04-03' AS test_id,
  'Hang khong serial khong co ban ghi product_units' AS purpose,
  'products.is_serialized=FALSE' AS test_input,
  '0 serial thua' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM product_units pu JOIN products p ON p.product_id=pu.product_id WHERE p.is_serialized=FALSE
) AS x;

SELECT
  'T04-04' AS test_id,
  'San pham tren movement phu hop chung tu' AS purpose,
  'import/sale/return' AS test_input,
  '0 sai lech' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM stock_movements s
  LEFT JOIN import_details idt ON idt.import_detail_id=s.import_detail_id
  LEFT JOIN invoice_details d ON d.invoice_detail_id=s.invoice_detail_id
  LEFT JOIN returns r ON r.return_id=s.return_id
  LEFT JOIN invoice_details rd ON rd.invoice_detail_id=r.invoice_detail_id
  WHERE (s.movement_type='import' AND (idt.import_detail_id IS NULL OR idt.product_id<>s.product_id))
     OR (s.movement_type='sale' AND (d.invoice_detail_id IS NULL OR d.product_id<>s.product_id))
     OR (s.movement_type='return' AND (rd.invoice_detail_id IS NULL OR rd.product_id<>s.product_id))
) AS x;

SELECT
  'T04-05' AS test_id,
  'Return #2 da refund chua nhap kho' AS purpose,
  'return_id=2' AS test_input,
  '0 movement return' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM stock_movements WHERE return_id=2 AND movement_type='return'
) AS x;

SELECT
  'T04-06' AS test_id,
  'Return #1 da duoc nhap kho dung 1' AS purpose,
  'return_id=1' AS test_input,
  '1 movement return' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 1) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM stock_movements WHERE return_id=1 AND movement_type='return' AND quantity=1
) AS x;

SELECT
  'T04-07' AS test_id,
  'Adjustment #15 co ly do va khong kem chung tu' AS purpose,
  'movement_id=15' AS test_input,
  '1 ban ghi hop le' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 1) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM stock_movements WHERE movement_id=15 AND movement_type='adjustment' AND quantity=1 AND import_detail_id IS NULL AND invoice_detail_id IS NULL AND return_id IS NULL AND reason='Hoàn kho do hủy hóa đơn'
) AS x;

-- -----------------------------------------------------------------------------------
-- T05 - HOA DON, THANH TOAN, COD, TIEN MAT CA
-- Thanh toan mot phan duoc phep: khong ep moi hoa don completed phai da thu du.
-- -----------------------------------------------------------------------------------

SELECT
  'T05-01' AS test_id,
  'Subtotal hoa don khop tong quantity x unit_price' AS purpose,
  'invoices/invoice_details (ke ca cancelled)' AS test_input,
  '0 hoa don lech' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM invoices i LEFT JOIN (
   SELECT invoice_id,SUM(quantity*unit_price) AS subtotal
   FROM invoice_details GROUP BY invoice_id
  ) d ON d.invoice_id=i.invoice_id
  WHERE i.subtotal_amount<>COALESCE(d.subtotal,0)
) AS x;

SELECT
  'T05-02' AS test_id,
  'Discount hoa don khop tong discount dong' AS purpose,
  'invoices/invoice_details' AS test_input,
  '0 hoa don lech' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM invoices i LEFT JOIN (
   SELECT invoice_id,SUM(discount_amount) AS discount_total
   FROM invoice_details GROUP BY invoice_id
  ) d ON d.invoice_id=i.invoice_id
  WHERE i.discount_amount<>COALESCE(d.discount_total,0)
) AS x;

SELECT
  'T05-03' AS test_id,
  'Tong thanh toan dung sau giam gia + ship' AS purpose,
  'invoices' AS test_input,
  '0 hoa don sai' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM invoices WHERE total_amount+discount_amount<>subtotal_amount+shipping_fee
) AS x;

SELECT
  'T05-04' AS test_id,
  'Khong hoa don nao thu vuot tong goc' AS purpose,
  'invoices/payments' AS test_input,
  '0 hoa don vuot' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM invoices i LEFT JOIN (
   SELECT invoice_id,SUM(amount) AS paid FROM payments GROUP BY invoice_id
  ) p ON p.invoice_id=i.invoice_id
  WHERE COALESCE(p.paid,0)>i.total_amount
) AS x;

SELECT
  'T05-05' AS test_id,
  '3 hoa don completed da thu du trong seed' AS purpose,
  'invoice_id IN (1,2,3)' AS test_input,
  '3 hoa don' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 3) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM invoices i LEFT JOIN (
   SELECT invoice_id,SUM(amount) AS paid FROM payments GROUP BY invoice_id
  ) p ON p.invoice_id=i.invoice_id
  WHERE i.invoice_id IN (1,2,3) AND i.status='completed'
  AND COALESCE(p.paid,0)=i.total_amount
) AS x;

SELECT
  'T05-06' AS test_id,
  'Hoa don huy #4 khong phat sinh payment' AS purpose,
  'invoice_id=4' AS test_input,
  '0 payment' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM payments WHERE invoice_id=4
) AS x;

SELECT
  'T05-07' AS test_id,
  'COD da thu bang payments cod theo order' AS purpose,
  'delivered orders / invoices' AS test_input,
  '0 order lech' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM orders o
  LEFT JOIN (
   SELECT order_id,SUM(cod_collected_amount) AS cod_sum FROM deliveries GROUP BY order_id
  ) d ON d.order_id=o.order_id
  LEFT JOIN (
   SELECT i.order_id,SUM(p.amount) AS cod_paid
   FROM invoices i JOIN payments p ON p.invoice_id=i.invoice_id AND p.method='cod'
   WHERE i.order_id IS NOT NULL GROUP BY i.order_id
  ) v ON v.order_id=o.order_id
  WHERE COALESCE(d.cod_sum,0)<>COALESCE(v.cod_paid,0)
) AS x;

SELECT
  'T05-08' AS test_id,
  'Tien mat cuoi ca = mo ca + payments cash' AS purpose,
  'shifts/payment cash' AS test_input,
  '0 ca lech' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM shifts s LEFT JOIN (
   SELECT i.shift_id,SUM(p.amount) AS cash_paid
   FROM invoices i JOIN payments p ON p.invoice_id=i.invoice_id AND p.method='cash'
   WHERE i.shift_id IS NOT NULL GROUP BY i.shift_id
  ) paid ON paid.shift_id=s.shift_id
  WHERE s.status='closed' AND s.closing_cash<>s.opening_cash+COALESCE(paid.cash_paid,0)
) AS x;

SELECT
  'T05-09' AS test_id,
  'Ca #2 giu tien 5 trieu vi thu bank transfer' AS purpose,
  'shift_id=2' AS test_input,
  '5000000 dong' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 5000000) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COALESCE((SELECT CAST(closing_cash AS SIGNED) FROM shifts WHERE shift_id=2),-1) AS actual
) AS x;

SELECT
  'T05-10' AS test_id,
  'Hoa don online giu nguyen tong ban goc sau tra' AS purpose,
  'invoice_id=3' AS test_input,
  '30050000 dong' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 30050000) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COALESCE((SELECT CAST(total_amount AS SIGNED) FROM invoices WHERE invoice_id=3),-1) AS actual
) AS x;

-- -----------------------------------------------------------------------------------
-- T06 - HOAN TRA
-- Pending khong duoc tinh vao returned_quantity va refund cua ky.
-- -----------------------------------------------------------------------------------

SELECT
  'T06-01' AS test_id,
  'returned_quantity khop tong returns completed' AS purpose,
  'invoice_details/returns' AS test_input,
  '0 dong lech' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM invoice_details d LEFT JOIN (
   SELECT invoice_detail_id,SUM(quantity) AS completed_qty
   FROM returns WHERE status='completed' GROUP BY invoice_detail_id
  ) r ON r.invoice_detail_id=d.invoice_detail_id
  WHERE d.returned_quantity<>COALESCE(r.completed_qty,0)
) AS x;

SELECT
  'T06-02' AS test_id,
  'returned_quantity khong vuot quantity ban' AS purpose,
  'invoice_details' AS test_input,
  '0 dong vi pham' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM invoice_details WHERE returned_quantity>quantity
) AS x;

SELECT
  'T06-03' AS test_id,
  'San pham sac da hoan 2/4 don vi' AS purpose,
  'invoice_detail_id=6' AS test_input,
  '2 don vi' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 2) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COALESCE((SELECT CAST(returned_quantity AS SIGNED) FROM invoice_details WHERE invoice_detail_id=6),-1) AS actual
) AS x;

SELECT
  'T06-04' AS test_id,
  'Co 2 phieu completed cho dong sac' AS purpose,
  'invoice_detail_id=6' AS test_input,
  '2 phieu' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 2) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM returns WHERE invoice_detail_id=6 AND status='completed'
) AS x;

SELECT
  'T06-05' AS test_id,
  'Phieu pending #3 khong co completed_at' AS purpose,
  'return_id=3' AS test_input,
  '1 phieu' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 1) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM returns WHERE return_id=3 AND status='pending' AND completed_at IS NULL
) AS x;

SELECT
  'T06-06' AS test_id,
  'Phieu pending demo chua chi tien hoan' AS purpose,
  'return_id=3' AS test_input,
  '0 dong' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COALESCE((SELECT CAST(refund_amount AS SIGNED) FROM returns WHERE return_id=3 AND status='pending'),-1) AS actual
) AS x;

SELECT
  'T06-07' AS test_id,
  'Thoi diem hoan tien #2 nam thang 11' AS purpose,
  'return_id=2' AS test_input,
  '1 phieu' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 1) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM returns WHERE return_id=2 AND status='completed' AND completed_at >= '2026-11-01' AND completed_at < '2026-12-01'
) AS x;

SELECT
  'T06-08' AS test_id,
  'Tong quantity phieu pending/approved khong vuot hang con lai (seed)' AS purpose,
  'invoice_detail_id=6' AS test_input,
  '0 so vuot' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM invoice_details d
  WHERE d.invoice_detail_id=6 AND (
   SELECT COALESCE(SUM(r.quantity),0) FROM returns r
   WHERE r.invoice_detail_id=d.invoice_detail_id AND r.status IN ('pending','approved')
  )> d.quantity-d.returned_quantity
) AS x;

-- -----------------------------------------------------------------------------------
-- T07 - ORACLE THONG KE DOANH THU
-- PASS = ket qua doc bang nguon; KHONG PHAI ket qua CALL Stored Procedure.
-- -----------------------------------------------------------------------------------

-- ORACLE: tao dong giao dich tu 2 nguon (khong UPDATE invoice_details.returned_quantity).
-- Tu cac dong sale/return nay, kiem tra tong theo thang va theo mat hang.
WITH
sales_events AS (
    SELECT d.product_id, i.invoice_date AS event_at,
           CAST(d.quantity AS DECIMAL(20,0)) AS sold_qty,
           CAST(0 AS DECIMAL(20,0)) AS returned_qty,
           CAST(d.quantity AS DECIMAL(20,0))*CAST(d.unit_price AS DECIMAL(30,0))
             - CAST(d.discount_amount AS DECIMAL(30,0)) AS sales_money,
           CAST(0 AS DECIMAL(50,0)) AS refunded_money
    FROM invoices i JOIN invoice_details d ON d.invoice_id=i.invoice_id
    WHERE i.status='completed' AND d.is_active=TRUE
),
refund_events AS (
    SELECT d.product_id, r.completed_at AS event_at,
           CAST(0 AS DECIMAL(20,0)), CAST(r.quantity AS DECIMAL(20,0)),
           CAST(0 AS DECIMAL(50,0)), CAST(r.refund_amount AS DECIMAL(50,0))
    FROM returns r
    JOIN invoice_details d ON d.invoice_detail_id=r.invoice_detail_id
    JOIN invoices i ON i.invoice_id=d.invoice_id
    WHERE r.status='completed' AND d.is_active=TRUE AND i.status='completed'
),
all_events AS (
    SELECT * FROM sales_events UNION ALL SELECT * FROM refund_events
),
by_month AS (
    SELECT DATE_FORMAT(event_at, '%Y-%m') AS ym,
           SUM(sold_qty) AS sold_qty, SUM(returned_qty) AS returned_qty,
           SUM(sales_money) AS sales_money, SUM(refunded_money) AS refunded_money
    FROM all_events GROUP BY DATE_FORMAT(event_at, '%Y-%m')
),
expected AS (
    SELECT '2026-10' AS ym, 10 AS sold_qty, 1 AS returned_qty,
           107500000 AS sales_money, 500000 AS refunded_money, 107000000 AS net_money
    UNION ALL
    SELECT '2026-11', 0, 1, 0, 500000, -500000
)
SELECT
    CONCAT('T07-',CASE WHEN e.ym='2026-10' THEN '01' ELSE '02' END) AS test_id,
    CONCAT('Doanh thu thang ', e.ym) AS purpose,
    e.ym AS test_input,
    CONCAT('sold=',e.sold_qty,', returned=',e.returned_qty,
           ', sales=',e.sales_money,', refund=',e.refunded_money,', net=',e.net_money) AS expected,
    CONCAT('sold=',COALESCE(m.sold_qty,0),', returned=',COALESCE(m.returned_qty,0),
           ', sales=',COALESCE(m.sales_money,0),', refund=',COALESCE(m.refunded_money,0),
           ', net=',COALESCE(m.sales_money,0)-COALESCE(m.refunded_money,0)) AS actual,
    CASE WHEN m.ym IS NOT NULL
            AND m.sold_qty=e.sold_qty
            AND m.returned_qty=e.returned_qty
            AND m.sales_money=e.sales_money
            AND m.refunded_money=e.refunded_money
            AND m.sales_money-m.refunded_money=e.net_money
         THEN 'PASS' ELSE 'FAIL' END AS result
FROM expected e LEFT JOIN by_month m ON m.ym=e.ym
ORDER BY e.ym;


SELECT
  'T07-03' AS test_id,
  'Thang 11 mat hang 5 chi co refund' AS purpose,
  'product_id=5, Nov 2026' AS test_input,
  '1 return, 0 sale' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 1) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM (
   SELECT r.return_id FROM returns r JOIN invoice_details d ON d.invoice_detail_id=r.invoice_detail_id
   JOIN invoices i ON i.invoice_id=d.invoice_id
   WHERE d.product_id=5 AND i.status='completed' AND d.is_active=TRUE
   AND r.status='completed' AND r.completed_at>='2026-11-01' AND r.completed_at<'2026-12-01'
  ) v WHERE NOT EXISTS (
   SELECT 1 FROM invoice_details d JOIN invoices i ON i.invoice_id=d.invoice_id
   WHERE d.product_id=5 AND i.status='completed' AND d.is_active=TRUE
   AND i.invoice_date>='2026-11-01' AND i.invoice_date<'2026-12-01'
  )
) AS x;

SELECT
  'T07-04' AS test_id,
  'Hoan tra thang 11 khong doi doanh thu ban thang 10' AS purpose,
  'invoices completed Oct' AS test_input,
  '107500000 dong' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 107500000) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COALESCE(SUM(d.quantity*d.unit_price-d.discount_amount),0) AS actual
  FROM invoices i JOIN invoice_details d ON d.invoice_id=i.invoice_id
  WHERE i.status='completed' AND d.is_active=TRUE
  AND i.invoice_date>='2026-10-01' AND i.invoice_date<'2026-11-01'
) AS x;

SELECT
  'T07-05' AS test_id,
  'Hoa don huy khong tao doanh thu ban' AS purpose,
  'invoice_id=4' AS test_input,
  '0 dong' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COALESCE(SUM(CASE WHEN i.status='completed' AND d.is_active=TRUE
  THEN d.quantity*d.unit_price-d.discount_amount ELSE 0 END),0) AS actual
  FROM invoices i JOIN invoice_details d ON d.invoice_id=i.invoice_id WHERE i.invoice_id=4
) AS x;

SELECT
  'T07-06' AS test_id,
  'Phieu chua completed co completed_at NULL' AS purpose,
  'returns not completed' AS test_input,
  '1 phieu' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 1) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM returns WHERE status<>'completed' AND completed_at IS NULL
) AS x;

-- -----------------------------------------------------------------------------------
-- T08 - ORACLE DOI SOAT THEO SAN PHAM
-- Khong the tu SQL SELECT lay va kiem tra result set CALL - xem NOTE cuoi file.
-- -----------------------------------------------------------------------------------

WITH sales AS (
  SELECT d.product_id, i.invoice_date AS transaction_at,
         d.quantity AS sold_qty, 0 AS returned_qty,
         d.quantity*d.unit_price-d.discount_amount AS sales_money,
         0 AS refunded_money
  FROM invoices i JOIN invoice_details d ON d.invoice_id=i.invoice_id
  WHERE i.status='completed' AND d.is_active=TRUE
), refunds AS (
  SELECT d.product_id, r.completed_at AS transaction_at,
         0 AS sold_qty, r.quantity AS returned_qty,
         0 AS sales_money, r.refund_amount AS refunded_money
  FROM returns r JOIN invoice_details d ON d.invoice_detail_id=r.invoice_detail_id
  JOIN invoices i ON i.invoice_id=d.invoice_id
  WHERE r.status='completed' AND d.is_active=TRUE AND i.status='completed'
), events AS (
  SELECT * FROM sales UNION ALL SELECT * FROM refunds
), by_product AS (
  SELECT product_id, DATE_FORMAT(transaction_at,'%Y-%m') AS ym,
         SUM(sold_qty) AS sold_qty, SUM(returned_qty) AS returned_qty,
         SUM(sales_money) AS sales_money, SUM(refunded_money) AS refunded_money
  FROM events GROUP BY product_id, DATE_FORMAT(transaction_at,'%Y-%m')
), exp AS (
  SELECT '2026-10' AS ym, 1 AS product_id, 2 AS sold_qty, 0 AS returned_qty,
         63000000 AS sales_money, 0 AS refunded_money
  UNION ALL SELECT '2026-10',2,1,0,28000000,0
  UNION ALL SELECT '2026-10',3,1,0,13500000,0
  UNION ALL SELECT '2026-10',5,6,1,3000000,500000
  UNION ALL SELECT '2026-11',5,0,1,0,500000
)
SELECT CONCAT('T08-',e.ym,'-P',e.product_id) AS test_id,
       'Chi tieu theo mat hang (nguon du lieu)' AS purpose,
       CONCAT('month=',e.ym,', product_id=',e.product_id) AS test_input,
       CONCAT('Q=',e.sold_qty,'/',e.returned_qty,
              ', Money=',e.sales_money,'/',e.refunded_money) AS expected,
       CONCAT('Q=',COALESCE(p.sold_qty,0),'/',COALESCE(p.returned_qty,0),
              ', Money=',COALESCE(p.sales_money,0),'/',COALESCE(p.refunded_money,0)) AS actual,
       CASE WHEN p.product_id IS NOT NULL AND p.sold_qty=e.sold_qty
                  AND p.returned_qty=e.returned_qty
                  AND p.sold_qty-p.returned_qty=e.sold_qty-e.returned_qty
                  AND p.sales_money=e.sales_money
                  AND p.refunded_money=e.refunded_money
                  AND p.sales_money-p.refunded_money=e.sales_money-e.refunded_money
            THEN 'PASS' ELSE 'FAIL' END AS result
FROM exp e LEFT JOIN by_product p ON p.ym=e.ym AND p.product_id=e.product_id
ORDER BY e.ym,e.product_id;


SELECT
  'T08-06' AS test_id,
  'Khong phat sinh them mat hang ngoai danh sach ky vong' AS purpose,
  'Oct/Nov 2026' AS test_input,
  '0 product/thang thua' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM (
   SELECT DATE_FORMAT(transaction_at,'%Y-%m') AS ym, product_id FROM (
     SELECT i.invoice_date AS transaction_at, d.product_id FROM invoices i JOIN invoice_details d ON d.invoice_id=i.invoice_id WHERE i.status='completed' AND d.is_active=TRUE
     UNION ALL
     SELECT r.completed_at, d.product_id FROM returns r JOIN invoice_details d ON d.invoice_detail_id=r.invoice_detail_id JOIN invoices i ON i.invoice_id=d.invoice_id WHERE r.status='completed' AND d.is_active=TRUE AND i.status='completed'
   ) z WHERE transaction_at >= '2026-10-01' AND transaction_at < '2026-12-01'
   GROUP BY DATE_FORMAT(transaction_at,'%Y-%m'), product_id
  ) q WHERE NOT ((q.ym='2026-10' AND q.product_id IN (1,2,3,5)) OR (q.ym='2026-11' AND q.product_id=5))
) AS x;

SELECT
  'T08-07' AS test_id,
  'Tong ban thang 10 sac Apple la 6' AS purpose,
  'product_id=5, Oct' AS test_input,
  '6 san pham' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 6) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COALESCE(SUM(d.quantity),0) AS actual FROM invoices i
  JOIN invoice_details d ON d.invoice_id=i.invoice_id
  WHERE i.status='completed' AND d.is_active=TRUE AND d.product_id=5
  AND i.invoice_date>='2026-10-01' AND i.invoice_date<'2026-11-01'
) AS x;

-- -----------------------------------------------------------------------------------
-- T09 - NGAY, KHOANG TRONG VA NGOAI LE
-- Test SIGNAL SQLSTATE 45000 bang Python de khong lam gian doan script SELECT.
-- -----------------------------------------------------------------------------------

SELECT
  'T09-01' AS test_id,
  'Khoang ngay khong co invoice completed' AS purpose,
  '2026-12-01..2026-12-31' AS test_input,
  '0 invoice' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM invoices WHERE status='completed' AND invoice_date >= '2026-12-01' AND invoice_date < '2027-01-01'
) AS x;

SELECT
  'T09-02' AS test_id,
  'Khoang ngay khong co returns completed' AS purpose,
  '2026-12-01..2026-12-31' AS test_input,
  '0 returns' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM returns WHERE status='completed' AND completed_at >= '2026-12-01' AND completed_at < '2027-01-01'
) AS x;

SELECT
  'T09-03' AS test_id,
  'Loc duy nhat ngay 15/10 lay du dong chi tiet' AS purpose,
  '2026-10-15..2026-10-15' AS test_input,
  '2 dong ban' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 2) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM invoice_details d
  JOIN invoices i ON i.invoice_id=d.invoice_id
  WHERE i.status='completed' AND d.is_active=TRUE
  AND i.invoice_date>='2026-10-15' AND i.invoice_date < DATE_ADD(DATE('2026-10-15'),INTERVAL 1 DAY)
) AS x;

SELECT
  'T09-04' AS test_id,
  'Loc dung ngay 05/11 co return #2' AS purpose,
  '2026-11-05..2026-11-05' AS test_input,
  '1 return' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 1) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM returns WHERE status='completed' AND completed_at >= '2026-11-05' AND completed_at < DATE_ADD(DATE('2026-11-05'),INTERVAL 1 DAY)
) AS x;
-- End-of-day 23:59:59 / DATETIME(6) can them fixture Python transaction (chua PASS).

-- -----------------------------------------------------------------------------------
-- T10 - NHAT QUAN TOAN BO VA 29 BANG
-- Seed 126 ban ghi: bo phan doc lap co expected count tung bang.
-- -----------------------------------------------------------------------------------

SELECT
  'T10-01' AS test_id,
  'Du 29 bang trong schema' AS purpose,
  'information_schema.tables' AS test_input,
  '29 tables' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 29) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_TYPE='BASE TABLE'
) AS x;

-- Kiem tra du lieu tung bang: moi bang la 1 testcase, khong chi dem tong 126.
WITH row_counts AS (
SELECT 'roles' AS table_name, COUNT(*) AS row_count FROM `roles`
UNION ALL
SELECT 'positions' AS table_name, COUNT(*) AS row_count FROM `positions`
UNION ALL
SELECT 'users' AS table_name, COUNT(*) AS row_count FROM `users`
UNION ALL
SELECT 'employees' AS table_name, COUNT(*) AS row_count FROM `employees`
UNION ALL
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM `customers`
UNION ALL
SELECT 'suppliers' AS table_name, COUNT(*) AS row_count FROM `suppliers`
UNION ALL
SELECT 'categories' AS table_name, COUNT(*) AS row_count FROM `categories`
UNION ALL
SELECT 'products' AS table_name, COUNT(*) AS row_count FROM `products`
UNION ALL
SELECT 'promotions' AS table_name, COUNT(*) AS row_count FROM `promotions`
UNION ALL
SELECT 'product_price_history' AS table_name, COUNT(*) AS row_count FROM `product_price_history`
UNION ALL
SELECT 'imports' AS table_name, COUNT(*) AS row_count FROM `imports`
UNION ALL
SELECT 'import_details' AS table_name, COUNT(*) AS row_count FROM `import_details`
UNION ALL
SELECT 'product_units' AS table_name, COUNT(*) AS row_count FROM `product_units`
UNION ALL
SELECT 'shifts' AS table_name, COUNT(*) AS row_count FROM `shifts`
UNION ALL
SELECT 'cart_items' AS table_name, COUNT(*) AS row_count FROM `cart_items`
UNION ALL
SELECT 'orders' AS table_name, COUNT(*) AS row_count FROM `orders`
UNION ALL
SELECT 'order_details' AS table_name, COUNT(*) AS row_count FROM `order_details`
UNION ALL
SELECT 'order_status_history' AS table_name, COUNT(*) AS row_count FROM `order_status_history`
UNION ALL
SELECT 'deliveries' AS table_name, COUNT(*) AS row_count FROM `deliveries`
UNION ALL
SELECT 'delivery_items' AS table_name, COUNT(*) AS row_count FROM `delivery_items`
UNION ALL
SELECT 'delivery_status_history' AS table_name, COUNT(*) AS row_count FROM `delivery_status_history`
UNION ALL
SELECT 'invoices' AS table_name, COUNT(*) AS row_count FROM `invoices`
UNION ALL
SELECT 'invoice_details' AS table_name, COUNT(*) AS row_count FROM `invoice_details`
UNION ALL
SELECT 'payments' AS table_name, COUNT(*) AS row_count FROM `payments`
UNION ALL
SELECT 'returns' AS table_name, COUNT(*) AS row_count FROM `returns`
UNION ALL
SELECT 'warranties' AS table_name, COUNT(*) AS row_count FROM `warranties`
UNION ALL
SELECT 'warranty_claims' AS table_name, COUNT(*) AS row_count FROM `warranty_claims`
UNION ALL
SELECT 'warranty_claim_history' AS table_name, COUNT(*) AS row_count FROM `warranty_claim_history`
UNION ALL
SELECT 'stock_movements' AS table_name, COUNT(*) AS row_count FROM `stock_movements`
), expected_counts AS (
SELECT 'roles' AS table_name, 6 AS expected_count
UNION ALL
SELECT 'positions' AS table_name, 5 AS expected_count
UNION ALL
SELECT 'users' AS table_name, 7 AS expected_count
UNION ALL
SELECT 'employees' AS table_name, 5 AS expected_count
UNION ALL
SELECT 'customers' AS table_name, 3 AS expected_count
UNION ALL
SELECT 'suppliers' AS table_name, 3 AS expected_count
UNION ALL
SELECT 'categories' AS table_name, 5 AS expected_count
UNION ALL
SELECT 'products' AS table_name, 6 AS expected_count
UNION ALL
SELECT 'promotions' AS table_name, 2 AS expected_count
UNION ALL
SELECT 'product_price_history' AS table_name, 7 AS expected_count
UNION ALL
SELECT 'imports' AS table_name, 3 AS expected_count
UNION ALL
SELECT 'import_details' AS table_name, 6 AS expected_count
UNION ALL
SELECT 'product_units' AS table_name, 12 AS expected_count
UNION ALL
SELECT 'shifts' AS table_name, 3 AS expected_count
UNION ALL
SELECT 'cart_items' AS table_name, 1 AS expected_count
UNION ALL
SELECT 'orders' AS table_name, 1 AS expected_count
UNION ALL
SELECT 'order_details' AS table_name, 2 AS expected_count
UNION ALL
SELECT 'order_status_history' AS table_name, 4 AS expected_count
UNION ALL
SELECT 'deliveries' AS table_name, 1 AS expected_count
UNION ALL
SELECT 'delivery_items' AS table_name, 2 AS expected_count
UNION ALL
SELECT 'delivery_status_history' AS table_name, 2 AS expected_count
UNION ALL
SELECT 'invoices' AS table_name, 4 AS expected_count
UNION ALL
SELECT 'invoice_details' AS table_name, 7 AS expected_count
UNION ALL
SELECT 'payments' AS table_name, 3 AS expected_count
UNION ALL
SELECT 'returns' AS table_name, 3 AS expected_count
UNION ALL
SELECT 'warranties' AS table_name, 4 AS expected_count
UNION ALL
SELECT 'warranty_claims' AS table_name, 1 AS expected_count
UNION ALL
SELECT 'warranty_claim_history' AS table_name, 3 AS expected_count
UNION ALL
SELECT 'stock_movements' AS table_name, 15 AS expected_count
)
SELECT CONCAT('T10-02-',e.table_name) AS test_id,
       'Dem so ban ghi theo bang' AS purpose,
       e.table_name AS test_input,
       CAST(e.expected_count AS CHAR) AS expected,
       CAST(COALESCE(r.row_count,0) AS CHAR) AS actual,
       IF(r.row_count=e.expected_count,'PASS','FAIL') AS result
FROM expected_counts e LEFT JOIN row_counts r ON r.table_name=e.table_name
ORDER BY e.table_name;

SELECT
  'T10-03' AS test_id,
  'Tong ban ghi seed = 126' AS purpose,
  '29 bang' AS test_input,
  '126 records' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 126) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT (
    (SELECT COUNT(*) FROM `roles`)+
    (SELECT COUNT(*) FROM `positions`)+
    (SELECT COUNT(*) FROM `users`)+
    (SELECT COUNT(*) FROM `employees`)+
    (SELECT COUNT(*) FROM `customers`)+
    (SELECT COUNT(*) FROM `suppliers`)+
    (SELECT COUNT(*) FROM `categories`)+
    (SELECT COUNT(*) FROM `products`)+
    (SELECT COUNT(*) FROM `promotions`)+
    (SELECT COUNT(*) FROM `product_price_history`)+
    (SELECT COUNT(*) FROM `imports`)+
    (SELECT COUNT(*) FROM `import_details`)+
    (SELECT COUNT(*) FROM `product_units`)+
    (SELECT COUNT(*) FROM `shifts`)+
    (SELECT COUNT(*) FROM `cart_items`)+
    (SELECT COUNT(*) FROM `orders`)+
    (SELECT COUNT(*) FROM `order_details`)+
    (SELECT COUNT(*) FROM `order_status_history`)+
    (SELECT COUNT(*) FROM `deliveries`)+
    (SELECT COUNT(*) FROM `delivery_items`)+
    (SELECT COUNT(*) FROM `delivery_status_history`)+
    (SELECT COUNT(*) FROM `invoices`)+
    (SELECT COUNT(*) FROM `invoice_details`)+
    (SELECT COUNT(*) FROM `payments`)+
    (SELECT COUNT(*) FROM `returns`)+
    (SELECT COUNT(*) FROM `warranties`)+
    (SELECT COUNT(*) FROM `warranty_claims`)+
    (SELECT COUNT(*) FROM `warranty_claim_history`)+
    (SELECT COUNT(*) FROM `stock_movements`)
  ) AS actual
) AS x;

SELECT
  'T10-04' AS test_id,
  'Delivery items dung order voi phieu giao' AS purpose,
  'delivery_items / orders' AS test_input,
  '0 sai lech' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM delivery_items di
  JOIN deliveries dl ON dl.delivery_id=di.delivery_id
  JOIN order_details od ON od.order_detail_id=di.order_detail_id
  WHERE dl.order_id<>od.order_id
) AS x;

SELECT
  'T10-05' AS test_id,
  'Serial giao dung mau san pham da dat' AS purpose,
  'delivery_items / product_units' AS test_input,
  '0 sai lech' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM delivery_items di
  JOIN order_details od ON od.order_detail_id=di.order_detail_id
  JOIN product_units pu ON pu.unit_id=di.unit_id
  WHERE di.unit_id IS NOT NULL AND pu.product_id<>od.product_id
) AS x;

SELECT
  'T10-06' AS test_id,
  'Tong so luong giao khong qua da dat' AS purpose,
  'order_details/delivery_items' AS test_input,
  '0 don hang vuot' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM order_details od LEFT JOIN (
    SELECT order_detail_id,SUM(quantity) AS shipped FROM delivery_items GROUP BY order_detail_id
  ) di ON di.order_detail_id=od.order_detail_id WHERE COALESCE(di.shipped,0)>od.quantity
) AS x;

SELECT
  'T10-07' AS test_id,
  'Lich su gia khong chong lan' AS purpose,
  'product_price_history' AS test_input,
  '0 cap chong lan' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM product_price_history h1
  JOIN product_price_history h2 ON h1.product_id=h2.product_id
   AND h1.price_history_id<h2.price_history_id
  WHERE h1.effective_from<COALESCE(h2.effective_to, '9999-12-31 23:59:59')
    AND h2.effective_from<COALESCE(h1.effective_to, '9999-12-31 23:59:59')
) AS x;

SELECT
  'T10-08' AS test_id,
  'Moi san pham co duy nhat 1 gia mo' AS purpose,
  'product_price_history effective_to NULL' AS test_input,
  '0 product bat thuong' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM products p LEFT JOIN (
   SELECT product_id,COUNT(*) AS open_count FROM product_price_history
   WHERE effective_to IS NULL GROUP BY product_id
  ) h ON h.product_id=p.product_id
  WHERE COALESCE(h.open_count,0)<>1
) AS x;

SELECT
  'T10-09' AS test_id,
  'Gia hien hanh khop products.price' AS purpose,
  'product_price_history current' AS test_input,
  '0 product lech' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM products p
  JOIN product_price_history h ON h.product_id=p.product_id AND h.effective_to IS NULL
  WHERE p.price<>h.price
) AS x;

SELECT
  'T10-10' AS test_id,
  'Noi dung khuyen mai iPhone chi canh bao' AS purpose,
  'promotion_id=1' AS test_input,
  '3.13 (chu y quy tac lam tron)' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 3.13) THEN 'REVIEW' ELSE 'FAIL' END AS result
FROM (
  SELECT COALESCE((SELECT discount_percent FROM promotions WHERE promotion_id=1),-1) AS actual
) AS x;

SELECT
  'T10-11' AS test_id,
  'Giam gia goc tren chi tiet iPhone duoc giu' AS purpose,
  'invoice_detail_id=1' AS test_input,
  '1000000 dong' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 1000000) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COALESCE((SELECT CAST(discount_amount AS SIGNED) FROM invoice_details WHERE invoice_detail_id=1),-1) AS actual
) AS x;

SELECT
  'T10-12' AS test_id,
  'Khach hang vang lai #3 co hoa don cu' AS purpose,
  'customer_id=3' AS test_input,
  '1 invoice' AS expected,
  CAST(x.actual AS CHAR) AS actual,
  CASE WHEN (x.actual = 1) THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
  SELECT COUNT(*) AS actual FROM invoices WHERE customer_id=3
) AS x;

-- -----------------------------------------------------------------------------------
-- KET QUA THUC TE CUA STORED PROCEDURE - CAC LENH CALL KHONG TU CHO PASS/FAIL
-- -----------------------------------------------------------------------------------

-- Kiem tra bang mat: doi chieu ket qua CALL duoi day voi cac ORACLE T07/T08.
-- Kiem tra tu dong 2 result set: can integration test Python lay du lieu CALL.
-- Thang 10: sold=107500000, refund=500000, net=107000000.
-- Thang 11: sold=0, refund=500000, net=-500000.
-- San pham 5 thang 11: sold=0, returned=1, net_qty=-1, net=-500000.
CALL sp_get_product_revenue_stats('2026-10-01', '2026-10-31');
CALL sp_get_product_revenue_stats('2026-11-01', '2026-11-30');
CALL sp_get_product_revenue_stats('2026-12-01', '2026-12-31');
CALL sp_get_product_transactions(5, '2026-10-01', '2026-10-31');
CALL sp_get_product_transactions(5, '2026-11-01', '2026-11-30');

-- TRUONG HOP CHUA TU DONG KIEM THU BANG SQL THUAN (test Python ve sau):
-- - Thao tac sai: NULL/duplicate phone; customer member_since<registered_at;
--   vi pham CHECK/FK ghep/UNIQUE; expected MySQL 1048/1062/3819/1452.
-- - Mo phong luong dang ky moi va nang cap khach vang lai (UserDAO + CustomerDAO).
-- - Transaction rollback khi tao user thanh cong nhung tao customer that bai.
-- - Thao tac tra hang 2 lan cung thoi diem, tinh returned_quantity chong vuot.
-- - Hai luong thay doi ton kho/price/delivery dong thoi bang 2 connection.
-- - Stored Procedure SIGNAL cho start_date>end_date, NULL date/product_id.
-- - So sanh truc tiep 6 chi tieu theo san pham va 2 thang giua
--   sp_get_product_revenue_stats() voi SUM(result-set sp_get_product_transactions()).
-- - Tao dong giao dich luc 23:59:59 hoac DATETIME(6) o ngay ket thuc va
--   xac nhan ket qua CALL bao gom dong nay (fixture test rollback).
-- - Xac minh password_hash voi argon2-cffi (MySQL khong verify Argon2id).
-- Thu lai tren database test rieng. test.sql la read-only, co the chay nhieu lan.
