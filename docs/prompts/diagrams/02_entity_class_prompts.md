# Prompt vẽ Biểu đồ Lớp Thực thể & Biểu đồ Lớp Phân tích

## 1. Biểu đồ lớp thực thể mức phân tích toàn hệ thống (`entity_analysis.png`)
> Hãy vẽ biểu đồ lớp thực thể mức phân tích cho hệ thống QLST theo phong cách Visual Paradigm (hộp màu xanh `#80CEFA`, tên lớp hậu tố `5`):
> - Các lớp thực thể: `Role5`, `User5`, `Employee5`, `Position5`, `Supplier5`, `Category5`, `Customer5`, `Import5`, `ImportDetail5`, `Product5`, `Order5`, `OrderDetail5`, `Invoice5`, `InvoiceDetail5`, `ProductUnit5`, `Delivery5`, `Payment5`, `Return5`, `Warranty5`, `StockMovement5`, cùng 2 lớp thống kê suy diễn `ProductTransaction5` và `ProductRevenue5`.
> - Dùng quan hệ kết hợp (association) ở mức phân tích; các đường nối đi vuông góc theo hành lang trống giữa các bảng, **tuyệt đối không cắt ngang hay đè lên khung bảng nào**.

## 2. Biểu đồ lớp phân tích Module 1 (`analysis_m1.png`)
> Hãy vẽ biểu đồ lớp phân tích theo mô hình BCE (Boundary – Control – Entity) cho **Module Đăng ký thành viên**:
> - `<<boundary>> RegistrationBoundary5`: `-inFullName`, `-inUsername`, `-inPassword`, `-inPhone`, `-inEmail`, `-inAddress`, `-subRegister`, `-outMessage`.
> - `<<control>> RegistrationController5`: `+showRegisterForm()`, `+submitRegistration()`.
> - `<<control>> RegistrationService5`: `+validateInput()`, `+normalizePhone()`, `+registerMember()`.
> - `<<entity>> User5`, `Customer5`, `Role5` cùng các thuộc tính và phương thức truy vấn khái niệm (`+findByUsername()`, `+findByPhone()`, `+getCustomerRole()`, `+create()`).

## 3. Biểu đồ lớp phân tích Module 2 (`analysis_m2.png`)
> Hãy vẽ biểu đồ lớp phân tích BCE cho **Module Xem thống kê mặt hàng theo doanh thu**:
> - `<<boundary>>`: `ManagerMenuBoundary5`, `ReportsMenuBoundary5`, `RevenueReportBoundary5` (gồm `-inoutStartDate`, `-inoutEndDate`, `-subViewStats`, `-outProductRevenueList`, `-subSelectProduct`, `-subBackToReports`, `-outMessage`), `ProductTransactionsBoundary5` (gồm `-outProductHeader`, `-outTransactionList`, `-subBackToReport`).
> - `<<control>>`: `AuthenticationService5` (`+verifyManagerAccess()`), `RevenueController5` (`+viewRevenueReport()`, `+viewProductTransactions()`), `RevenueService5` (`+validateDateRange()`, `+getProductRevenueStats()`, `+getProductTransactions()`).
> - `<<entity>>`: `ProductRevenue5` (`+getProductRevenueStats()`), `ProductTransaction5` (`+getProductTransactions()`), `Product5`, `Invoice5`.
> - Sắp xếp các ô thưa thoáng (khoảng cách 45–65px), đường nối chạm đúng mép khung.
