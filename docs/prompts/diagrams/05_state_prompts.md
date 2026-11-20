# Prompt vẽ Biểu đồ Trạng thái (State Machine Diagrams)

## 1. Biểu đồ trạng thái Module 1 (`state_m1.png`)
> Hãy vẽ State Machine Diagram **dạng dọc** theo phong cách Visual Paradigm cho **Module Đăng ký thành viên**:
> - Điểm bắt đầu (hình tròn đen đặc) ở trên cùng, mũi tên đi xuống kèm chữ `Bắt đầu`.
> - Các trạng thái hộp bo tròn màu xanh `#80CEFA` xếp dọc chính giữa:
>   1. `Hiển thị GD đăng ký thành viên`
>   2. `Kiểm tra dữ liệu và lưu tài khoản`
>   3. `Hiển thị thông báo đăng ký thành công`
> - Luồng đi xuống bên trái (`nhấn Đăng ký`), luồng lỗi quay ngược lên bên phải (`dữ liệu lỗi / trùng username hoặc SĐT`), luồng thành công đi xuống nút Kết thúc (vòng tròn đồng tâm) ở dưới cùng.

## 2. Biểu đồ trạng thái Module 2 (`state_m2.png`)
> Hãy vẽ State Machine Diagram **dạng dọc** cho **Module Xem thống kê mặt hàng theo doanh thu**:
> - Xếp dọc từ trên xuống:
>   1. `Hiển thị GD chính nhân viên quản lý`
>   2. `Hiển thị GD danh mục báo cáo`
>   3. `Hiển thị GD thống kê mặt hàng theo doanh thu` (có vòng lặp tự chuyển trạng thái bên phải: `nhập khoảng ngày & nhấn Thống kê`)
>   4. `Hiển thị GD chi tiết các lần giao dịch của mặt hàng`
> - Luồng tiến ở bên trái, luồng `chọn quay lại` ở bên phải mỗi tầng, và nút `Kết thúc` ở dưới cùng.
