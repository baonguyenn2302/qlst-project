# Prompt vẽ Biểu đồ Thiết kế Lớp chi tiết, Package & Deployment

## 1. Biểu đồ lớp thực thể mức thiết kế (`entity_design.png`)
> Hãy vẽ biểu đồ lớp thực thể mức thiết kế toàn hệ thống QLST:
> - Bổ sung khóa định danh (`user_id`, `customer_id`, `product_id`...) và kiểu dữ liệu Python (`int`, `str`, `Decimal`, `datetime`, `bool`).
> - Chuyển các quan hệ kết hợp sang kết tập (hình thoi rỗng `#agg`) và hợp thành (hình thoi đặc `#comp`) giữa `Import5`–`ImportDetail5`, `Order5`–`OrderDetail5`, `Invoice5`–`InvoiceDetail5`, `Product5`–`OrderDetail5`/`InvoiceDetail5`/`StockMovement5`.
> - Đảm bảo đầu hình thoi chạm chính xác mép ngoài khung bảng (không đâm vào trong) và mọi đường nối vuông góc không chồng chéo lên bảng.

## 2. Biểu đồ lớp thiết kế chi tiết Module 1 & Module 2 (`design_m1.png`, `design_m2.png`)
> Hãy vẽ biểu đồ lớp thiết kế chi tiết kiến trúc MVC + DAO/Service cho từng module:
> - Module 1 (`design_m1.png`): `register.html`, `RegistrationController`, `RegistrationService`, `PasswordService`, `UserDAO`, `CustomerDAO`, `Database`, `User`, `Customer`.
> - Module 2 (`design_m2.png`): `menu.html`, `reports.html`, `revenue_report.html`, `product_transactions.html`, `RevenueController`, `AuthenticationService`, `RevenueService`, `RevenueDAO`, `Database`, `ProductRevenue`, `ProductTransaction`.
> - Ghi rõ tên thuộc tính, kiểu dữ liệu và chữ ký đầy đủ các phương thức khớp 100% với mã nguồn Python.

## 3. Biểu đồ gói (`package.png`)
> Hãy vẽ Package Diagram tối giản theo phong cách Visual Paradigm:
> - Package cha `view` chứa 2 package con `templates` và `static`.
> - Nối tuần tự theo chiều dọc xuống các package `controller` → `dao` → `model`.

## 4. Biểu đồ triển khai (`deployment.png`)
> Hãy vẽ Deployment Diagram gồm 3 node 3D chuẩn UML mô tả môi trường vận hành thực tế:
> 1. `<<device>> Client Browser`: Trình duyệt Web (Chrome / Safari), HTML5/Jinja2 UI, Session Cookie (HttpOnly).
> 2. `<<executionEnvironment>> Flask App Server (macOS)`: Python 3.14.8 + Flask 3.1.3, Port `127.0.0.1:5000`.
> 3. `<<executionEnvironment>> Docker: qlst-mysql`: Docker Container (MySQL 8.x), `Host :3307 -> Container :3306`, Database `qlst` (29 bảng InnoDB, 2 Stored Procedures).
> - Ghi rõ giao thức kết nối `HTTP :5000` và `TCP/IP Host :3307 -> :3306`.
