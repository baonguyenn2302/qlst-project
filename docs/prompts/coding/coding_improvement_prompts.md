# Tổng hợp Prompt cải thiện mã nguồn dự án QLST (`qlst-project`)

Tài liệu này tổng hợp các prompt được sử dụng trong quá trình xây dựng, rà soát và tối ưu mã nguồn Python/Flask/MySQL cho **Hệ thống quản lý siêu thị điện máy (QLST)** gồm 2 module trọng tâm: **(1) Khách hàng đăng ký thành viên** và **(2) Nhân viên quản lý xem thống kê mặt hàng theo doanh thu & chi tiết giao dịch**.

---

## Prompt 1: Hoàn thiện xử lý giao dịch & chuẩn hóa số điện thoại cho Module 1 (Đăng ký thành viên)
> Hãy cải thiện `RegistrationService` và `CustomerDAO` để xử lý chặt chẽ các trường hợp biên khi khách hàng đăng ký thành viên:
> 1. Chuẩn hóa số điện thoại Việt Nam về định dạng 10 chữ số bắt đầu bằng `0` (chấp nhận đầu vào `0...`, `84...`, `+84...`, loại bỏ khoảng trắng và dấu gạch nối).
> 2. Kiểm tra trùng `username` trong `users` và kiểm tra `phone` trong `customers`:
>    - Nếu số điện thoại đã gắn với một `user_id` (`member_since IS NOT NULL`): từ chối đăng ký trùng.
>    - Nếu số điện thoại thuộc hồ sơ khách vãng lai (`user_id IS NULL`): từ chối ghi đè trực tiếp và thông báo yêu cầu xác minh số điện thoại trước khi liên kết tài khoản.
> 3. Bọc toàn bộ thao tác tạo bản ghi `users` (vai trò `customer`) và `customers` trong **một transaction duy nhất**, tự động `rollback()` nếu có bất kỳ lỗi ràng buộc hoặc ngoại lệ CSDL nào.

---

## Prompt 2: Tối ưu Stored Procedure & đảm bảo độ chính xác tài chính (`Decimal`) cho Module 2
> Hãy rà soát `database/procedures.sql`, `RevenueDAO` và `RevenueService` cho chức năng Thống kê mặt hàng theo doanh thu:
> 1. Trong `sp_get_product_revenue_stats(p_start_date, p_end_date)` và `sp_get_product_transactions(p_product_id, p_start_date, p_end_date)`:
>    - Kiểm tra khoảng ngày hợp lệ (`p_start_date <= p_end_date`), phát sinh `SQLSTATE '45000'` nếu sai.
>    - Tính doanh thu bán từ `invoices` (`status = 'completed'`) theo `invoice_date`, và tính hoàn trả từ `returns` (`status = 'completed'`) theo `completed_at` — **không** dùng `invoice_details.returned_quantity` để trừ ngược kỳ bán.
> 2. Giữ nguyên kiểu `Decimal` có dấu cho các trường `sales_revenue`, `refund_amount`, `net_revenue` (cho phép doanh thu ròng âm khi trong kỳ có phiếu trả lớn hơn lượng bán ra), tuyệt đối không ép kiểu `float` gây sai số làm tròn.
> 3. Trong `RevenueDAO._call_procedure()`, đọc hết mọi result set phụ bằng `while cursor.nextset()` để tránh lỗi mất đồng bộ kết nối PyMySQL khi tái sử dụng connection.

---

## Prompt 3: Xây dựng bộ kiểm thử tự động Unit & Integration Test an toàn dữ liệu
> Hãy viết bộ kiểm thử `unittest` trong `src/tests/` (`check_environment.py`, `test_registration.py`, `test_revenue.py`) đáp ứng:
> 1. Có lớp bảo vệ kết nối (`GuardedTestDatabase` tự động rollback/dọn dẹp dữ liệu thử nghiệm cho Module 1 và `GuardedRevenueDatabase` chỉ đọc cho Module 2) để không làm bẩn dữ liệu gốc.
> 2. Bao phủ đầy đủ: đăng ký thành công, trùng `username`, trùng `phone` khách vãng lai/thành viên, dữ liệu đầu vào lỗi; thống kê tháng 10 có dữ liệu, thống kê tháng 11 có doanh thu ròng âm (`-500.000 đ`), chi tiết giao dịch `INV-...` và `RET-...`, từ chối khoảng ngày ngược hoặc `product_id` không hợp lệ trước khi mở kết nối CSDL.
