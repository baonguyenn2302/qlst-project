# Prompt vẽ Biểu đồ Giao tiếp (Communication) & Biểu đồ Tuần tự (Sequence)

## 1. Biểu đồ giao tiếp Module 1 (`comm_m1.png`)
> Hãy vẽ Communication Diagram theo phong cách Robustness (Actor ở trên cùng chính giữa, hàng giữa là các Boundary tròn có gạch đứng bên trái, hàng dưới là các Entity/Control tương ứng):
> - Actor `Customer5` tương tác với `RegistrationBoundary5` (nhập thông tin đăng ký, nhận thông báo) và `LoginBoundary5`.
> - `RegistrationBoundary5` kết nối với `User5`, `Customer5`, `Role5` kèm các lời gọi tự thân (`self-link`) kiểm tra trùng lặp và tạo tài khoản.
> - Các đường nối đi vuông góc và có mũi tên chỉ hướng độc lập kèm số thứ tự thông điệp (`1:`, `2:`, ...) khớp hoàn toàn với Kịch bản v2.0.

## 2. Biểu đồ giao tiếp Module 2 (`comm_m2.png`)
> Hãy vẽ Communication Diagram theo phong cách Robustness cho **Module Xem thống kê mặt hàng theo doanh thu**:
> - Actor `Manager5` ở trên cùng chính giữa.
> - Hàng Boundary: `ManagerMenuBoundary5` → `ReportsMenuBoundary5` → `RevenueReportBoundary5` → `ProductTransactionsBoundary5`.
> - Hàng Entity: `ProductRevenue5`, `ProductTransaction5` với các self-link `getProductRevenueStats()` và `getProductTransactions()`, đánh số thông điệp liên tục từ `1:` đến bước hiển thị chi tiết giao dịch.

## 3. Biểu đồ tuần tự thiết kế Module 1 (`seq_m1.png`)
> Hãy vẽ Sequence Diagram mức thiết kế cho **Module Đăng ký thành viên** với đầy đủ thanh kích hoạt (activation bar) và mũi tên đồng bộ/trả về (`- - ->`):
> - Các lifeline: `Customer`, `register.html`, `RegistrationController`, `RegistrationService`, `PasswordService`, `UserDAO`, `CustomerDAO`, `MySQL (qlst)`.
> - Thể hiện tuần tự 18 bước từ lúc mở `/register`, gửi POST + CSRF token, chuẩn hóa SĐT, kiểm tra trùng `phone`/`username`, băm mật khẩu Argon2id, mở transaction chèn `users` + `customers`, commit và hiển thị kết quả.

## 4. Biểu đồ tuần tự thiết kế Module 2 (`seq_m2.png`)
> Hãy vẽ Sequence Diagram mức thiết kế cho **Module Xem thống kê mặt hàng theo doanh thu**:
> - Các lifeline: `Manager`, `menu.html`, `reports.html`, `revenue_report.html`, `product_transactions.html`, `RevenueController`, `RevenueService`, `RevenueDAO`, `MySQL (qlst)`.
> - Thể hiện 2 pha tương tác liên tiếp: (1) Chọn khoảng ngày & nhấn Thống kê → gọi `sp_get_product_revenue_stats`, hiển thị bảng 11 cột; (2) Nhấp `Xem chi tiết giao dịch` → gọi `sp_get_product_transactions`, hiển thị bảng 12 cột.
