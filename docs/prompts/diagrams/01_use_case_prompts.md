# Prompt vẽ Biểu đồ Use Case (Use Case Diagrams)

## 1. Biểu đồ Use Case tổng quan (`uc_tq.png`)
> Hãy vẽ biểu đồ Use Case tổng quan cho **Hệ thống quản lý siêu thị điện máy (Electronic Supermarket Management System)** theo phong cách Visual Paradigm (nền xanh nhạt `#80CEFA`, viền đen rõ nét):
> - Tác nhân cha: `Member5`, kế thừa bởi `Customer5` và `Staff5`; `Staff5` được kế thừa bởi `Manager5`, `WarehouseStaff5`, `SalesStaff5`.
> - Các Use Case trong ranh giới hệ thống:
>   - Của `Member5`: `Log in 5`, `Log out 5`.
>   - Của `Customer5`: `Register as member 5`, `Search products 5`, `Order online 5`, `Purchase at counter 5`.
>   - Của `Manager5`: `View statistics 5` (tổng quát hóa cho `View product revenue statistics 5`, `View supplier statistics 5`, `View revenue statistics 5`).
>   - Của `WarehouseStaff5`: `Receive products 5`, `Update information 5` (`Update product information 5`, `Update supplier information 5`), `Approve order and dispatch 5`.
>   - Của `SalesStaff5`: `Sell products at counter 5`.

## 2. Biểu đồ Use Case chi tiết Module 1 (`uc_m1.png`)
> Hãy vẽ biểu đồ Use Case chi tiết cho **Module Khách hàng đăng ký thành viên**:
> - Tác nhân: `Customer5` (kế thừa `Member5`).
> - Use Case chính: `Register as member 5` nối với `Customer5`.
> - Quan hệ `<<include>>` tới: `Enter registration info 5`, `Validate & normalize input 5`, `Create member account 5`.
> - Quan hệ `<<extend>>` từ: `Customer log in 5` (điểm mở rộng khi đã có tài khoản hoặc sau khi đăng ký thành công).

## 3. Biểu đồ Use Case chi tiết Module 2 (`uc_m2.png`)
> Hãy vẽ biểu đồ Use Case chi tiết cho **Module Nhân viên quản lý xem thống kê mặt hàng theo doanh thu**:
> - Tác nhân: `Manager5` (kế thừa `Staff5` → `Member5`).
> - Use Case chính: `View product revenue statistics 5` nối với `Manager5`.
> - Quan hệ `<<include>>` tới: `Manager log in 5`, `Select reports menu 5`, `Select date range 5`.
> - Quan hệ `<<extend>>` từ: `View product transactions 5` (khi quản lý chọn xem chi tiết các lần giao dịch của một mặt hàng trong bảng thống kê).
