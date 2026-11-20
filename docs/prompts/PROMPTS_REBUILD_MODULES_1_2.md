# BỘ PROMPT TÁI TẠO ĐỘC LẬP MODULE 1 & MODULE 2

**Hệ thống quản lý siêu thị điện máy — đặc tả, chuỗi prompt thực thi và phụ lục nguồn nội tại**

- **Mục đích:** tài liệu nộp giảng viên và bàn giao cho một AI Agent mới để tái tạo dự án từ đầu.
- **Ngôn ngữ tài liệu:** tiếng Việt; nguồn tham chiếu và tên API giữ nguyên theo code.
- **Baseline snapshot nguồn:** `370616beda985676e0de9ca92ecd59dae9596bd4`.
- **Mốc nghiệm thu hai module trước đó:** `430cfcf82e5c32dccbde1c91b2087e9e13f694c1`.
- **Chứng cứ:** ZIP nguồn do người thực hiện cung cấp, `MANIFEST.json` có 38 file được chọn (gồm 22 file `.py`, 5 file `.sql`, 6 file `.html`, file môi trường và cấu hình); kết quả nghiệm thu do người thực hiện xác nhận.
- **Phạm vi:** Module 1 (đăng ký thành viên), Module 2 (báo cáo doanh thu sản phẩm và chi tiết giao dịch), database nền hỗ trợ, Flask/Jinja2 và kiểm thử. **Không khẳng định** có giao diện nghiệp vụ cho mọi bảng trong schema.

> **Cách dùng với Agent mới:** Gửi **toàn bộ file Markdown này** vào cuộc trò chuyện mới. Yêu cầu Agent đọc Phần 1–3, sau đó thực hiện lần lượt `PROMPT-001` đến prompt cuối tại Phần 4. Các phụ lục chứa DDL/Stored Procedure, dữ liệu mẫu, mã tham chiếu và test — **ngay trong tài liệu**, không cần GitHub, repository gốc hoặc lịch sử chat. Mọi phần liên quan đến mật khẩu/khóa chỉ được thiết lập cục bộ bằng biến môi trường. Các ví dụ SQL có `DROP` là phá hủy dữ liệu: chỉ thực thi trên DB mới có chủ đích, không dùng trên DB hiện có.

## Phần 1 — Thông tin bài tập lớn và mục đích sử dụng AI

### 1.1. Phạm vi đã triển khai

- **Module 1:** `/register` GET/POST, tạo tài khoản và hồ sơ khách hàng mới bằng transaction, CSRF, Argon2id; từ chối username trùng, khách đã là thành viên và hồ sơ khách vãng lai chưa được xác minh. **OTP chưa triển khai**, không tự động liên kết hồ sơ vãng lai.
- **Module 2:** `/reports` chọn báo cáo, `/revenue` thống kê theo hai ngày, `/revenue/products/<product_id>/transactions` xem từng giao dịch bán/hoàn trả; kết quả đọc từ đúng hai Stored Procedure, không sửa dữ liệu.
- **Nền tảng:** Python 3.14.8, Flask 3.1.3, PyMySQL 1.2.4, `argon2-cffi` 25.1.0, `python-dotenv` 1.2.4, MySQL/InnoDB UTF8MB4, Jinja2/HTML thuần, CSS inline tối thiểu, không cần JavaScript.
- **Kiến trúc:** `app.py` → Flask Blueprint Controller (`src/controller`) → Service trong `src/model` → DAO (`src/dao`) → MySQL; dataclass model trong `src/model`; view HTML trong `view/templates`; `src/config.py` đọc `.env` (không commit). Riêng `view/base.html` trong snapshot rỗng, chưa được sử dụng làm template bố cục.
- **Không triển khai trong hai module:** đăng nhập/quên mật khẩu, OTP xác minh, quản lý đơn hàng/nhập hàng/bảo hành bằng giao diện, CRUD của 29 bảng, dashboard ngoài báo cáo sản phẩm; các bảng còn lại của schema chỉ là nền dữ liệu và ràng buộc.

### 1.2. Nguyên tắc dùng AI

1. Mỗi prompt bên dưới là **prompt tái cấu trúc**, soạn sau khi đọc snapshot mã nguồn; không ghi nhãn là prompt gốc đã dùng trong quá khứ.
2. Một số câu lệnh yêu cầu giao diện/điều hướng thật sự được người thực hiện đưa trong cuộc trò chuyện hiện có, được dẫn ở Phần 2 như **trích dẫn prompt gốc có phạm vi hữu hạn**.
3. Tái tạo tương đương hành vi, schema, hợp đồng và kết quả kiểm thử. Không mở rộng nghiệp vụ.
4. Trước mỗi thao tác phá hủy DB phải xác nhận môi trường mới; test ghi dữ liệu chỉ dùng `qlst_test` với chốt bảo vệ host/port/database và cleanup.

## Phần 2 — Cơ sở xây dựng bộ prompt và tính trung thực

### 2.1. Phân loại bằng chứng

| Nhóm                   | Nguồn                                                              | Mức tin cậy / giới hạn                                                                                |
| ---------------------- | ------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------- |
| Mã nguồn P2            | 38 file trong snapshot ZIP tại baseline đã nêu                     | Đã đọc trực tiếp nội dung; chưa chạy MySQL/Flask ở phiên soạn tài liệu này                            |
| Database               | `init.sql`, `schema.sql`, `procedures.sql`, `seed.sql`, `test.sql` | DDL, 29 bảng và 2 procedure lấy nguyên lý từ SQL; phép kiểm tra kết quả runtime cần chạy khi dựng mới |
| Service/DAO/Controller | Python và Jinja2 của hai module                                    | Tên hàm, validation, lỗi, field mapping được trích trực tiếp                                          |
| Nghiệm thu             | Kết quả người thực hiện báo trong cuộc hội thoại                   | Đã báo PASS ở dự án gốc, **không thay thế** việc kiểm thử của bản tái tạo                             |
| Prompt gốc             | Các câu yêu cầu thực sự hiện diện trong cuộc trao đổi đã cung cấp  | Chỉ trích ví dụ xác minh được; **không tuyên bố** có toàn bộ lịch sử gốc                              |

### 2.2. Một số trích đoạn prompt gốc có thể xác minh (không phải bộ prompt đầy đủ)

- “Tôi chỉ muốn căn giữa vị trí của toàn bộ bảng, không phải căn giữa toàn bộ chữ hoặc số trong các ô.” — yêu cầu trực tiếp về hai bảng báo cáo.
- “Không được trình bày prompt tái cấu trúc như thể đó là bản ghi nguyên văn của những prompt tôi đã sử dụng trước đây.” — yêu cầu trực tiếp về xuất xứ tài liệu.
- “Một AI Agent mới, trong cuộc trò chuyện hoàn toàn mới, chỉ cần nhận nội dung file Markdown này là có thể xây dựng lại một phiên bản tương đương của hệ thống hiện tại” — mục tiêu tài liệu do người thực hiện đưa ra.

Đây là **trích đoạn**, không phải bản chép toàn bộ prompt triển khai Module 1/Module 2; các prompt có đánh số sau đây là **tái cấu trúc**.

### 2.3. Quy ước riêng tư và tái tạo

Các phụ lục chứa **bản sao nguồn nội tại đã được xử lý an toàn**, không phải cam kết giống từng byte với Git. Đã thay tên, email, số liên hệ và địa chỉ minh họa trong dữ liệu mẫu bằng thông tin thử nghiệm, giữ nguyên khóa ngoại, ID, ngày, số lượng, giá và công thức; đồng bộ thay giá trị fixture trong test tương ứng. Hai file `.env.example` và `init.sql` được dựng lại an toàn vì bản ZIP đã che giá trị xác thực và phần `.env.example` sau che có một dòng bị dính; các giá trị cấu hình được khôi phục từ `src/config.py`. Khóa chuỗi nội bộ `_CSRF_SESSION_KEY` được đặt tên an toàn trong phụ lục thay cho một chuỗi ngẫu nhiên từ baseline; **đây không phải Flask `SECRET_KEY`**. Một mật khẩu thử nghiệm tĩnh trong test cũng được thay bằng mẫu không phải mật khẩu thật; 7 hash mật khẩu của seed demo được tạo lại từ các chuỗi ngẫu nhiên không lưu giữ, vẫn theo Argon2id và giữ nguyên chức năng kiểm thử. Tất cả thay đổi ở **tài liệu**, không có sửa file dự án gốc.

**Giới hạn thực chứng:** snapshot không chứa các prompt gốc đầy đủ, README/run.txt/view/base.html có nội dung rỗng, thư mục `docs/diagrams` rỗng; không có bằng chứng để mô tả UML đã hoàn thiện. Việc thay `_CSRF_SESSION_KEY` ở commit sau mốc nghiệm thu có thể làm phiên form cũ mất token hợp lệ; chưa có nghiệm thu lại riêng cho thay đổi này. Đây là giới hạn cần ghi trong báo cáo, không tự nhận PASS.

## Phần 3 — Đặc tả độc lập để tái tạo hệ thống

### 3.1. Cây dự án cần tạo

Dựng đúng đường dẫn trong bảng và cây dưới đây. Các file `__init__.py` rỗng được phép giữ rỗng. `docs/diagrams/*` và `view/static/css|js` là thư mục chuẩn bị, **chưa có sơ đồ hoặc tài nguyên giao diện hoàn chỉnh** trong snapshot.

```text
[FILE] .env.example
[FILE] .gitignore
[FILE] README.md
[FILE] app.py
[FILE] requirements.txt
[FILE] run.txt
[DIR] database
[FILE] database/init.sql
[FILE] database/procedures.sql
[FILE] database/schema.sql
[FILE] database/seed.sql
[FILE] database/test.sql
[DIR] docs
[DIR] docs/diagrams
[DIR] docs/diagrams/01_use_case [EMPTY]
[DIR] docs/diagrams/02_entity_class [EMPTY]
[DIR] docs/diagrams/03_activity [EMPTY]
[DIR] docs/diagrams/04_sequence [EMPTY]
[DIR] docs/diagrams/05_state [EMPTY]
[DIR] docs/diagrams/06_ui_navigation [EMPTY]
[DIR] docs/diagrams/07_database_erd [EMPTY]
[DIR] docs/diagrams/08_design_class_mvc [EMPTY]
[DIR] docs/report [EMPTY]
[DIR] src
[FILE] src/__init__.py
[FILE] src/config.py
[DIR] src/controller
[FILE] src/controller/__init__.py
[FILE] src/controller/registration_controller.py
[FILE] src/controller/revenue_controller.py
[DIR] src/dao
[FILE] src/dao/__init__.py
[FILE] src/dao/customer_dao.py
[FILE] src/dao/db.py
[FILE] src/dao/revenue_dao.py
[FILE] src/dao/user_dao.py
[DIR] src/model
[FILE] src/model/__init__.py
[FILE] src/model/customer.py
[FILE] src/model/password_service.py
[FILE] src/model/registration_service.py
[FILE] src/model/revenue.py
[FILE] src/model/revenue_service.py
[FILE] src/model/user.py
[DIR] src/tests
[FILE] src/tests/__init__.py
[FILE] src/tests/check_environment.py
[FILE] src/tests/test_registration.py
[FILE] src/tests/test_revenue.py
[DIR] view
[FILE] view/base.html
[DIR] view/static
[DIR] view/static/css [EMPTY]
[DIR] view/static/js [EMPTY]
[DIR] view/templates
[FILE] view/templates/index.html
[FILE] view/templates/product_transactions.html
[FILE] view/templates/register.html
[FILE] view/templates/reports.html
[FILE] view/templates/revenue_report.html
```

Ghi chú: `README.md`, `run.txt`, `view/base.html` thực sự rỗng trong snapshot. Khi tái tạo, giữ trạng thái rỗng để giống baseline hoặc chỉ viết hướng dẫn chạy trong tài liệu ngoài phạm vi runtime; không tự coi nội dung hướng dẫn do Agent viết là một phần của baseline đã nghiệm thu. `docs/report/PROMPTS_REBUILD_MODULES_1_2.md` chính là tài liệu bàn giao đang đọc, không phải file ứng dụng.

### 3.2. Môi trường và cách chạy

- Tạo `.venv` với Python 3.14.8; cài bằng `pip install -r requirements.txt` (phiên bản chính xác tại Phụ lục nguồn).
- MySQL chạy trên `127.0.0.1:3307` (ví dụ Docker host port 3307 ánh xạ container 3306); user ứng dụng có quyền phù hợp, không root. Tạo `.env` cục bộ với `FLASK_SECRET_KEY`, `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DATABASE`, `MYSQL_CONNECT_TIMEOUT`; `FLASK_DEBUG=0` là cấu hình ví dụ, app tự chạy `debug=False`.
- `src/config.py`: `load_dotenv(PROJECT_ROOT/'.env', override=False)`; `get_flask_secret_key()` từ chối chuỗi rỗng hoặc bắt đầu `CHANGE_ME`; `DatabaseSettings.from_env()` bắt buộc username/password không rỗng, port 1..65535, timeout dương; mặc định host `127.0.0.1`, port `3307`, database `qlst`.
- `Database.open()`: `pymysql.connect(..., charset='utf8mb4', cursorclass=DictCursor, autocommit=False)`; `Database.connection()` chỉ đóng kết nối; `Database.transaction()` commit thành công, rollback trên **mọi** lỗi, luôn đóng kết nối.
- Ứng dụng chính chạy tại `127.0.0.1:5000` bằng `python -B app.py`. Không suy ra trạng thái DB từ `/health` (route này chỉ xác nhận Flask hoạt động).
- **Không đặt password/secret trong repo hoặc Markdown.** Mật khẩu của user ứng dụng trong bản sao `init.sql` chỉ là placeholder, phải thay bằng giá trị mạnh cục bộ đồng nhất với `.env` trước khi chạy. SQL `init.sql` có `DROP`, chỉ dùng trên MySQL demo mới; quy trình xây dựng `qlst_test` từ một database test riêng phải kiểm tra DB đích trước khi apply DDL/seed.

### 3.3. Tuyến HTTP và endpoint (Flask)

| Đường dẫn                                   | HTTP     | Endpoint                | Hiển thị                    | Hành vi                                                      |
| ------------------------------------------- | -------- | ----------------------- | --------------------------- | ------------------------------------------------------------ |
| /                                           | GET      | `home`                  | `index.html`                | Trang menu hệ thống; chỉ có nút Xem báo cáo                  |
| /reports                                    | GET      | `reports_menu`          | `reports.html`              | Hai form GET chọn báo cáo / quay lại /                       |
| /health                                     | GET      | `health`                | JSON                        | `status=ok`, `component=flask`, không gọi MySQL              |
| /register                                   | GET/POST | `registration.register` | `register.html`             | GET tạo CSRF token; POST validate CSRF và gọi Service        |
| /revenue                                    | GET      | `revenue.report`        | `revenue_report.html`       | Không ngày: hiện form; có ngày: thống kê hoặc 400/503        |
| /revenue/products/<product_id>/transactions | GET      | `revenue.transactions`  | `product_transactions.html` | ID số nguyên, ngày từ query string, trả dữ liệu hoặc 400/503 |

### 3.4. Module 1 — Đăng ký thành viên

**Input POST:** `full_name`, `username`, `password`, `phone` bắt buộc; `email`, `address` tùy chọn; hidden `csrf_token`. GET hiển thị form, thông điệp flash và lỗi. Khi lỗi giữ giá trị của `full_name`, `phone`, `username`, `email`, `address` nhưng **không** đưa mật khẩu cũ vào HTML.

**Chuẩn hóa & validation đúng với `RegistrationService`:**

- `full_name`: loại dư khoảng trắng giữa từ bằng `' '.join(value.split())`; không rỗng, tối đa 100 ký tự.
- `username`: trim hai đầu, không rỗng, tối đa 50 ký tự, không chứa ký tự khoảng trắng bên trong; so trùng **theo giá trị nguyên sau trim**, không tự lowercase.
- `phone`: bỏ các dấu cách và `(` `)` `.` `-`; chấp nhận `+84...` hoặc `84...` dài 11 chữ số và đổi về `0...`; sau chuẩn hóa buộc regex `0[0-9]{9}`. Không coi chuẩn hóa là xác minh số điện thoại.
- `password`: string từ 8 đến 256 ký tự; chỉ giữ trong bộ nhớ trong thời gian tạo hash; `PasswordService` dùng `argon2.PasswordHasher(type=Type.ID)`, hỗ trợ verify và needs_rehash.
- `email`: trim, rỗng thành `None`, tối đa 100 ký tự; phải khớp `[^@\s]+@[^@\s]+\.[^@\s]+` nếu có.
- `address`: trim, rỗng thành `None`, tối đa 255 ký tự.

**Luồng giao dịch:** thực hiện validate ngoài connection; `Database.transaction()` mở một connection dùng chung cho DAO. `CustomerDAO.find_by_phone()` tra hồ sơ hiện có; nếu `is_member` → `AlreadyRegisteredError`; nếu có hồ sơ vãng lai → `GuestVerificationRequiredError`, **không gọi `link_user()`** vì OTP chưa triển khai. Sau đó `UserDAO.find_by_username()` từ chối trùng. Tra vai trò `roles.code='customer'` (không hardcode `role_id=6`), hash mật khẩu, lấy một timestamp `clock().replace(microsecond=0)`, tạo users rồi customers trong cùng transaction, `loyalty_points=0`, `registered_at=member_since` và liên kết `customers.user_id=users.user_id`. Thành công trả `RegistrationResult` **sau commit**.

**Concurrency và lỗi:** `IntegrityError 1062` theo tên index `uq_users_username` → lỗi tên trùng; `uq_customers_phone` → conflict; 1205/1213 → retryable; lỗi DB khác → 503, không lộ SQL. Controller map validation 400; xung đột 409; lỗi retry/storage 503. CSRF token do `secrets.token_urlsafe(32)` lưu trong Flask session, kiểm tra bằng `secrets.compare_digest`; từ chối POST sai CSRF 400 và xóa token, tạo token mới; đăng ký thành công xóa token, flash success, redirect 303 GET `/register`. Biến `_CSRF_SESSION_KEY` là **tên key trong session** (không phải secret); khi đổi tên, token lưu theo key cũ không còn được đọc từ phiên trước. Phải nghiệm thu lại nếu thay đổi key trong dự án đang phục vụ người dùng.

**Mô hình:** `User(user_id, username, password_hash[repr=False], role_id, is_active, last_login_at, created_at)`; `Customer(customer_id, user_id?, full_name, phone, email?, address?, loyalty_points, registered_at, member_since?, is_active)`, `is_member` đúng khi cả `user_id` và `member_since` khác None. `RegistrationResult(user_id, customer_id, username, full_name, phone, member_since)`.

**Khác biệt có chủ ý:** `CustomerDAO.link_user` đã có API hỗ trợ hồ sơ vãng lai sau xác minh, nhưng **không được sử dụng** trong flow đăng ký hiện tại.

### 3.5. Module 2 — Doanh thu sản phẩm

- `RevenueController._parse_date_range()`: phải có cả `start_date`, `end_date`; dùng `date.fromisoformat`, sau đó so khớp `isoformat()` để chỉ nhận đúng `YYYY-MM-DD`; báo 400 nếu thiếu/sai. Service `_validate_dates` yêu cầu `type(x) is date` (không nhận `datetime`), `start <= end`.
- `RevenueController._parse_product_id()`: chuyển string sang int; Service yêu cầu `type(id) is int` và `1 <= id <= 4_294_967_295` (miền `INT UNSIGNED`).
- Không có tham số ngày nào: render form báo cáo mà **không mở DB**. GET hợp lệ: Service sử dụng `Database.connection()`, gọi DAO, trả `list[ProductRevenue]` hoặc `list[ProductTransaction]`; `[]` nghĩa là không có dữ liệu, không phải lỗi DB. Lỗi MySQL → `RevenueStorageError`, Controller trả 503 và thông điệp an toàn.
- DAO `_call_procedure()` dùng `DictCursor.callproc`, lấy result set đầu, đọc hết `nextset()` kể cả phần dư để connection tái sử dụng; tuyệt đối không tái tính số tiền trong Python.
- `ProductRevenue` có **13 field** theo đúng thứ tự procedure: `product_id`, `name`, `brand`, `barcode`, `category_id`, `category_name`, `current_list_price`, `quantity_sold`, `quantity_returned`, `net_quantity`, `sales_revenue`, `refund_amount`, `net_revenue`.
- `ProductTransaction` có **23 field** theo đúng thứ tự procedure: `transaction_type`, `transaction_at`, `document_type`, `document_id`, `document_code`, `product_id`, `product_name`, `invoice_id`, `invoice_detail_id`, `return_id`, `channel`, `quantity_sold`, `quantity_returned`, `net_quantity`, `sales_revenue`, `refund_amount`, `net_revenue`, `unit_price`, `original_line_discount`, `unit_id`, `serial_number`, `customer_name`, `customer_phone`.
- Model là `@dataclass(frozen=True, slots=True)`; `from_row` ép ID/quantities sang `int`, tiền/giá sang `Decimal`, giữ `None` cho field tùy chọn; giữ nguyên số âm.

**Công thức và thời điểm ghi nhận (theo SQL tại Phụ lục):**

- Chỉ tính `invoices.status='completed'` và dòng `invoice_details.is_active=TRUE`.
- Bán trong kỳ: `invoice_date >= start_date` và `< DATE_ADD(end_date, INTERVAL 1 DAY)`. `sales_revenue = quantity * unit_price - discount_amount` của **dòng hóa đơn**, không lấy giá niêm yết hiện tại.
- Hoàn trả trong kỳ: chỉ `returns.status='completed'`, `completed_at` trong khoảng ngày tương tự, gắn với dòng hóa đơn còn hiệu lực và hóa đơn completed. `refund_amount` lấy từ **phiếu trả**, không tính lại. Không dùng `invoice_details.returned_quantity` để trừ ngược doanh thu kỳ bán.
- Mỗi sale có `quantity_returned=0`, `refund_amount=0`; mỗi return có `quantity_sold=0`, `sales_revenue=0`; dùng `UNION ALL` tránh nhân bản qua JOIN giữa sale và return.
- `net_quantity = quantity_sold - quantity_returned`; `net_revenue = sales_revenue - refund_amount`; các giá trị âm hoàn toàn hợp lệ (đặc biệt tháng chỉ có trả hàng).
- Nhóm theo sản phẩm, danh mục; order thống kê `net_revenue DESC, quantity_sold DESC, product_id ASC`. Chi tiết `transaction_at DESC`, `transaction_type ASC`, `document_id DESC`, `invoice_detail_id DESC`.

### 3.6. Hợp đồng giao diện chính xác

**Bảng thống kê 11 cột theo thứ tự:**

1. Mã sản phẩm; 2. Tên sản phẩm; 3. Thương hiệu; 4. Danh mục; 5. Số lượng bán; 6. Số lượng trả; 7. Số lượng ròng; 8. Doanh thu bán (đ); 9. Tiền hoàn trả (đ); 10. Doanh thu ròng (đ); 11. Chi tiết.

Có `<caption>Doanh thu theo từng sản phẩm</caption>`. Bảng `<table border="1" style="margin-left: auto; margin-right: auto;">`; hàng cuối `<tfoot>`: `<th scope="row" colspan="4" style="text-align: center;">TỔNG CỘNG</th>`, **6 tổng** (`quantity_sold`, `quantity_returned`, `net_quantity`, `sales_revenue`, `refund_amount`, `net_revenue`) và một ô cuối trống. Các cột số/tiền căn phải. Tiền Việt Nam format nguyên `"{:,.0f}".format(value) | replace(",", ".")` **không làm tròn/ép float ở Service**. Thương hiệu null hiện `Không có`. Link “Xem chi tiết giao dịch” dùng `url_for('revenue.transactions', product_id=..., start_date=..., end_date=...)`.

**Bảng chi tiết 12 cột theo thứ tự:**

1. Thời điểm; 2. Loại giao dịch; 3. Mã chứng từ; **4. Đơn giá (đ)**; 5. Số lượng bán; 6. Số lượng trả; 7. Số lượng ròng; 8. Doanh thu bán (đ); 9. Tiền hoàn trả (đ); 10. Doanh thu ròng (đ); 11. Mã phiếu trả; 12. Số serial.

Không có `<caption>`. Bảng cũng tự căn giữa. Hàng tổng `<th colspan="4" ...>TỔNG CỘNG</th>` + **6 tổng** + `<td colspan="2"></td>`; số/tiền căn phải. `transaction_type` `sale`→“Bán hàng”, `return`→“Hoàn trả”. `return_id` hoặc `serial_number` là None hiển thị `—`. Đơn giá vị trí 4 ngay cả với giao dịch hoàn trả. Header “Mã sản phẩm” và “Khoảng ngày” đặt phía trên bảng.

**Điều hướng không dùng JavaScript:** `index.html` GET button “Xem báo cáo” → `/reports`. `reports.html` GET button “Thống kê mặt hàng theo doanh thu” → `/revenue`; form GET “Quay lại menu hệ thống” → `/`, `style="margin-top: 16px;"`. `revenue_report.html` form GET chọn ngày và nút “Thống kê” ở trái; form GET quay về `/reports` `style="text-align: right;"`. `product_transactions.html` form GET quay về `revenue.report`, `style="text-align: right;"`, bên trong chứa đúng hai hidden input `start_date`, `end_date` và submit button. Khi quay về `/revenue?start_date=2026-10-01&end_date=2026-10-31`, form ngày vẫn hiện đúng giá trị.

### 3.7. Database — bảng, liên hệ và ràng buộc

`schema.sql` có **29 bảng**, `InnoDB`/`utf8mb4_unicode_ci`, 2 Stored Procedure nằm riêng trong `procedures.sql`. Không được rút gọn 29 bảng thành một database mini rồi tuyên bố tương đương, vì hai module phụ thuộc ngữ nghĩa FK và dữ liệu demo. Bản SQL đầy đủ và chính xác đã nằm trong **Phụ lục A**, kể cả PK, FK, UNIQUE, CHECK, index, generated columns, ENUM và thứ tự tạo bảng.

| STT | Bảng                      | Số cột | Trường & kiểu (tóm tắt; chi tiết xem DDL)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | PK                        |
| --- | ------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------- |
| 1   | `roles`                   | 3      | `role_id` INT UNSIGNED, `code` VARCHAR(30), `name` VARCHAR(100)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | `role_id`                 |
| 2   | `positions`               | 2      | `position_id` INT UNSIGNED, `name` VARCHAR(50)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | `position_id`             |
| 3   | `users`                   | 7      | `user_id` INT UNSIGNED, `username` VARCHAR(50), `password_hash` VARCHAR(255), `role_id` INT UNSIGNED, `is_active` BOOLEAN, `last_login_at` DATETIME, `created_at` DATETIME                                                                                                                                                                                                                                                                                                                                                                                                                                                  | `user_id`                 |
| 4   | `employees`               | 8      | `employee_id` INT UNSIGNED, `user_id` INT UNSIGNED, `full_name` VARCHAR(100), `phone` VARCHAR(15), `email` VARCHAR(100), `hire_date` DATE, `position_id` INT UNSIGNED, `is_active` BOOLEAN                                                                                                                                                                                                                                                                                                                                                                                                                                  | `employee_id`             |
| 5   | `customers`               | 10     | `customer_id` INT UNSIGNED, `user_id` INT UNSIGNED, `full_name` VARCHAR(100), `phone` VARCHAR(15), `email` VARCHAR(100), `address` VARCHAR(255), `loyalty_points` BIGINT UNSIGNED, `registered_at` DATETIME, `member_since` DATETIME, `is_active` BOOLEAN                                                                                                                                                                                                                                                                                                                                                                   | `customer_id`             |
| 6   | `suppliers`               | 7      | `supplier_id` INT UNSIGNED, `name` VARCHAR(100), `tax_code` VARCHAR(20), `phone` VARCHAR(15), `email` VARCHAR(100), `address` VARCHAR(255), `is_active` BOOLEAN                                                                                                                                                                                                                                                                                                                                                                                                                                                             | `supplier_id`             |
| 7   | `categories`              | 3      | `category_id` INT UNSIGNED, `name` VARCHAR(100), `is_active` BOOLEAN                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | `category_id`             |
| 8   | `products`                | 13     | `product_id` INT UNSIGNED, `name` VARCHAR(150), `brand` VARCHAR(50), `barcode` VARCHAR(30), `description` TEXT, `image_url` VARCHAR(255), `category_id` INT UNSIGNED, `price` BIGINT UNSIGNED, `cost_price` BIGINT UNSIGNED, `warranty_months` TINYINT UNSIGNED, `is_serialized` BOOLEAN, `stock_quantity` INT UNSIGNED, `is_active` BOOLEAN                                                                                                                                                                                                                                                                                | `product_id`              |
| 9   | `promotions`              | 6      | `promotion_id` INT UNSIGNED, `product_id` INT UNSIGNED, `category_id` INT UNSIGNED, `discount_percent` DECIMAL(5,2), `start_date` DATETIME, `end_date` DATETIME                                                                                                                                                                                                                                                                                                                                                                                                                                                             | `promotion_id`            |
| 10  | `product_price_history`   | 5      | `price_history_id` INT UNSIGNED, `product_id` INT UNSIGNED, `price` BIGINT UNSIGNED, `effective_from` DATETIME, `effective_to` DATETIME                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | `price_history_id`        |
| 11  | `product_units`           | 5      | `unit_id` INT UNSIGNED, `product_id` INT UNSIGNED, `serial_number` VARCHAR(50), `status` ENUM('in_stock', 'reserved', 'sold', 'returned', 'damaged'), `import_detail_id` INT UNSIGNED                                                                                                                                                                                                                                                                                                                                                                                                                                       | `unit_id`                 |
| 12  | `imports`                 | 4      | `import_id` INT UNSIGNED, `import_date` DATETIME, `supplier_id` INT UNSIGNED, `employee_id` INT UNSIGNED                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    | `import_id`               |
| 13  | `import_details`          | 5      | `import_detail_id` INT UNSIGNED, `import_id` INT UNSIGNED, `product_id` INT UNSIGNED, `quantity` INT UNSIGNED, `unit_cost` BIGINT UNSIGNED                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | `import_detail_id`        |
| 14  | `shifts`                  | 7      | `shift_id` INT UNSIGNED, `employee_id` INT UNSIGNED, `opened_at` DATETIME, `closed_at` DATETIME, `opening_cash` BIGINT UNSIGNED, `closing_cash` BIGINT UNSIGNED, `status` ENUM('open', 'closed')                                                                                                                                                                                                                                                                                                                                                                                                                            | `shift_id`                |
| 15  | `cart_items`              | 4      | `customer_id` INT UNSIGNED, `product_id` INT UNSIGNED, `quantity` INT UNSIGNED, `added_at` DATETIME                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | `customer_id, product_id` |
| 16  | `orders`                  | 17     | `order_id` INT UNSIGNED, `order_code` VARCHAR(20), `customer_id` INT UNSIGNED, `order_date` DATETIME, `shipping_name` VARCHAR(100), `shipping_phone` VARCHAR(15), `shipping_address` VARCHAR(255), `subtotal_amount` BIGINT UNSIGNED, `discount_amount` BIGINT UNSIGNED, `shipping_fee` BIGINT UNSIGNED, `total_amount` BIGINT UNSIGNED, `payment_method` ENUM('cash', 'card', 'bank_transfer', 'cod'), `payment_status` ENUM('unpaid', 'paid'), `status` ENUM('pending', 'approved', 'delivering', 'delivered', 'cancelled'), `cancel_reason` VARCHAR(255), `approved_by_employee_id` INT UNSIGNED, `approved_at` DATETIME | `order_id`                |
| 17  | `order_details`           | 7      | `order_detail_id` INT UNSIGNED, `order_id` INT UNSIGNED, `product_id` INT UNSIGNED, `quantity` INT UNSIGNED, `unit_price` BIGINT UNSIGNED, `discount_amount` BIGINT UNSIGNED, `promotion_id` INT UNSIGNED                                                                                                                                                                                                                                                                                                                                                                                                                   | `order_detail_id`         |
| 18  | `order_status_history`    | 7      | `history_id` INT UNSIGNED, `order_id` INT UNSIGNED, `from_status` VARCHAR(20), `to_status` VARCHAR(20), `changed_by_user_id` INT UNSIGNED, `reason` VARCHAR(255), `changed_at` DATETIME                                                                                                                                                                                                                                                                                                                                                                                                                                     | `history_id`              |
| 19  | `deliveries`              | 9      | `delivery_id` INT UNSIGNED, `order_id` INT UNSIGNED, `exported_by_employee_id` INT UNSIGNED, `delivery_staff_id` INT UNSIGNED, `exported_at` DATETIME, `delivered_at` DATETIME, `status` ENUM('delivering', 'delivered', 'failed'), `failed_reason` VARCHAR(255), `cod_collected_amount` BIGINT UNSIGNED                                                                                                                                                                                                                                                                                                                    | `delivery_id`             |
| 20  | `delivery_items`          | 5      | `delivery_item_id` INT UNSIGNED, `delivery_id` INT UNSIGNED, `order_detail_id` INT UNSIGNED, `unit_id` INT UNSIGNED, `quantity` INT UNSIGNED                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | `delivery_item_id`        |
| 21  | `delivery_status_history` | 7      | `history_id` INT UNSIGNED, `delivery_id` INT UNSIGNED, `from_status` VARCHAR(20), `to_status` VARCHAR(20), `changed_by_user_id` INT UNSIGNED, `reason` VARCHAR(255), `changed_at` DATETIME                                                                                                                                                                                                                                                                                                                                                                                                                                  | `history_id`              |
| 22  | `invoices`                | 12     | `invoice_id` INT UNSIGNED, `invoice_date` DATETIME, `channel` ENUM('counter', 'online'), `employee_id` INT UNSIGNED, `customer_id` INT UNSIGNED, `shift_id` INT UNSIGNED, `order_id` INT UNSIGNED, `subtotal_amount` BIGINT UNSIGNED, `discount_amount` BIGINT UNSIGNED, `shipping_fee` BIGINT UNSIGNED, `total_amount` BIGINT UNSIGNED, `status` ENUM('completed', 'cancelled')                                                                                                                                                                                                                                            | `invoice_id`              |
| 23  | `invoice_details`         | 11     | `invoice_detail_id` INT UNSIGNED, `invoice_id` INT UNSIGNED, `product_id` INT UNSIGNED, `unit_id` INT UNSIGNED, `quantity` INT UNSIGNED, `returned_quantity` INT UNSIGNED, `unit_price` BIGINT UNSIGNED, `discount_amount` BIGINT UNSIGNED, `promotion_id` INT UNSIGNED, `is_active` BOOLEAN, `active_unit_id` INT UNSIGNED                                                                                                                                                                                                                                                                                                 | `invoice_detail_id`       |
| 24  | `payments`                | 5      | `payment_id` INT UNSIGNED, `invoice_id` INT UNSIGNED, `method` ENUM('cash', 'card', 'bank_transfer', 'cod'), `amount` BIGINT UNSIGNED, `paid_at` DATETIME                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `payment_id`              |
| 25  | `returns`                 | 9      | `return_id` INT UNSIGNED, `invoice_detail_id` INT UNSIGNED, `quantity` INT UNSIGNED, `return_date` DATETIME, `completed_at` DATETIME, `reason` VARCHAR(255), `refund_amount` BIGINT UNSIGNED, `status` ENUM('pending', 'approved', 'rejected', 'completed'), `employee_id` INT UNSIGNED                                                                                                                                                                                                                                                                                                                                     | `return_id`               |
| 26  | `warranties`              | 7      | `warranty_id` INT UNSIGNED, `unit_id` INT UNSIGNED, `invoice_detail_id` INT UNSIGNED, `start_date` DATE, `end_date` DATE, `is_void` BOOLEAN, `active_unit_id` INT UNSIGNED                                                                                                                                                                                                                                                                                                                                                                                                                                                  | `warranty_id`             |
| 27  | `warranty_claims`         | 8      | `claim_id` INT UNSIGNED, `warranty_id` INT UNSIGNED, `received_at` DATETIME, `issue` VARCHAR(255), `status` ENUM('received', 'repairing', 'repaired', 'replaced', 'returned', 'rejected'), `replacement_unit_id` INT UNSIGNED, `handled_by_employee_id` INT UNSIGNED, `resolved_at` DATETIME                                                                                                                                                                                                                                                                                                                                | `claim_id`                |
| 28  | `warranty_claim_history`  | 7      | `history_id` INT UNSIGNED, `claim_id` INT UNSIGNED, `from_status` VARCHAR(20), `to_status` VARCHAR(20), `changed_by_user_id` INT UNSIGNED, `reason` VARCHAR(255), `changed_at` DATETIME                                                                                                                                                                                                                                                                                                                                                                                                                                     | `history_id`              |
| 29  | `stock_movements`         | 10     | `movement_id` INT UNSIGNED, `product_id` INT UNSIGNED, `movement_type` ENUM('import', 'sale', 'return', 'adjustment'), `quantity` INT, `import_detail_id` INT UNSIGNED, `invoice_detail_id` INT UNSIGNED, `return_id` INT UNSIGNED, `employee_id` INT UNSIGNED, `reason` VARCHAR(255), `created_at` DATETIME                                                                                                                                                                                                                                                                                                                | `movement_id`             |

**Quan hệ trọng tâm:** `users.role_id → roles.role_id`; `customers.user_id → users.user_id` (nullable, unique, cặp `member_since` theo CHECK); `invoices` nối `invoice_details`, `invoice_details.product_id → products`, `returns.invoice_detail_id → invoice_details`, `products.category_id → categories`, `invoice_details.unit_id → product_units`, `product_units.import_detail_id → import_details` (FK ghép phù hợp), `invoices.customer_id → customers`. Mọi ràng buộc chéo còn lại phải thực hiện đúng DDL ở phụ lục, không thay từ trí nhớ.

### 3.8. Dữ liệu mẫu và kết quả kiểm chứng dùng làm oracle

- Seed minh họa có **29 câu INSERT** và **126 hàng demo** trong 29 bảng (các hàng liên hệ được giả danh trong phụ lục, khóa/giá trị nghiệp vụ giữ nguyên).
- `users`: 7 (hash Argon2id), `customers`: 3 (2 thành viên, 1 vãng lai), `products`: 6, `invoices`: 4 (bao gồm hóa đơn hủy), `invoice_details`: 7, `returns`: 3 (hoàn tất tháng 10, hoàn tất tháng 11, pending tháng 11).
- Báo cáo **01–31/10/2026**: 4 sản phẩm có doanh thu, tổng ròng theo mã `1: 63.000.000đ`, `2: 28.000.000đ`, `3: 13.500.000đ`, `5: 2.500.000đ` (theo test tích hợp Python).
- Báo cáo **01–30/11/2026**: sản phẩm `5` có doanh thu ròng `-500.000đ`, bán `0`, trả `1`; giao dịch hoàn trả mã `RET-2`, `return_id=2`, tiền hoàn `500.000đ`. Hoàn trả pending không tham gia báo cáo.
- Truy vấn khoảng 2020-01-01..2020-01-31 trả rỗng. ID sản phẩm chưa có trong DB nhưng hợp lệ miền INT UNSIGNED trả rỗng, không tự coi là HTTP 404.
- SQL test có **73 nhãn `T01–T10`** theo câu `AS test_id`; các mục `T07/T08` ghi rõ oracle của dữ liệu nguồn, **không đủ** chứng minh CALL Stored Procedure PASS. Stored Procedure phải được kiểm thử riêng qua `test_revenue.py` và so sánh giá trị trả về.

### 3.9. Thứ tự thiết lập database một cách an toàn

1. Tạo MySQL dành riêng cho demo và credentials cục bộ; dùng biến thể `database/init.sql` trong Phụ lục A **chỉ với DB mới** sau khi điền mật khẩu riêng. Nếu muốn không xóa DB, tự tạo DB trống bằng tài khoản quản trị được phép; không chạy lệnh `DROP` bừa bãi.
2. Thực thi lần lượt `schema.sql` → `procedures.sql` → `seed.sql`; kiểm tra số bảng 29, hai procedure, khóa và hàng seed. `test.sql` chỉ dùng trên bản dữ liệu seed hoàn chỉnh.
3. Khi tái tạo `qlst_test`, tạo DB **riêng** với cùng DDL và procedure/seed; thay chính xác `USE qlst;` ở phần đầu bằng `USE qlst_test;` trong bản sao dùng cho kiểm thử. Tuyệt đối không chạy test ghi vào `qlst`.
4. Không viết lại schema theo các bảng tối thiểu; phải giữ được đầy đủ DDL trong Phụ lục A, vì test kiểm tra các constraint ngoài hai module.

### 3.10. Biên giới kiểm thử và nguồn gốc PASS

Bài gốc đã được người thực hiện xác nhận NAV 8/8, BTN 5/5, LAYOUT 3/3, TABLE 2/2 PASS và module nghiệp vụ đã nghiệm thu. Bản tái tạo **phải kiểm thử lại**, không được kế thừa các trạng thái PASS như thể đã chạy. `src/tests/test_registration.py` có 8 testcase tích hợp ghi/rollback vào **duy nhất** `qlst_test`, cleanup theo danh tính gắn tag. `src/tests/test_revenue.py` có 3 model tests + 4 DAO unit tests + 9 Service unit tests + 6 MySQL integration tests (sáu test DB chỉ chạy khi đặt `RUN_REVENUE_DB_TESTS=1`); kiểm thử unit không cần DB.

## Phần 4 — Bộ prompt tái cấu trúc có thể sao chép và gửi AI Agent mới

**Quy tắc vận hành:** các lời nhắc sau là **PROMPT TÁI CẤU TRÚC**. Mỗi prompt giả định Agent đã nhận toàn bộ Markdown này trong cùng phiên làm việc, kể cả phụ lục nguồn. Khi muốn dựng nhanh nhất, Agent có thể tạo các file từ khối nội dung **nội tại** Phụ lục A–C, chỉ áp dụng thay đổi bí mật/tên giả đã được chú giải; không cần và không được truy cập repository gốc. Sau mỗi prompt, phải nêu file đã tạo và kiểm chứng, không mở rộng phạm vi. Không chạy lệnh phá hủy DB trừ khi được người vận hành cho phép trên DB mới.

### PROMPT-001 — Xác định phạm vi và quy tắc tái tạo

**Loại:** Prompt tái cấu trúc. **Lệnh gửi AI Agent:**

> **Vai trò:** Bạn là Kiến trúc sư hệ thống trong một phiên tái tạo độc lập.

> **Bối cảnh và đầu vào:** Toàn bộ tài liệu Markdown hiện tại (Phần 1–7, Phụ lục A–D) đã được cung cấp trong cuộc trò chuyện này; không truy cập GitHub, repository cũ hay lịch sử hội thoại cũ. Sử dụng sản phẩm từ các prompt trước nếu đã được tạo.

> **File hoặc sản phẩm đầu ra:** `Đặc tả phạm vi / checklist kiến trúc (không tạo source)`.

> **Nhiệm vụ, quy tắc nghiệp vụ và giới hạn:** Bạn là kiến trúc sư dự án Flask MVC học phần phân tích thiết kế. Hãy đọc toàn bộ tài liệu Markdown này, giữ nguyên phạm vi hai module và 29 bảng nền. Lập contract triển khai: Module 1 đăng ký mới, từ chối vãng lai chưa OTP; Module 2 báo cáo/chi tiết chỉ đọc bằng hai procedure. Không thêm login, OTP, CRUD, API JSON ngoài `/health`, JS hoặc frontend framework. Đầu vào duy nhất là tài liệu này. Đầu ra: bản liệt kê module/route/tầng/file và các ranh giới, không yêu cầu link GitHub.

> **Kết quả mong đợi:** File/sản phẩm đích tồn tại trong dự án dựng mới, đúng cấu trúc và hợp đồng dữ liệu ở phần đặc tả; trình bày những gì đã tạo, chưa tạo, và lý do.

> **Tiêu chí nghiệm thu:** so với Phần 3, không thiếu hoặc thêm endpoint. Nếu cần thao tác ghi DB hoặc xóa dữ liệu, yêu cầu người vận hành cho phép trên môi trường test mới trước; không ghi nhận PASS khi chưa chạy.

### PROMPT-002 — Khởi tạo cây thư mục đúng baseline

**Loại:** Prompt tái cấu trúc. **Lệnh gửi AI Agent:**

> **Vai trò:** Bạn là Kiến trúc sư hệ thống trong một phiên tái tạo độc lập.

> **Bối cảnh và đầu vào:** Toàn bộ tài liệu Markdown hiện tại (Phần 1–7, Phụ lục A–D) đã được cung cấp trong cuộc trò chuyện này; không truy cập GitHub, repository cũ hay lịch sử hội thoại cũ. Sử dụng sản phẩm từ các prompt trước nếu đã được tạo.

> **File hoặc sản phẩm đầu ra:** `Cây qlst-project, thư mục và các file __init__.py`.

> **Nhiệm vụ, quy tắc nghiệp vụ và giới hạn:** Hãy tạo `qlst-project` theo DIRECTORY_TREE Phần 3.1 và các file trong Phụ lục A–C. Giữ nguyên `src/controller`, `src/model`, `src/dao`, `src/tests`, `database`, `view/templates`, `view/static/css`, `view/static/js`, `docs/diagrams/01...08`, `docs/report`; tạo **init**.py cần thiết. Giữ các tài liệu rỗng đúng snapshot nếu phục dựng baseline. Không tự viết UML hay file mới ngoài phạm vi.

> **Kết quả mong đợi:** File/sản phẩm đích tồn tại trong dự án dựng mới, đúng cấu trúc và hợp đồng dữ liệu ở phần đặc tả; trình bày những gì đã tạo, chưa tạo, và lý do.

> **Tiêu chí nghiệm thu:** đường dẫn chính xác, không file thừa, import src.\* hoạt động. Nếu cần thao tác ghi DB hoặc xóa dữ liệu, yêu cầu người vận hành cho phép trên môi trường test mới trước; không ghi nhận PASS khi chưa chạy.

### PROMPT-003 — Thiết lập Python 3.14.8 và requirements

**Loại:** Prompt tái cấu trúc. **Lệnh gửi AI Agent:**

> **Vai trò:** Bạn là Lập trình viên Python/Flask MVC trong một phiên tái tạo độc lập.

> **Bối cảnh và đầu vào:** Toàn bộ tài liệu Markdown hiện tại (Phần 1–7, Phụ lục A–D) đã được cung cấp trong cuộc trò chuyện này; không truy cập GitHub, repository cũ hay lịch sử hội thoại cũ. Sử dụng sản phẩm từ các prompt trước nếu đã được tạo.

> **File hoặc sản phẩm đầu ra:** `requirements.txt và môi trường .venv`.

> **Nhiệm vụ, quy tắc nghiệp vụ và giới hạn:** Bạn là kỹ sư môi trường. Tạo `.venv` bằng Python 3.14.8 trên macOS, tạo `requirements.txt` đúng bốn phiên bản đã nêu trong Phần 3.2/Phụ lục C và cài dependencies. Không cài gói tùy tiện. Đầu ra: lệnh setup/check package version và cách activate trên Mac.

> **Kết quả mong đợi:** File/sản phẩm đích tồn tại trong dự án dựng mới, đúng cấu trúc và hợp đồng dữ liệu ở phần đặc tả; trình bày những gì đã tạo, chưa tạo, và lý do.

> **Tiêu chí nghiệm thu:** import Flask, pymysql, argon2, dotenv, và môi trường ảo hoạt động. Nếu cần thao tác ghi DB hoặc xóa dữ liệu, yêu cầu người vận hành cho phép trên môi trường test mới trước; không ghi nhận PASS khi chưa chạy.

### PROMPT-004 — Cấu hình Flask và MySQL an toàn

**Loại:** Prompt tái cấu trúc. **Lệnh gửi AI Agent:**

> **Vai trò:** Bạn là Lập trình viên Python/Flask MVC trong một phiên tái tạo độc lập.

> **Bối cảnh và đầu vào:** Toàn bộ tài liệu Markdown hiện tại (Phần 1–7, Phụ lục A–D) đã được cung cấp trong cuộc trò chuyện này; không truy cập GitHub, repository cũ hay lịch sử hội thoại cũ. Sử dụng sản phẩm từ các prompt trước nếu đã được tạo.

> **File hoặc sản phẩm đầu ra:** `src/config.py, src/dao/db.py, .env.example`.

> **Nhiệm vụ, quy tắc nghiệp vụ và giới hạn:** Tạo `src/config.py`, `src/dao/db.py` đúng contract Phần 3.2 và các bản mã nội tại tại Phụ lục C. Đặt `PROJECT_ROOT`; dotenv không override biến môi trường có sẵn. Cài đặt `DatabaseSettings.from_env` với giới hạn port/timeout, password/user không rỗng, `get_flask_secret_key` từ chối key yếu placeholder. Database.open DictCursor, charset utf8mb4, autocommit False; Database.connection chỉ đóng; Database.transaction commit/rollback chính xác. Tạo `.env.example` an toàn; không tạo hay in `.env` thật.

> **Kết quả mong đợi:** File/sản phẩm đích tồn tại trong dự án dựng mới, đúng cấu trúc và hợp đồng dữ liệu ở phần đặc tả; trình bày những gì đã tạo, chưa tạo, và lý do.

> **Tiêu chí nghiệm thu:** parse AST, unit-check lỗi cấu hình, không hardcode password. Nếu cần thao tác ghi DB hoặc xóa dữ liệu, yêu cầu người vận hành cho phép trên môi trường test mới trước; không ghi nhận PASS khi chưa chạy.

### PROMPT-005 — Tạo Flask chính và đăng ký các Blueprint

**Loại:** Prompt tái cấu trúc. **Lệnh gửi AI Agent:**

> **Vai trò:** Bạn là Lập trình viên Python/Flask MVC trong một phiên tái tạo độc lập.

> **Bối cảnh và đầu vào:** Toàn bộ tài liệu Markdown hiện tại (Phần 1–7, Phụ lục A–D) đã được cung cấp trong cuộc trò chuyện này; không truy cập GitHub, repository cũ hay lịch sử hội thoại cũ. Sử dụng sản phẩm từ các prompt trước nếu đã được tạo.

> **File hoặc sản phẩm đầu ra:** `app.py`.

> **Nhiệm vụ, quy tắc nghiệp vụ và giới hạn:** Tạo `app.py`: Flask template_folder ở `view/templates`, static_folder ở `view/static`, ChoiceLoader ưu tiên templates rồi view root; SECRET_KEY từ config; đăng ký registration_bp và revenue_bp; định nghĩa GET `/` render index, `/reports` render reports, `/health` trả JSON Flask không kiểm tra MySQL; `python -B app.py` bind 127.0.0.1:5000, debug=False. **Chỉ chạy kiểm tra url_map sau khi các Controller ở PROMPT-016 và PROMPT-022 đã được tạo**, vì app import Blueprint. Đầu vào là Phần 3.3 và bản app.py phụ lục. Kết quả: url_map đúng 6 route người dùng và endpoint; không dùng factory app giả để thay app chính.

> **Kết quả mong đợi:** File/sản phẩm đích tồn tại trong dự án dựng mới, đúng cấu trúc và hợp đồng dữ liệu ở phần đặc tả; trình bày những gì đã tạo, chưa tạo, và lý do.

> **Tiêu chí nghiệm thu:** Đối chiếu source nội tại và những điều kiện nghiệm thu tương ứng ở Phần 3/Phần 5; không tự báo PASS nếu chưa kiểm thử. Nếu cần thao tác ghi DB hoặc xóa dữ liệu, yêu cầu người vận hành cho phép trên môi trường test mới trước; không ghi nhận PASS khi chưa chạy.

### PROMPT-006 — Khởi tạo DB mới với bảo vệ an toàn

**Loại:** Prompt tái cấu trúc. **Lệnh gửi AI Agent:**

> **Vai trò:** Bạn là Kỹ sư database và kiểm thử SQL trong một phiên tái tạo độc lập.

> **Bối cảnh và đầu vào:** Toàn bộ tài liệu Markdown hiện tại (Phần 1–7, Phụ lục A–D) đã được cung cấp trong cuộc trò chuyện này; không truy cập GitHub, repository cũ hay lịch sử hội thoại cũ. Sử dụng sản phẩm từ các prompt trước nếu đã được tạo.

> **File hoặc sản phẩm đầu ra:** `database/init.sql (chỉ môi trường demo mới)`.

> **Nhiệm vụ, quy tắc nghiệp vụ và giới hạn:** Bạn là DBA. Từ Phụ lục A sử dụng `init.sql` demo an toàn, tạo DB `qlst` trong MySQL riêng mới; hỏi người vận hành xác nhận trước mọi DROP, không áp dụng DROP lên DB dữ liệu thật. Sinh mật khẩu mạnh cục bộ, cấu hình tài khoản ứng dụng `qlst_app` và `.env` nhưng không in hoặc commit mật khẩu. Giữ utf8mb4, InnoDB; thiết lập database `qlst_test` độc lập phục vụ test.

> **Kết quả mong đợi:** File/sản phẩm đích tồn tại trong dự án dựng mới, đúng cấu trúc và hợp đồng dữ liệu ở phần đặc tả; trình bày những gì đã tạo, chưa tạo, và lý do.

> **Tiêu chí nghiệm thu:** kết nối DB đúng tên bằng SELECT DATABASE(), không dùng root cho ứng dụng. Nếu cần thao tác ghi DB hoặc xóa dữ liệu, yêu cầu người vận hành cho phép trên môi trường test mới trước; không ghi nhận PASS khi chưa chạy.

### PROMPT-007 — Tạo schema đầy đủ 29 bảng

**Loại:** Prompt tái cấu trúc. **Lệnh gửi AI Agent:**

> **Vai trò:** Bạn là Kỹ sư database và kiểm thử SQL trong một phiên tái tạo độc lập.

> **Bối cảnh và đầu vào:** Toàn bộ tài liệu Markdown hiện tại (Phần 1–7, Phụ lục A–D) đã được cung cấp trong cuộc trò chuyện này; không truy cập GitHub, repository cũ hay lịch sử hội thoại cũ. Sử dụng sản phẩm từ các prompt trước nếu đã được tạo.

> **File hoặc sản phẩm đầu ra:** `database/schema.sql`.

> **Nhiệm vụ, quy tắc nghiệp vụ và giới hạn:** Đọc DDL toàn bộ `schema.sql` nhúng trong Phụ lục A và tạo đúng 29 bảng theo thứ tự, cột/types, PK/FK/UNIQUE/CHECK, generated columns/index/ENUM và constraint names, không suy đoán hoặc giản lược bảng. Đặc biệt users/roles/customers; invoices/invoice_details/returns/products/categories/product_units; các bảng nền kho/đơn hàng. Ghi schema.sql trong database/ với văn bản nội tại.

> **Kết quả mong đợi:** File/sản phẩm đích tồn tại trong dự án dựng mới, đúng cấu trúc và hợp đồng dữ liệu ở phần đặc tả; trình bày những gì đã tạo, chưa tạo, và lý do.

> **Tiêu chí nghiệm thu:** metadata 29 BASE TABLE; CHECK customers membership + member_date, uq_users_username và uq_customers_phone, FK đầy đủ; SQL thực thi trong DB thử nghiệm mới. Nếu cần thao tác ghi DB hoặc xóa dữ liệu, yêu cầu người vận hành cho phép trên môi trường test mới trước; không ghi nhận PASS khi chưa chạy.

### PROMPT-008 — Tạo seed 126 hàng với hợp đồng số liệu

**Loại:** Prompt tái cấu trúc. **Lệnh gửi AI Agent:**

> **Vai trò:** Bạn là Kỹ sư database và kiểm thử SQL trong một phiên tái tạo độc lập.

> **Bối cảnh và đầu vào:** Toàn bộ tài liệu Markdown hiện tại (Phần 1–7, Phụ lục A–D) đã được cung cấp trong cuộc trò chuyện này; không truy cập GitHub, repository cũ hay lịch sử hội thoại cũ. Sử dụng sản phẩm từ các prompt trước nếu đã được tạo.

> **File hoặc sản phẩm đầu ra:** `database/seed.sql`.

> **Nhiệm vụ, quy tắc nghiệp vụ và giới hạn:** Dùng Phụ lục A `seed.sql` (dữ liệu liên hệ đã giả danh) tạo đúng các records seed và khóa tham chiếu, gồm 7 users hash Argon2id, 3 customers, 6 products, 4 invoices, 7 invoice_details, 3 returns. Không phục hồi dữ liệu cá nhân gốc, không dùng mật khẩu demo thật. Các ID, số tiền, trạng thái, ngày và công thức test phải giữ nguyên. Seed chỉ chạy lên DB mới đúng schema.

> **Kết quả mong đợi:** File/sản phẩm đích tồn tại trong dự án dựng mới, đúng cấu trúc và hợp đồng dữ liệu ở phần đặc tả; trình bày những gì đã tạo, chưa tạo, và lý do.

> **Tiêu chí nghiệm thu:** 29 INSERT statements và 126 rows, khách vãng lai customer_id=3, hoàn trả tháng 10/11, 1 pending. Nếu cần thao tác ghi DB hoặc xóa dữ liệu, yêu cầu người vận hành cho phép trên môi trường test mới trước; không ghi nhận PASS khi chưa chạy.

### PROMPT-009 — Cài đúng hai Stored Procedure báo cáo

**Loại:** Prompt tái cấu trúc. **Lệnh gửi AI Agent:**

> **Vai trò:** Bạn là Kỹ sư database và kiểm thử SQL trong một phiên tái tạo độc lập.

> **Bối cảnh và đầu vào:** Toàn bộ tài liệu Markdown hiện tại (Phần 1–7, Phụ lục A–D) đã được cung cấp trong cuộc trò chuyện này; không truy cập GitHub, repository cũ hay lịch sử hội thoại cũ. Sử dụng sản phẩm từ các prompt trước nếu đã được tạo.

> **File hoặc sản phẩm đầu ra:** `database/procedures.sql`.

> **Nhiệm vụ, quy tắc nghiệp vụ và giới hạn:** Từ Phụ lục A tạo nguyên logic hai `CREATE PROCEDURE` sp_get_product_revenue_stats(DATE,DATE) và sp_get_product_transactions(INT UNSIGNED,DATE,DATE); đặt p_start_date<=p_end_date, check non-NULL với SQLSTATE 45000; bán từ completed invoice + active details, trả từ completed returns theo completed_at, khoảng ngày inclusive qua DATE_ADD(end,1 DAY), UNION ALL không nhân dòng, net revenue có dấu. Không dùng returned_quantity để trừ lại kỳ bán. Output lần lượt 13 và 23 trường, đúng alias/thứ tự; SQL ở phụ lục là nguồn định nghĩa.

> **Kết quả mong đợi:** File/sản phẩm đích tồn tại trong dự án dựng mới, đúng cấu trúc và hợp đồng dữ liệu ở phần đặc tả; trình bày những gì đã tạo, chưa tạo, và lý do.

> **Tiêu chí nghiệm thu:** CALL trả số liệu tháng 10 và âm tháng 11 như Phần 3.8; không tự rút gọn công thức. Nếu cần thao tác ghi DB hoặc xóa dữ liệu, yêu cầu người vận hành cho phép trên môi trường test mới trước; không ghi nhận PASS khi chưa chạy.

### PROMPT-010 — Đối soát seed, schema và SQL test

**Loại:** Prompt tái cấu trúc. **Lệnh gửi AI Agent:**

> **Vai trò:** Bạn là Kỹ sư database và kiểm thử SQL trong một phiên tái tạo độc lập.

> **Bối cảnh và đầu vào:** Toàn bộ tài liệu Markdown hiện tại (Phần 1–7, Phụ lục A–D) đã được cung cấp trong cuộc trò chuyện này; không truy cập GitHub, repository cũ hay lịch sử hội thoại cũ. Sử dụng sản phẩm từ các prompt trước nếu đã được tạo.

> **File hoặc sản phẩm đầu ra:** `database/test.sql; biên bản chạy SQL khi được phép`.

> **Nhiệm vụ, quy tắc nghiệp vụ và giới hạn:** Tạo `database/test.sql` từ Phụ lục A, đọc phần cảnh báo đầu file. Chạy trên DB đã được dựng mới, kiểm tra PK/FK/CHECK/UNIQUE, consistency kho, giao dịch, số liệu, các nhóm T01..T10. Phân biệt oracle từ dữ liệu nguồn với việc kiểm tra procedure: riêng T07/T08 không coi PASS là CALL đã PASS. Chuẩn bị kiểm tra procedure qua Python tích hợp. Đầu ra: bảng kết quả thực tế hoặc ghi chưa chạy nếu không có DB, không tự khai PASS.

> **Kết quả mong đợi:** File/sản phẩm đích tồn tại trong dự án dựng mới, đúng cấu trúc và hợp đồng dữ liệu ở phần đặc tả; trình bày những gì đã tạo, chưa tạo, và lý do.

> **Tiêu chí nghiệm thu:** Đối chiếu source nội tại và những điều kiện nghiệm thu tương ứng ở Phần 3/Phần 5; không tự báo PASS nếu chưa kiểm thử. Nếu cần thao tác ghi DB hoặc xóa dữ liệu, yêu cầu người vận hành cho phép trên môi trường test mới trước; không ghi nhận PASS khi chưa chạy.

### PROMPT-011 — Định nghĩa User và Customer models

**Loại:** Prompt tái cấu trúc. **Lệnh gửi AI Agent:**

> **Vai trò:** Bạn là Lập trình viên Python/Flask MVC trong một phiên tái tạo độc lập.

> **Bối cảnh và đầu vào:** Toàn bộ tài liệu Markdown hiện tại (Phần 1–7, Phụ lục A–D) đã được cung cấp trong cuộc trò chuyện này; không truy cập GitHub, repository cũ hay lịch sử hội thoại cũ. Sử dụng sản phẩm từ các prompt trước nếu đã được tạo.

> **File hoặc sản phẩm đầu ra:** `src/model/user.py, src/model/customer.py`.

> **Nhiệm vụ, quy tắc nghiệp vụ và giới hạn:** Tạo `src/model/user.py` và `src/model/customer.py` theo Phần 3.4 và code Phụ lục C. Dùng @dataclass(frozen=True, slots=True), User.password_hash repr=False, Customer.is_member chỉ true khi user_id và member_since cùng khác None. Không thêm kiểm tra OTP hay login. Kiểm tra model construct, field names/types, Customer guest/member trạng thái đúng.

> **Kết quả mong đợi:** File/sản phẩm đích tồn tại trong dự án dựng mới, đúng cấu trúc và hợp đồng dữ liệu ở phần đặc tả; trình bày những gì đã tạo, chưa tạo, và lý do.

> **Tiêu chí nghiệm thu:** Đối chiếu source nội tại và những điều kiện nghiệm thu tương ứng ở Phần 3/Phần 5; không tự báo PASS nếu chưa kiểm thử. Nếu cần thao tác ghi DB hoặc xóa dữ liệu, yêu cầu người vận hành cho phép trên môi trường test mới trước; không ghi nhận PASS khi chưa chạy.

### PROMPT-012 — Xây dựng PasswordService Argon2id

**Loại:** Prompt tái cấu trúc. **Lệnh gửi AI Agent:**

> **Vai trò:** Bạn là Lập trình viên Python/Flask MVC trong một phiên tái tạo độc lập.

> **Bối cảnh và đầu vào:** Toàn bộ tài liệu Markdown hiện tại (Phần 1–7, Phụ lục A–D) đã được cung cấp trong cuộc trò chuyện này; không truy cập GitHub, repository cũ hay lịch sử hội thoại cũ. Sử dụng sản phẩm từ các prompt trước nếu đã được tạo.

> **File hoặc sản phẩm đầu ra:** `src/model/password_service.py`.

> **Nhiệm vụ, quy tắc nghiệp vụ và giới hạn:** Tạo `src/model/password_service.py` với PasswordHasher(type=Type.ID), hash_password, verify_password bắt mismatch/invalid hash trả false, needs_rehash. Không ghi plaintext ra log, DAO hay response. Chỉ dùng thư viện argon2-cffi 25.1.0.

> **Kết quả mong đợi:** File/sản phẩm đích tồn tại trong dự án dựng mới, đúng cấu trúc và hợp đồng dữ liệu ở phần đặc tả; trình bày những gì đã tạo, chưa tạo, và lý do.

> **Tiêu chí nghiệm thu:** cùng mật khẩu hai lần có salt khác nhau, verify đúng/sai, tiền tố $argon2id$, rehash API. Nếu cần thao tác ghi DB hoặc xóa dữ liệu, yêu cầu người vận hành cho phép trên môi trường test mới trước; không ghi nhận PASS khi chưa chạy.

### PROMPT-013 — Xây dựng DAO Module 1

**Loại:** Prompt tái cấu trúc. **Lệnh gửi AI Agent:**

> **Vai trò:** Bạn là Lập trình viên Python/Flask MVC trong một phiên tái tạo độc lập.

> **Bối cảnh và đầu vào:** Toàn bộ tài liệu Markdown hiện tại (Phần 1–7, Phụ lục A–D) đã được cung cấp trong cuộc trò chuyện này; không truy cập GitHub, repository cũ hay lịch sử hội thoại cũ. Sử dụng sản phẩm từ các prompt trước nếu đã được tạo.

> **File hoặc sản phẩm đầu ra:** `src/dao/user_dao.py, src/dao/customer_dao.py`.

> **Nhiệm vụ, quy tắc nghiệp vụ và giới hạn:** Tạo `src/dao/user_dao.py`, `src/dao/customer_dao.py` và dùng connection do Database cấp; không DAO nào commit, rollback, tự mở connection. UserDAO: find_by_username, get_customer_role_id theo roles.code=customer, create từ password_hash. CustomerDAO: find_by_phone, find_by_phone_for_update (SELECT FOR UPDATE trong transaction), create với loyalty_points=0, link_user chỉ cho hồ sơ còn active chưa có tài khoản, khóa rowcount và không đổi ID/phone/history; vẫn giữ API link_user dù service chưa gọi. SQL parameterized %s.

> **Kết quả mong đợi:** File/sản phẩm đích tồn tại trong dự án dựng mới, đúng cấu trúc và hợp đồng dữ liệu ở phần đặc tả; trình bày những gì đã tạo, chưa tạo, và lý do.

> **Tiêu chí nghiệm thu:** giữ đúng field names và Unique, không SQL injection, đúng rollback khi lỗi. Nếu cần thao tác ghi DB hoặc xóa dữ liệu, yêu cầu người vận hành cho phép trên môi trường test mới trước; không ghi nhận PASS khi chưa chạy.

### PROMPT-014 — Xây dựng RegistrationService validation

**Loại:** Prompt tái cấu trúc. **Lệnh gửi AI Agent:**

> **Vai trò:** Bạn là Lập trình viên Python/Flask MVC trong một phiên tái tạo độc lập.

> **Bối cảnh và đầu vào:** Toàn bộ tài liệu Markdown hiện tại (Phần 1–7, Phụ lục A–D) đã được cung cấp trong cuộc trò chuyện này; không truy cập GitHub, repository cũ hay lịch sử hội thoại cũ. Sử dụng sản phẩm từ các prompt trước nếu đã được tạo.

> **File hoặc sản phẩm đầu ra:** `src/model/registration_service.py`.

> **Nhiệm vụ, quy tắc nghiệp vụ và giới hạn:** Tạo `src/model/registration_service.py` bao gồm các error classes và RegistrationResult như Phần 3.4. Cài normalize_phone và \_required_text/\_optional_text/\_validate_input chính xác: tên 100, username 50 không whitespace nội bộ, password 8–256, email 100 regex, address 255, phone 10 số VN bắt đầu 0/+84/84. Không tự lowercase username, không yêu cầu OTP đã hoàn thành.

> **Kết quả mong đợi:** File/sản phẩm đích tồn tại trong dự án dựng mới, đúng cấu trúc và hợp đồng dữ liệu ở phần đặc tả; trình bày những gì đã tạo, chưa tạo, và lý do.

> **Tiêu chí nghiệm thu:** invalid input bị từ chối trước mở connection, output chuẩn hóa đúng, không lộ password. Nếu cần thao tác ghi DB hoặc xóa dữ liệu, yêu cầu người vận hành cho phép trên môi trường test mới trước; không ghi nhận PASS khi chưa chạy.

### PROMPT-015 — Xây dựng RegistrationService transaction

**Loại:** Prompt tái cấu trúc. **Lệnh gửi AI Agent:**

> **Vai trò:** Bạn là Lập trình viên Python/Flask MVC trong một phiên tái tạo độc lập.

> **Bối cảnh và đầu vào:** Toàn bộ tài liệu Markdown hiện tại (Phần 1–7, Phụ lục A–D) đã được cung cấp trong cuộc trò chuyện này; không truy cập GitHub, repository cũ hay lịch sử hội thoại cũ. Sử dụng sản phẩm từ các prompt trước nếu đã được tạo.

> **File hoặc sản phẩm đầu ra:** `src/model/registration_service.py`.

> **Nhiệm vụ, quy tắc nghiệp vụ và giới hạn:** Hoàn thiện `RegistrationService.register` dùng một `Database.transaction()` để find customer by normalized phone -> member conflict / guest OTP required; check username; get role by code; hash Argon2id; tạo users trước rồi customers cùng timestamp; commit -> RegistrationResult. Phân loại IntegrityError 1062 theo UNIQUE keys, OperationalError 1205/1213 thành retryable, storage errors thành generic. Đừng gọi CustomerDAO.link_user vì OTP chưa triển khai.

> **Kết quả mong đợi:** File/sản phẩm đích tồn tại trong dự án dựng mới, đúng cấu trúc và hợp đồng dữ liệu ở phần đặc tả; trình bày những gì đã tạo, chưa tạo, và lý do.

> **Tiêu chí nghiệm thu:** không ghi nửa chừng, rollback hoàn toàn ở hai điểm thất bại, race condition được UNIQUE chắn, guest data không bị động. Nếu cần thao tác ghi DB hoặc xóa dữ liệu, yêu cầu người vận hành cho phép trên môi trường test mới trước; không ghi nhận PASS khi chưa chạy.

### PROMPT-016 — Xây dựng Controller đăng ký và CSRF

**Loại:** Prompt tái cấu trúc. **Lệnh gửi AI Agent:**

> **Vai trò:** Bạn là Lập trình viên Python/Flask MVC trong một phiên tái tạo độc lập.

> **Bối cảnh và đầu vào:** Toàn bộ tài liệu Markdown hiện tại (Phần 1–7, Phụ lục A–D) đã được cung cấp trong cuộc trò chuyện này; không truy cập GitHub, repository cũ hay lịch sử hội thoại cũ. Sử dụng sản phẩm từ các prompt trước nếu đã được tạo.

> **File hoặc sản phẩm đầu ra:** `src/controller/registration_controller.py`.

> **Nhiệm vụ, quy tắc nghiệp vụ và giới hạn:** Tạo `src/controller/registration_controller.py` cho Blueprint registration, route GET/POST /register; session CSRF sinh bằng secrets.token_urlsafe(32), constant-time compare_digest, hidden csrf_token; dùng một tên internal session key nhất quán (không cần chép giá trị bất kỳ cũ), Flask SECRET_KEY lấy từ env; POST sai token 400 + form mới; validation 400, conflict 409, DB/retry 503; thành công flash và redirect HTTP 303, xóa token; giữ non-sensitive input, không giữ password. Cảnh báo: đổi internal CSRF session key giữa hai lần deploy có thể vô hiệu hóa token form của session cũ.

> **Kết quả mong đợi:** File/sản phẩm đích tồn tại trong dự án dựng mới, đúng cấu trúc và hợp đồng dữ liệu ở phần đặc tả; trình bày những gì đã tạo, chưa tạo, và lý do.

> **Tiêu chí nghiệm thu:** HTTP status và message đúng Phụ lục C, không SQL ở Controller. Nếu cần thao tác ghi DB hoặc xóa dữ liệu, yêu cầu người vận hành cho phép trên môi trường test mới trước; không ghi nhận PASS khi chưa chạy.

### PROMPT-017 — Tạo trang HTML đăng ký thành viên

**Loại:** Prompt tái cấu trúc. **Lệnh gửi AI Agent:**

> **Vai trò:** Bạn là Lập trình viên Python/Flask MVC trong một phiên tái tạo độc lập.

> **Bối cảnh và đầu vào:** Toàn bộ tài liệu Markdown hiện tại (Phần 1–7, Phụ lục A–D) đã được cung cấp trong cuộc trò chuyện này; không truy cập GitHub, repository cũ hay lịch sử hội thoại cũ. Sử dụng sản phẩm từ các prompt trước nếu đã được tạo.

> **File hoặc sản phẩm đầu ra:** `view/templates/register.html`.

> **Nhiệm vụ, quy tắc nghiệp vụ và giới hạn:** Tạo `view/templates/register.html` từ Phần 3.4 và Phụ lục B: HTML vi, labels id/name full_name, username, password, phone, email, address; field csrf_token hidden; method POST, action url_for(registration.register); thông báo flash success và role alert error; giữ input thông thường khi validate lỗi, không hiển thị lại password; maxlength 100/50/100/255 và password minlength=8; không JavaScript/CSS framework.

> **Kết quả mong đợi:** File/sản phẩm đích tồn tại trong dự án dựng mới, đúng cấu trúc và hợp đồng dữ liệu ở phần đặc tả; trình bày những gì đã tạo, chưa tạo, và lý do.

> **Tiêu chí nghiệm thu:** Jinja2 parse được, GET form có token, POST submit đúng endpoint. Nếu cần thao tác ghi DB hoặc xóa dữ liệu, yêu cầu người vận hành cho phép trên môi trường test mới trước; không ghi nhận PASS khi chưa chạy.

### PROMPT-018 — Kiểm thử Module 1 với DB an toàn

**Loại:** Prompt tái cấu trúc. **Lệnh gửi AI Agent:**

> **Vai trò:** Bạn là Kỹ sư QA trong một phiên tái tạo độc lập.

> **Bối cảnh và đầu vào:** Toàn bộ tài liệu Markdown hiện tại (Phần 1–7, Phụ lục A–D) đã được cung cấp trong cuộc trò chuyện này; không truy cập GitHub, repository cũ hay lịch sử hội thoại cũ. Sử dụng sản phẩm từ các prompt trước nếu đã được tạo.

> **File hoặc sản phẩm đầu ra:** `src/tests/test_registration.py; log test khi được phép`.

> **Nhiệm vụ, quy tắc nghiệp vụ và giới hạn:** Tạo `src/tests/test_registration.py` theo Phụ lục C và 8 testcase: tạo mới + Argon2id + FK + commit; trùng username; guest OTP required và không đổi; member đã tồn tại; rollback khi check customer lỗi; rollback insert user; hai request cùng phone; dữ liệu nhập sai không ghi. Dùng `MYSQL_DATABASE=qlst_test` được đặt rõ, host 127.0.0.1 port 3307, non-root, SELECT DATABASE() trước DML, seed 7 users/3 customers, cleanup theo ID/phone/tag.

> **Kết quả mong đợi:** File/sản phẩm đích tồn tại trong dự án dựng mới, đúng cấu trúc và hợp đồng dữ liệu ở phần đặc tả; trình bày những gì đã tạo, chưa tạo, và lý do.

> **Tiêu chí nghiệm thu:** không DROP/TRUNCATE, DB thử nghiệm giữ đúng count sau test; chỉ báo PASS sau chạy thực. Nếu cần thao tác ghi DB hoặc xóa dữ liệu, yêu cầu người vận hành cho phép trên môi trường test mới trước; không ghi nhận PASS khi chưa chạy.

### PROMPT-019 — Tạo ProductRevenue và ProductTransaction models

**Loại:** Prompt tái cấu trúc. **Lệnh gửi AI Agent:**

> **Vai trò:** Bạn là Lập trình viên Python/Flask MVC trong một phiên tái tạo độc lập.

> **Bối cảnh và đầu vào:** Toàn bộ tài liệu Markdown hiện tại (Phần 1–7, Phụ lục A–D) đã được cung cấp trong cuộc trò chuyện này; không truy cập GitHub, repository cũ hay lịch sử hội thoại cũ. Sử dụng sản phẩm từ các prompt trước nếu đã được tạo.

> **File hoặc sản phẩm đầu ra:** `src/model/revenue.py`.

> **Nhiệm vụ, quy tắc nghiệp vụ và giới hạn:** Tạo `src/model/revenue.py` với hai frozen+slots dataclasses và from_row đúng 13/23 field thứ tự như Phần 3.5/Phụ lục C. Giữ Decimal, kể cả giá trị âm; đổi quantities sang int; giữ nullable return_id, unit_id, serial_number, customer fields thành None; không tính lại doanh thu hay đổi dấu.

> **Kết quả mong đợi:** File/sản phẩm đích tồn tại trong dự án dựng mới, đúng cấu trúc và hợp đồng dữ liệu ở phần đặc tả; trình bày những gì đã tạo, chưa tạo, và lý do.

> **Tiêu chí nghiệm thu:** unit test 13/23 columns, negative Decimal, immutable, nullable field PASS. Nếu cần thao tác ghi DB hoặc xóa dữ liệu, yêu cầu người vận hành cho phép trên môi trường test mới trước; không ghi nhận PASS khi chưa chạy.

### PROMPT-020 — Xây dựng RevenueDAO chỉ đọc

**Loại:** Prompt tái cấu trúc. **Lệnh gửi AI Agent:**

> **Vai trò:** Bạn là Lập trình viên Python/Flask MVC trong một phiên tái tạo độc lập.

> **Bối cảnh và đầu vào:** Toàn bộ tài liệu Markdown hiện tại (Phần 1–7, Phụ lục A–D) đã được cung cấp trong cuộc trò chuyện này; không truy cập GitHub, repository cũ hay lịch sử hội thoại cũ. Sử dụng sản phẩm từ các prompt trước nếu đã được tạo.

> **File hoặc sản phẩm đầu ra:** `src/dao/revenue_dao.py`.

> **Nhiệm vụ, quy tắc nghiệp vụ và giới hạn:** Tạo `src/dao/revenue_dao.py`: constructor nhận connection; \_call_procedure gọi cursor.callproc có parameter tuple, fetchall result chính, drain nextset() kể cả các resultset phụ, rồi trả list mapping; hai phương thức gọi tên procedure cố định và trả danh sách ProductRevenue/Transaction; không commit, không tự SQL hóa công thức.

> **Kết quả mong đợi:** File/sản phẩm đích tồn tại trong dự án dựng mới, đúng cấu trúc và hợp đồng dữ liệu ở phần đặc tả; trình bày những gì đã tạo, chưa tạo, và lý do.

> **Tiêu chí nghiệm thu:** unit mock check đúng procedure names/argument order, nextset và lỗi DB không bị đổi thành [] im lặng. Nếu cần thao tác ghi DB hoặc xóa dữ liệu, yêu cầu người vận hành cho phép trên môi trường test mới trước; không ghi nhận PASS khi chưa chạy.

### PROMPT-021 — Xây dựng RevenueService và validation

**Loại:** Prompt tái cấu trúc. **Lệnh gửi AI Agent:**

> **Vai trò:** Bạn là Lập trình viên Python/Flask MVC trong một phiên tái tạo độc lập.

> **Bối cảnh và đầu vào:** Toàn bộ tài liệu Markdown hiện tại (Phần 1–7, Phụ lục A–D) đã được cung cấp trong cuộc trò chuyện này; không truy cập GitHub, repository cũ hay lịch sử hội thoại cũ. Sử dụng sản phẩm từ các prompt trước nếu đã được tạo.

> **File hoặc sản phẩm đầu ra:** `src/model/revenue_service.py`.

> **Nhiệm vụ, quy tắc nghiệp vụ và giới hạn:** Tạo `src/model/revenue_service.py`: \_validate_dates chỉ nhận type(date) đúng, không nhận datetime/string, start<=end; \_validate_product_id chỉ int nguyên dương 1..4294967295 không bool; get_product_revenue_stats/get_product_transactions gọi RevenueDAO dưới Database.connection(), bọc MySQLError thành RevenueStorageError. Không tính lại doanh thu hoặc ép Decimal sang float.

> **Kết quả mong đợi:** File/sản phẩm đích tồn tại trong dự án dựng mới, đúng cấu trúc và hợp đồng dữ liệu ở phần đặc tả; trình bày những gì đã tạo, chưa tạo, và lý do.

> **Tiêu chí nghiệm thu:** invalid input trước mở DB, empty list hợp lệ, lỗi DB khác empty. Nếu cần thao tác ghi DB hoặc xóa dữ liệu, yêu cầu người vận hành cho phép trên môi trường test mới trước; không ghi nhận PASS khi chưa chạy.

### PROMPT-022 — Xây dựng Controller báo cáo và chi tiết GET

**Loại:** Prompt tái cấu trúc. **Lệnh gửi AI Agent:**

> **Vai trò:** Bạn là Lập trình viên Python/Flask MVC trong một phiên tái tạo độc lập.

> **Bối cảnh và đầu vào:** Toàn bộ tài liệu Markdown hiện tại (Phần 1–7, Phụ lục A–D) đã được cung cấp trong cuộc trò chuyện này; không truy cập GitHub, repository cũ hay lịch sử hội thoại cũ. Sử dụng sản phẩm từ các prompt trước nếu đã được tạo.

> **File hoặc sản phẩm đầu ra:** `src/controller/revenue_controller.py`.

> **Nhiệm vụ, quy tắc nghiệp vụ và giới hạn:** Tạo `src/controller/revenue_controller.py`, Blueprint revenue, GET /revenue và GET /revenue/products/<product_id>/transactions; parse ISO ngày định dạng YYYY-MM-DD, convert product_id int và đẩy validation miền giá trị cho service; nếu hoàn toàn không có params thì render báo cáo không query; một ngày thiếu hoặc sai -> 400, MySQL error -> 503, success -> 200, empty data -> thông báo. Phải chuyển start_date/end_date nguyên bản vào template và không viết SQL trong Controller.

> **Kết quả mong đợi:** File/sản phẩm đích tồn tại trong dự án dựng mới, đúng cấu trúc và hợp đồng dữ liệu ở phần đặc tả; trình bày những gì đã tạo, chưa tạo, và lý do.

> **Tiêu chí nghiệm thu:** routing, status codes, no connection khi mở form. Nếu cần thao tác ghi DB hoặc xóa dữ liệu, yêu cầu người vận hành cho phép trên môi trường test mới trước; không ghi nhận PASS khi chưa chạy.

### PROMPT-023 — Tạo template doanh thu 11 cột

**Loại:** Prompt tái cấu trúc. **Lệnh gửi AI Agent:**

> **Vai trò:** Bạn là Lập trình viên Python/Flask MVC trong một phiên tái tạo độc lập.

> **Bối cảnh và đầu vào:** Toàn bộ tài liệu Markdown hiện tại (Phần 1–7, Phụ lục A–D) đã được cung cấp trong cuộc trò chuyện này; không truy cập GitHub, repository cũ hay lịch sử hội thoại cũ. Sử dụng sản phẩm từ các prompt trước nếu đã được tạo.

> **File hoặc sản phẩm đầu ra:** `view/templates/revenue_report.html`.

> **Nhiệm vụ, quy tắc nghiệp vụ và giới hạn:** Tạo `view/templates/revenue_report.html` theo Phần 3.6 và Phụ lục B: form GET date inputs start_date, end_date required, button Thống kê căn trái; form GET back /reports có style text-align:right. Khi has_searched=false thông báo chọn khoảng ngày; lỗi role alert; có products render table đúng 11 th, caption Doanh thu theo từng sản phẩm, mỗi row đủ dữ liệu và link giao dịch bảo toàn ngày; tfoot th colspan=4 + 6 totals + td trống; tiền format bằng Jinja `{:,.0f}` và replace comma->dot; bảng dùng margin-left/right auto.

> **Kết quả mong đợi:** File/sản phẩm đích tồn tại trong dự án dựng mới, đúng cấu trúc và hợp đồng dữ liệu ở phần đặc tả; trình bày những gì đã tạo, chưa tạo, và lý do.

> **Tiêu chí nghiệm thu:** giữ số/tiền right-align, caption, `sum(attribute=...)`, không width:100%. Nếu cần thao tác ghi DB hoặc xóa dữ liệu, yêu cầu người vận hành cho phép trên môi trường test mới trước; không ghi nhận PASS khi chưa chạy.

### PROMPT-024 — Tạo template chi tiết 12 cột

**Loại:** Prompt tái cấu trúc. **Lệnh gửi AI Agent:**

> **Vai trò:** Bạn là Lập trình viên Python/Flask MVC trong một phiên tái tạo độc lập.

> **Bối cảnh và đầu vào:** Toàn bộ tài liệu Markdown hiện tại (Phần 1–7, Phụ lục A–D) đã được cung cấp trong cuộc trò chuyện này; không truy cập GitHub, repository cũ hay lịch sử hội thoại cũ. Sử dụng sản phẩm từ các prompt trước nếu đã được tạo.

> **File hoặc sản phẩm đầu ra:** `view/templates/product_transactions.html`.

> **Nhiệm vụ, quy tắc nghiệp vụ và giới hạn:** Tạo `view/templates/product_transactions.html`: hiển thị product_id và start/end; form GET độc lập action revenue.report, text-align:right, hai hidden input start_date/end_date nằm trong form, nút Quay lại báo cáo doanh thu; khi có transactions render table border=1, margin auto, đúng 12 cột và Đơn giá ở cột 4, tiền right-align, None -> em-dash, tfoot colspan=4 + 6 totals + colspan=2; không có caption; nếu lỗi/no rows hiển thị đúng thông điệp. Không dùng JS hoặc ép rộng.

> **Kết quả mong đợi:** File/sản phẩm đích tồn tại trong dự án dựng mới, đúng cấu trúc và hợp đồng dữ liệu ở phần đặc tả; trình bày những gì đã tạo, chưa tạo, và lý do.

> **Tiêu chí nghiệm thu:** HTML form không lồng/đóng sớm, BTN-05 giữ ngày, Jinja parse. Nếu cần thao tác ghi DB hoặc xóa dữ liệu, yêu cầu người vận hành cho phép trên môi trường test mới trước; không ghi nhận PASS khi chưa chạy.

### PROMPT-025 — Tạo menu điều hướng và CSS inline tối thiểu

**Loại:** Prompt tái cấu trúc. **Lệnh gửi AI Agent:**

> **Vai trò:** Bạn là Lập trình viên Python/Flask MVC trong một phiên tái tạo độc lập.

> **Bối cảnh và đầu vào:** Toàn bộ tài liệu Markdown hiện tại (Phần 1–7, Phụ lục A–D) đã được cung cấp trong cuộc trò chuyện này; không truy cập GitHub, repository cũ hay lịch sử hội thoại cũ. Sử dụng sản phẩm từ các prompt trước nếu đã được tạo.

> **File hoặc sản phẩm đầu ra:** `view/templates/index.html, view/templates/reports.html`.

> **Nhiệm vụ, quy tắc nghiệp vụ và giới hạn:** Tạo `view/templates/index.html` và `view/templates/reports.html` từ Phụ lục B; trang chủ chỉ có menu Xem báo cáo GET /reports; reports chọn doanh thu GET /revenue và quay về / với margin-top:16px. Hai form back tại báo cáo/chi tiết text-align:right; hai table margin-left:auto và margin-right:auto. Không thay đổi cách căn phải từng cell, không thêm JS/CSS framework hay liên kết tới trang register từ menu nếu baseline không có.

> **Kết quả mong đợi:** File/sản phẩm đích tồn tại trong dự án dựng mới, đúng cấu trúc và hợp đồng dữ liệu ở phần đặc tả; trình bày những gì đã tạo, chưa tạo, và lý do.

> **Tiêu chí nghiệm thu:** NAV và BTN routes đúng, LAYOUT 3/3. Nếu cần thao tác ghi DB hoặc xóa dữ liệu, yêu cầu người vận hành cho phép trên môi trường test mới trước; không ghi nhận PASS khi chưa chạy.

### PROMPT-026 — Kiểm thử Unit và MySQL Module 2

**Loại:** Prompt tái cấu trúc. **Lệnh gửi AI Agent:**

> **Vai trò:** Bạn là Kỹ sư QA trong một phiên tái tạo độc lập.

> **Bối cảnh và đầu vào:** Toàn bộ tài liệu Markdown hiện tại (Phần 1–7, Phụ lục A–D) đã được cung cấp trong cuộc trò chuyện này; không truy cập GitHub, repository cũ hay lịch sử hội thoại cũ. Sử dụng sản phẩm từ các prompt trước nếu đã được tạo.

> **File hoặc sản phẩm đầu ra:** `src/tests/test_revenue.py; log test khi được phép`.

> **Nhiệm vụ, quy tắc nghiệp vụ và giới hạn:** Tạo `src/tests/test_revenue.py` đúng test groups tại Phần 3.10/Phụ lục C: 3 model, 4 DAO, 9 service, 6 MySQL read-only integration; MySQL integration mặc định skip, phải đặt RUN_REVENUE_DB_TESTS=1 và MYSQL_DATABASE=qlst_test có host/port/user guard; đối chiếu October 4 sản phẩm các net revenue, November chỉ return sản phẩm 5 net âm -500000, empty year 2020, nonexistent product, nextset reuse. Không dùng qlst production trong test; không tuyên bố PASS nếu chưa chạy.

> **Kết quả mong đợi:** File/sản phẩm đích tồn tại trong dự án dựng mới, đúng cấu trúc và hợp đồng dữ liệu ở phần đặc tả; trình bày những gì đã tạo, chưa tạo, và lý do.

> **Tiêu chí nghiệm thu:** Đối chiếu source nội tại và những điều kiện nghiệm thu tương ứng ở Phần 3/Phần 5; không tự báo PASS nếu chưa kiểm thử. Nếu cần thao tác ghi DB hoặc xóa dữ liệu, yêu cầu người vận hành cho phép trên môi trường test mới trước; không ghi nhận PASS khi chưa chạy.

### PROMPT-027 — Kiểm thử Flask và Jinja2 không tác động DB

**Loại:** Prompt tái cấu trúc. **Lệnh gửi AI Agent:**

> **Vai trò:** Bạn là Kỹ sư QA trong một phiên tái tạo độc lập.

> **Bối cảnh và đầu vào:** Toàn bộ tài liệu Markdown hiện tại (Phần 1–7, Phụ lục A–D) đã được cung cấp trong cuộc trò chuyện này; không truy cập GitHub, repository cũ hay lịch sử hội thoại cũ. Sử dụng sản phẩm từ các prompt trước nếu đã được tạo.

> **File hoặc sản phẩm đầu ra:** `Báo cáo static route, Flask/Jinja2 checks (không thay source)`.

> **Nhiệm vụ, quy tắc nghiệp vụ và giới hạn:** Kiểm tra Flask url_map và endpoint /, /register, /reports, /health, /revenue, /revenue/products/<product_id>/transactions bằng create_app chính; parse Jinja2 tất cả template; kiểm tra form registration CSRF, form GET báo cáo và hidden inputs, button trái/phải, table 11/12 cột, caption chỉ trên doanh thu, expression sum đúng. Dùng unittest mocks khi cần, không mở kết nối/ghi dữ liệu trừ khi người vận hành cho phép test tích hợp.

> **Kết quả mong đợi:** File/sản phẩm đích tồn tại trong dự án dựng mới, đúng cấu trúc và hợp đồng dữ liệu ở phần đặc tả; trình bày những gì đã tạo, chưa tạo, và lý do.

> **Tiêu chí nghiệm thu:** cú pháp hợp lệ, Jinja2 render đủ context và luồng lỗi. Nếu cần thao tác ghi DB hoặc xóa dữ liệu, yêu cầu người vận hành cho phép trên môi trường test mới trước; không ghi nhận PASS khi chưa chạy.

### PROMPT-028 — Kiểm thử Chrome NAV/BTN/LAYOUT/TABLE

**Loại:** Prompt tái cấu trúc. **Lệnh gửi AI Agent:**

> **Vai trò:** Bạn là Kỹ sư QA trong một phiên tái tạo độc lập.

> **Bối cảnh và đầu vào:** Toàn bộ tài liệu Markdown hiện tại (Phần 1–7, Phụ lục A–D) đã được cung cấp trong cuộc trò chuyện này; không truy cập GitHub, repository cũ hay lịch sử hội thoại cũ. Sử dụng sản phẩm từ các prompt trước nếu đã được tạo.

> **File hoặc sản phẩm đầu ra:** `Báo cáo Chrome NAV/BTN/LAYOUT/TABLE (không thay source)`.

> **Nhiệm vụ, quy tắc nghiệp vụ và giới hạn:** Sau khi app + DB demo mới được xác thực, chạy python -B app.py tại 127.0.0.1:5000 và Chrome. NAV-01..08 cần khớp 8 case gốc đã báo nghiệm thu; nếu tài liệu chưa có mapping từng NAV thì **không bịa**, lập kịch bản bổ sung và đánh dấu cần xác minh. Kiểm BTN-01 /→/reports, BTN-02 /reports→/revenue, BTN-03 /reports→/, BTN-04 /revenue→/reports, BTN-05 chi tiết product_id=5 → /revenue?start_date=2026-10-01&end_date=2026-10-31 giữ ngày. Kiểm LAYOUT-01..03: reports gap 16px, Thống kê left/back right, detail back right. TABLE-01 11 cột, caption/tổng/right-align/căn giữa; TABLE-02 12 cột, Đơn giá thứ tư, không caption, tổng/right-align/căn giữa. Không tự giảm cột khi bảng rộng; zoom để xem cơ chế auto margin.

> **Kết quả mong đợi:** File/sản phẩm đích tồn tại trong dự án dựng mới, đúng cấu trúc và hợp đồng dữ liệu ở phần đặc tả; trình bày những gì đã tạo, chưa tạo, và lý do.

> **Tiêu chí nghiệm thu:** báo PASS/FAIL thực tế, không thừa nhận từ lịch sử chat. Nếu cần thao tác ghi DB hoặc xóa dữ liệu, yêu cầu người vận hành cho phép trên môi trường test mới trước; không ghi nhận PASS khi chưa chạy.

### PROMPT-029 — Tổng nghiệm thu tái tạo và bàn giao

**Loại:** Prompt tái cấu trúc. **Lệnh gửi AI Agent:**

> **Vai trò:** Bạn là Kiến trúc sư hệ thống trong một phiên tái tạo độc lập.

> **Bối cảnh và đầu vào:** Toàn bộ tài liệu Markdown hiện tại (Phần 1–7, Phụ lục A–D) đã được cung cấp trong cuộc trò chuyện này; không truy cập GitHub, repository cũ hay lịch sử hội thoại cũ. Sử dụng sản phẩm từ các prompt trước nếu đã được tạo.

> **File hoặc sản phẩm đầu ra:** `Bảng đối chiếu nghiệm thu cuối / file dự án tái tạo`.

> **Nhiệm vụ, quy tắc nghiệp vụ và giới hạn:** Thực hiện kiểm kê file, diff và static checks; kiểm tra 29 bảng, 2 stored procedures, seed 126 hàng, file Python/template, endpoints, test integration chỉ trên qlst_test. Đối chiếu toàn bộ Phần 3 và Phần 5, ghi kết quả thật, nơi còn thiếu hoặc không thể xác minh. Không truy cập GitHub/repository cũ. Không tự push, commit hoặc ghi dữ liệu người dùng. Đầu ra cuối cùng: phiên bản hệ thống tương đương chạy độc lập cùng biên bản nghiệm thu và danh sách hạn chế.

> **Kết quả mong đợi:** File/sản phẩm đích tồn tại trong dự án dựng mới, đúng cấu trúc và hợp đồng dữ liệu ở phần đặc tả; trình bày những gì đã tạo, chưa tạo, và lý do.

> **Tiêu chí nghiệm thu:** Đối chiếu source nội tại và những điều kiện nghiệm thu tương ứng ở Phần 3/Phần 5; không tự báo PASS nếu chưa kiểm thử. Nếu cần thao tác ghi DB hoặc xóa dữ liệu, yêu cầu người vận hành cho phép trên môi trường test mới trước; không ghi nhận PASS khi chưa chạy.

## Phần 5 — Prompt kiểm thử và nghiệm thu thực thi được

Các prompt `PROMPT-010`, `PROMPT-018`, `PROMPT-025`–`PROMPT-028` chứa yêu cầu kiểm thử thực thi. Bảng dưới là **oracle**, không phải bằng chứng một bản dựng mới đã vượt qua kiểm thử. Lệnh chuẩn được phép chạy **sau khi đã chuẩn bị DB đích và xác nhận an toàn**:

```bash
# Chạy từ qlst-project, sau khi kích hoạt .venv
python -B -m unittest -v src.tests.test_revenue.ProductModelsTests src.tests.test_revenue.RevenueDAOUnitTests src.tests.test_revenue.RevenueServiceUnitTests
# CẢNH BÁO: test_registration có ghi và cleanup trên qlst_test; không chạy trên qlst.
MYSQL_DATABASE=qlst_test python -B -m unittest -v src.tests.test_registration
# Chỉ đọc qlst_test; bật cờ riêng cho kiểm thử DB doanh thu.
RUN_REVENUE_DB_TESTS=1 MYSQL_DATABASE=qlst_test python -B -m unittest -v src.tests.test_revenue.RevenueMySQLIntegrationTests
# Check_environment.py trong snapshot kiểm tra DATABASE() == 'qlst' (không phải qlst_test).
# Không dùng smoke check này để chứng minh cấu hình qlst_test.
```

**Điều kiện chuẩn bị:** test DB riêng có schema/seed đầy đủ và 2 Stored Procedure; `MYSQL_DATABASE=qlst_test` được chỉ rõ, host/port đã xác nhận, user không root, kết quả `SELECT DATABASE()` đúng tên, không chạy database/init.sql lên DB đã có dữ liệu. Test đăng ký tích hợp có ghi có điều kiện và cleanup, nên chỉ chạy khi được phép; phần P2/P3/P4 soạn tài liệu này **không thực thi** các lệnh DB.

| Nhóm          | Tiền điều kiện                       | Hành động/kết quả mong đợi                                                                            | PASS/FAIL                                                      |
| ------------- | ------------------------------------ | ----------------------------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| REG-01..08    | qlst_test; seed 7 users, 3 customers | new commit/hash/FK, username conflict, guest/member, 2 rollback, duplicate phone, invalid input       | Dữ liệu sau cleanup không bị tăng/giảm                         |
| REV-MODEL     | Không DB                             | 13/23 fields, Decimal âm, immutable, None                                                             | 3 tests theo `ProductModelsTests`                              |
| REV-DAO       | Mock Cursor                          | callproc đúng tên/thứ tự, nextset, propagates DB error                                                | 4 tests theo `RevenueDAOUnitTests`                             |
| REV-SERVICE   | Mock DB                              | date/product validation, [] hợp lệ, storage error, close connection                                   | 9 tests theo `RevenueServiceUnitTests`                         |
| REV-DB-OCT    | qlst_test seed                       | 4 products; product IDs 1/2/3/5; net revenue 63m/28m/13.5m/2.5m                                       | So sánh giá trị Decimal chính xác                              |
| REV-DB-NOV    | qlst_test seed                       | Product 5, no sales, 1 return, net_quantity=-1, net_revenue=-500000                                   | Không làm mất dấu âm                                           |
| REV-DB-EMPTY  | qlst_test seed                       | 2020 no rows; nonexistent valid product ID returns []                                                 | Không báo storage error/404                                    |
| BTN-01        | Chrome, Flask chính                  | / → /reports                                                                                          | Đúng URL và 200                                                |
| BTN-02        | Chrome                               | /reports → /revenue                                                                                   | Đúng URL và 200                                                |
| BTN-03        | Chrome                               | /reports → /                                                                                          | Đúng URL và 200                                                |
| BTN-04        | Chrome                               | /revenue → /reports                                                                                   | Đúng URL và 200                                                |
| BTN-05        | Chrome, dates October and product 5  | /revenue/products/5/transactions?start_date=2026-10-01&end_date=2026-10-31 → /revenue với cả hai ngày | Hai input date vẫn hiển thị đúng                               |
| LAYOUT-01..03 | Chrome                               | gap 16px ở reports; nút back căn phải trên báo cáo và chi tiết                                        | 3/3 kiểm tra trực quan                                         |
| TABLE-01      | Chrome, Oct data                     | 11 cột, caption, totals 6 values, right numbers, table centered                                       | Không mất cột/đổi dữ liệu                                      |
| TABLE-02      | Chrome, product 5                    | 12 cột, đơn giá thứ 4, no caption, 6 totals, right numbers, centered                                  | Không đổi dữ liệu / giữ GET back dates                         |
| NAV-01..08    | Chrome, thông tin nghiệm thu gốc     | Đã báo 8/8 PASS nhưng snapshot không chứa bản định nghĩa từng NAV case                                | Cần xây dựng mapping có bằng chứng trước khi gắn nhãn case gốc |
| SQL T01..T10  | DB seed mới                          | 73 nhãn test_id; kiểm tra đúng các điều kiện như test.sql                                             | Không coi T07/T08 oracle là proof CALL                         |

## Phần 6 — Phụ lục nguồn nội tại (đủ để Agent dựng file mà không đọc repository cũ)

**QUAN TRỌNG:** Những file dưới đây là nội dung được đưa trực tiếp vào tài liệu để Agent có thể dựng lại từ số 0. Trình bày dạng code block với đường dẫn chính xác. Dựa trên snapshot đã cung cấp, ngoại trừ các **thay thế rõ ràng vì an toàn** nêu ở Phần 2.3. Không dùng bản sao này để xác minh hash Git byte-for-byte. `database/init.sql` trong phụ lục là bản an toàn cần điền mật khẩu riêng trước khi chạy; `database/schema.sql`, `database/procedures.sql` và các logic tài chính giữ nguyên. Không chạy SQL hay Python chỉ bằng cách đọc tài liệu.

### Phụ lục A — SQL toàn hệ thống

Thứ tự dựng DB mới: `init.sql` (tùy chọn, **phá hủy DB trùng tên**), `schema.sql`, `procedures.sql`, `seed.sql`, sau cùng `test.sql` để kiểm tra. Agent cần trích từng khối vào đường dẫn đã ghi. Ở DB `qlst_test`, thay duy nhất dòng `USE qlst;` bằng `USE qlst_test;` trên **bản sao trong môi trường thử nghiệm**, không làm thay đổi logic DDL/procedure.

#### A.1 — `database/init.sql`

```sql
-- Biến thể demo an toàn của init.sql: cần thay mật khẩu trước khi chạy.
-- LỆNH DROP có tính phá hủy, chỉ dùng trên môi trường DB mới có chủ đích!
DROP DATABASE IF EXISTS qlst;
DROP USER IF EXISTS 'qlst_app'@'%';

CREATE DATABASE qlst CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'qlst_app'@'%' IDENTIFIED BY 'SET_YOUR_OWN_LOCAL_PASSWORD';
GRANT ALL PRIVILEGES ON qlst.* TO 'qlst_app'@'%';
FLUSH PRIVILEGES;
```

#### A.2 — `database/schema.sql`

```sql
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
```

#### A.3 — `database/procedures.sql`

```sql
SET NAMES utf8mb4;
USE qlst;

-- Chỉ triển khai hai Stored Procedure của Module 2.
-- Module đăng ký thành viên sẽ xử lý bằng Python OOP (UserDAO/CustomerDAO).
DROP PROCEDURE IF EXISTS sp_get_product_revenue_stats;
DROP PROCEDURE IF EXISTS sp_get_product_transactions;

DELIMITER $$

-- ============================================================================
-- 1. Thống kê mặt hàng theo doanh thu trong khoảng ngày (bao gồm cả hai đầu).
--    Doanh thu bán: hóa đơn completed, dòng chi tiết còn hiệu lực,
--                   ghi nhận theo invoices.invoice_date.
--    Hoàn trả:      returns completed, ghi nhận theo returns.completed_at.
--    Không dùng invoice_details.returned_quantity để trừ ngược kỳ bán.
--    Các giá trị ròng là DECIMAL có dấu; có thể âm.
-- ============================================================================
CREATE PROCEDURE sp_get_product_revenue_stats(
    IN p_start_date DATE,
    IN p_end_date   DATE
)
BEGIN
    IF p_start_date IS NULL
       OR p_end_date IS NULL
       OR p_start_date > p_end_date THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Khoang ngay thong ke khong hop le';
    END IF;

    SELECT
        p.product_id,
        p.name,
        p.brand,
        p.barcode,
        c.category_id,
        c.name AS category_name,
        p.price AS current_list_price,
        SUM(tx.quantity_sold) AS quantity_sold,
        SUM(tx.quantity_returned) AS quantity_returned,
        SUM(tx.quantity_sold) - SUM(tx.quantity_returned) AS net_quantity,
        SUM(tx.sales_revenue) AS sales_revenue,
        SUM(tx.refund_amount) AS refund_amount,
        SUM(tx.sales_revenue) - SUM(tx.refund_amount) AS net_revenue
    FROM (
        -- Một dòng hóa đơn là một giao dịch bán, không JOIN với returns.
        SELECT
            d.product_id,
            CAST(d.quantity AS DECIMAL(20, 0)) AS quantity_sold,
            CAST(0 AS DECIMAL(20, 0)) AS quantity_returned,
            (
                CAST(d.quantity AS DECIMAL(20, 0))
                * CAST(d.unit_price AS DECIMAL(30, 0))
                - CAST(d.discount_amount AS DECIMAL(30, 0))
            ) AS sales_revenue,
            CAST(0 AS DECIMAL(50, 0)) AS refund_amount
        FROM invoices AS i
        INNER JOIN invoice_details AS d
            ON d.invoice_id = i.invoice_id
           AND d.is_active = TRUE
        WHERE i.status = 'completed'
          AND i.invoice_date >= p_start_date
          AND i.invoice_date < DATE_ADD(p_end_date, INTERVAL 1 DAY)

        UNION ALL

        -- Mỗi phiếu trả completed là một giao dịch hoàn trả độc lập.
        SELECT
            d.product_id,
            CAST(0 AS DECIMAL(20, 0)) AS quantity_sold,
            CAST(r.quantity AS DECIMAL(20, 0)) AS quantity_returned,
            CAST(0 AS DECIMAL(50, 0)) AS sales_revenue,
            CAST(r.refund_amount AS DECIMAL(50, 0)) AS refund_amount
        FROM returns AS r
        INNER JOIN invoice_details AS d
            ON d.invoice_detail_id = r.invoice_detail_id
           AND d.is_active = TRUE
        INNER JOIN invoices AS i
            ON i.invoice_id = d.invoice_id
           AND i.status = 'completed'
        WHERE r.status = 'completed'
          AND r.completed_at >= p_start_date
          AND r.completed_at < DATE_ADD(p_end_date, INTERVAL 1 DAY)
    ) AS tx
    INNER JOIN products AS p
        ON p.product_id = tx.product_id
    INNER JOIN categories AS c
        ON c.category_id = p.category_id
    GROUP BY
        p.product_id,
        p.name,
        p.brand,
        p.barcode,
        c.category_id,
        c.name,
        p.price
    ORDER BY net_revenue DESC, quantity_sold DESC, p.product_id ASC;
END$$

-- ============================================================================
-- 2. Chi tiết các giao dịch của một mặt hàng trong khoảng ngày.
--    Mỗi hàng là một giao dịch bán hoặc một phiếu hoàn trả completed.
--    Các cột quantity_sold, quantity_returned, sales_revenue, refund_amount
--    cùng ngữ nghĩa với procedure tổng hợp nên có thể cộng để đối soát.
--    net_quantity / net_revenue có dấu: hoàn trả cho giá trị âm.
-- ============================================================================
CREATE PROCEDURE sp_get_product_transactions(
    IN p_product_id INT UNSIGNED,
    IN p_start_date DATE,
    IN p_end_date   DATE
)
BEGIN
    IF p_product_id IS NULL
       OR p_start_date IS NULL
       OR p_end_date IS NULL
       OR p_start_date > p_end_date THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Tham so thong ke khong hop le';
    END IF;

    SELECT
        tx.transaction_type,
        tx.transaction_at,
        tx.document_type,
        tx.document_id,
        tx.document_code,
        tx.product_id,
        p.name AS product_name,
        tx.invoice_id,
        tx.invoice_detail_id,
        tx.return_id,
        tx.channel,
        tx.quantity_sold,
        tx.quantity_returned,
        tx.quantity_sold - tx.quantity_returned AS net_quantity,
        tx.sales_revenue,
        tx.refund_amount,
        tx.sales_revenue - tx.refund_amount AS net_revenue,
        tx.unit_price,
        tx.original_line_discount,
        tx.unit_id,
        pu.serial_number,
        c.full_name AS customer_name,
        c.phone AS customer_phone
    FROM (
        SELECT
            'sale' AS transaction_type,
            i.invoice_date AS transaction_at,
            'invoice' AS document_type,
            i.invoice_id AS document_id,
            CONCAT('INV-', i.invoice_id) AS document_code,
            d.product_id,
            i.invoice_id,
            d.invoice_detail_id,
            NULL AS return_id,
            i.channel,
            CAST(d.quantity AS DECIMAL(20, 0)) AS quantity_sold,
            CAST(0 AS DECIMAL(20, 0)) AS quantity_returned,
            (
                CAST(d.quantity AS DECIMAL(20, 0))
                * CAST(d.unit_price AS DECIMAL(30, 0))
                - CAST(d.discount_amount AS DECIMAL(30, 0))
            ) AS sales_revenue,
            CAST(0 AS DECIMAL(50, 0)) AS refund_amount,
            d.unit_price,
            d.discount_amount AS original_line_discount,
            d.unit_id,
            i.customer_id
        FROM invoices AS i
        INNER JOIN invoice_details AS d
            ON d.invoice_id = i.invoice_id
           AND d.is_active = TRUE
        WHERE i.status = 'completed'
          AND d.product_id = p_product_id
          AND i.invoice_date >= p_start_date
          AND i.invoice_date < DATE_ADD(p_end_date, INTERVAL 1 DAY)

        UNION ALL

        SELECT
            'return' AS transaction_type,
            r.completed_at AS transaction_at,
            'return' AS document_type,
            r.return_id AS document_id,
            CONCAT('RET-', r.return_id) AS document_code,
            d.product_id,
            i.invoice_id,
            d.invoice_detail_id,
            r.return_id,
            i.channel,
            CAST(0 AS DECIMAL(20, 0)) AS quantity_sold,
            CAST(r.quantity AS DECIMAL(20, 0)) AS quantity_returned,
            CAST(0 AS DECIMAL(50, 0)) AS sales_revenue,
            CAST(r.refund_amount AS DECIMAL(50, 0)) AS refund_amount,
            d.unit_price,
            d.discount_amount AS original_line_discount,
            d.unit_id,
            i.customer_id
        FROM returns AS r
        INNER JOIN invoice_details AS d
            ON d.invoice_detail_id = r.invoice_detail_id
           AND d.is_active = TRUE
        INNER JOIN invoices AS i
            ON i.invoice_id = d.invoice_id
           AND i.status = 'completed'
        WHERE r.status = 'completed'
          AND d.product_id = p_product_id
          AND r.completed_at >= p_start_date
          AND r.completed_at < DATE_ADD(p_end_date, INTERVAL 1 DAY)
    ) AS tx
    INNER JOIN products AS p
        ON p.product_id = tx.product_id
    LEFT JOIN product_units AS pu
        ON pu.unit_id = tx.unit_id
    LEFT JOIN customers AS c
        ON c.customer_id = tx.customer_id
    ORDER BY
        tx.transaction_at DESC,
        tx.transaction_type ASC,
        tx.document_id DESC,
        tx.invoice_detail_id DESC;
END$$

DELIMITER ;
```

## Phần 7 — Checklist tái tạo độc lập và kiểm định P4

### 7.1. Checklist thực hiện trên bản dựng mới

- [ ] Tạo đúng cây thư mục và các file trong Phần 3/Phụ lục; không cần GitHub hoặc mã nguồn khác.
- [ ] Python 3.14.8, đủ bốn dependency và đúng config; `.env` riêng không được công bố.
- [ ] DB mới có 29 bảng, đủ PK/FK/UNIQUE/CHECK, hai Stored Procedure; seed demo 126 hàng hoạt động.
- [ ] Module 1 GET/POST, CSRF/session, Argon2id, khách mới/guest/member/username duplicate, transaction/rollback và status HTTP đúng.
- [ ] Module 2 GET báo cáo/chi tiết, đúng ngày, product ID, Decimal có dấu, 13/23 field từ procedure.
- [ ] Bảng báo cáo 11 cột + caption + 6 tổng, bảng chi tiết 12 cột không caption + 6 tổng, đơn giá thứ tư.
- [ ] Menu 2 cấp, form quay lại GET, hai hidden dates, nút Back căn phải, gap 16px, bảng tự căn giữa.
- [ ] Test unit/DB được chạy có chủ đích và có kết quả log thực tế; BTN/ LAYOUT/ TABLE trên Chrome đạt yêu cầu.
- [ ] Tài liệu không chứa mật khẩu MySQL, Flask secret, token truy cập hoặc dữ liệu cá nhân thật; dữ liệu liên hệ demo đã được thay thế bằng fixture.
- [ ] Không nhầm prompt tái cấu trúc với prompt gốc; không tuyên bố chạy test nếu chưa chạy.

### 7.2. Chốt chất lượng tài liệu (P4 — kiểm tra tĩnh)

P4 ở đây xác nhận: hồ sơ Markdown chứa các phần, bản DDL/procedure/seed/test, các file runtime/test cần thiết, prompt đánh số liên tục, các điểm bảo mật được ghi rõ. **Chưa** triển khai bản tái tạo thứ hai, chưa chạy SQL hay Flask trong môi trường soạn Markdown, nên tính tương đương runtime cuối cùng vẫn phải được một Agent thực hiện và nghiệm thu lại.

### 7.3. Những giới hạn còn tồn tại

1. Prompt gốc của giai đoạn đầu không nằm trong ZIP; chỉ có thể chứng minh một số trích đoạn yêu cầu từ hội thoại cung cấp. Bộ `PROMPT-001..PROMPT-029` là **biên soạn lại**.
2. Snapshot không có văn bản đề bài/UML ở `docs/diagrams`, không thể khẳng định các sơ đồ đã được biên soạn.
3. Snapshot có file `README.md`, `run.txt`, `view/base.html` rỗng; hướng dẫn setup trong tài liệu là đối chiếu code, không phải copy README.
4. Giá trị CSRF session key đã được thay cho tài liệu và commit mới chỉ được chấp nhận làm baseline kiểm kê; thay đổi CSRF chưa có nghiệm thu chức năng riêng.
5. Dữ liệu liên hệ trong seed/test được giả danh để tránh đưa thông tin cá nhân lên tài liệu, vì vậy **không có bảo đảm byte-for-byte** với bản nguồn; các quan hệ, ID và phép tính nghiệp vụ cần được test lại khi dựng mới; hash demo được tạo lại nên đăng nhập bằng mật khẩu demo trước đó không được bảo đảm (chức năng đăng nhập không thuộc phạm vi).
6. MySQL version cụ thể và Docker Compose không có trong snapshot; cần cấu hình một MySQL tương thích với CHECK enforced, generated columns và cú pháp procedure, không tự nói đã xác minh phiên bản.
7. Kết quả kiểm thử của hệ thống gốc là báo cáo nghiệm thu người thực hiện, không phải log thực thi được tạo trong phiên soạn tài liệu.

**Kết luận:** Tài liệu này là một bộ prompt + dữ liệu kỹ thuật nội tại đủ để tiến hành dựng lại mã nguồn và schema mà không dùng repository gốc. Chỉ đánh dấu “bản tái tạo PASS” sau khi chạy các kiểm tra ở Phần 5 và checklist trên trong môi trường mới.
