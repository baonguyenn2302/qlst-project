# Prompt vẽ Biểu đồ Hoạt động (Activity Diagrams)

## 1. Biểu đồ hoạt động thiết kế Module 1 (`act_m1.png`)
> Hãy vẽ Activity Diagram mức thiết kế cho **Module Đăng ký thành viên** theo chuẩn bài giảng PTTKHTTT và phong cách Visual Paradigm:
> - Dùng các khung bo tròn lớn màu xanh `Xử lý tại register.html` và `Xử lý tại RegistrationController / RegistrationService` chứa các nút hành động bên trong.
> - Hàng dưới cùng tách riêng các khối gọi phương thức DAO / Service thực tế: `RegistrationService.validate_input()`, `CustomerDAO.find_by_phone()`, `UserDAO.find_by_username()`, `PasswordService.hash_password()`, `UserDAO.create_customer_user()`, `CustomerDAO.create_member()`.
> - Thể hiện rõ luồng rẽ nhánh khi dữ liệu lỗi / trùng số điện thoại / trùng tên đăng nhập quay lại hiển thị thông báo lỗi trên `register.html`, và luồng thành công đi tới nút Kết thúc.

## 2. Biểu đồ hoạt động thiết kế Module 2 (`act_m2.png`)
> Hãy vẽ Activity Diagram mức thiết kế cho **Module Xem thống kê mặt hàng theo doanh thu & chi tiết giao dịch**:
> - Các khung xử lý theo màn hình/controller: `Xử lý tại menu.html`, `Xử lý tại reports.html`, `Xử lý tại revenue_report.html`, `Xử lý tại product_transactions.html`.
> - Hàng dưới cùng đặt các khối gọi hàm thực tế: `AuthenticationService.verify_manager()`, `RevenueService.validate_date_range()`, `RevenueDAO.get_product_revenue_stats()` (gọi `sp_get_product_revenue_stats`), `RevenueDAO.get_product_transactions()` (gọi `sp_get_product_transactions`).
> - Các mũi tên đi vuông góc rõ ràng, có nhãn điều kiện `[hợp lệ]`, `[lỗi khoảng ngày]`, `[chọn 1 mặt hàng]`, `[lấy xong dữ liệu]`.
