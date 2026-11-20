# HỆ THỐNG QUẢN LÝ SIÊU THỊ ĐIỆN MÁY

**Bài tập lớn môn Phân tích và thiết kế hệ thống thông tin — Đề số 10**  
**Sinh viên:** Nguyễn Gia Bảo  
**Mã sinh viên:** B23DCCN075  
**Thư mục dự án:** `qlst-project`

## 1. Giới thiệu

Đây là ứng dụng web quản lý siêu thị điện máy, phát triển bằng Python/Flask và MySQL. Phạm vi triển khai tập trung vào hai module của đề bài:

- **Module 1 — Đăng ký thành viên:** khách hàng nhập thông tin cá nhân và tài khoản; hệ thống kiểm tra dữ liệu, tài khoản trùng, trạng thái hồ sơ khách hàng và lưu thông tin bằng transaction. Mật khẩu được băm bằng Argon2id. Trường hợp khách vãng lai đã có hồ sơ cần xác minh được thông báo; quy trình OTP chưa được triển khai.
- **Module 2 — Thống kê mặt hàng theo doanh thu:** nhân viên có quyền chọn khoảng ngày, xem bảng doanh thu theo sản phẩm, chọn một sản phẩm để xem các giao dịch bán và hoàn trả trong kỳ. Truy vấn báo cáo sử dụng Stored Procedure và dữ liệu tiền tệ được xử lý phù hợp bằng `Decimal`.

Ứng dụng có **đăng nhập, đăng xuất, Flask session và phân quyền**. Tài khoản `admin` hoặc `manager` đang hoạt động với hồ sơ nhân viên hợp lệ được xem báo cáo; các vai trò khác có thể đăng nhập theo điều kiện tương ứng nhưng không được xem báo cáo doanh thu. Việc kiểm tra quyền thực hiện ở phía server, không chỉ dựa vào việc ẩn liên kết trên giao diện.

**Phạm vi:** các chức năng quản lý siêu thị khác được mô tả trong đề bài và tài liệu phân tích, không đồng nghĩa tất cả đã có màn hình và nghiệp vụ thực thi trong ứng dụng Flask hiện tại.

## 2. Công nghệ và môi trường

| Thành phần          | Phiên bản/công nghệ                                             |
| ------------------- | --------------------------------------------------------------- |
| Ngôn ngữ            | Python 3.14.8 (môi trường phát triển của dự án)                 |
| Web framework       | Flask 3.1.3                                                     |
| Kết nối MySQL       | PyMySQL 1.2.4                                                   |
| Mật khẩu            | argon2-cffi 25.1.0 (Argon2id)                                   |
| Cấu hình môi trường | python-dotenv 1.2.4                                             |
| Giao diện           | HTML, Jinja2, CSS                                               |
| Database            | MySQL, 29 bảng theo schema dự án, Stored Procedure              |
| Kiểm thử            | `unittest`, Flask Test Client và kiểm thử tích hợp có kiểm soát |

Các thư viện Python được khai báo trong `requirements.txt`. Dự án được phát triển và chạy thử trên macOS; MySQL có thể chạy trong Docker nếu đã thiết lập container tương ứng.

## 3. Cấu trúc thư mục

```text
qlst-project/
├── app.py                         # Điểm vào Flask; tạo app, đăng ký Blueprint
├── README.md                      # Tài liệu dự án
├── run.txt                        # Lệnh chạy nhanh trên Mac
├── requirements.txt               # Thư viện Python
├── .env.example                   # Mẫu biến môi trường (không chứa mật khẩu thật)
├── database/
│   ├── init.sql                   # Script khởi tạo CSDL, có lệnh DROP (cẩn trọng)
│   ├── schema.sql                 # Định nghĩa cấu trúc bảng
│   ├── procedures.sql             # Stored Procedure
│   ├── seed.sql                   # Dữ liệu mẫu
│   └── test.sql                   # Script SQL thử nghiệm
├── src/
│   ├── config.py                  # Đọc cấu hình .env
│   ├── controller/                # HTTP route, CSRF, session, phân quyền
│   ├── model/                     # Model và nghiệp vụ Service
│   ├── dao/                       # Truy cập dữ liệu MySQL
│   └── tests/                     # Kiểm thử tự động
├── view/
│   ├── base.html
│   ├── templates/                 # Các template Jinja2
│   └── static/                    # CSS/JS, tài nguyên tĩnh

```

Thư mục `.venv/`, `.git/`, `__pycache__/` và file `.env` là thành phần môi trường cục bộ; không cần phân phối kèm mã nguồn.

## 4. Chuẩn bị môi trường trên macOS

### 4.1. Yêu cầu

- Python 3.14.8 (ưu tiên phiên bản đã dùng cho dự án).
- `pip` và khả năng tạo môi trường ảo `venv`.
- MySQL đang hoạt động và có cơ sở dữ liệu phù hợp với `schema.sql`/`procedures.sql`.
- Docker **chỉ khi** bạn chạy MySQL qua Docker.

Mở Terminal ở thư mục gốc `qlst-project`:

```bash
cd /Users/baonguyenn/SourceCode/Demos/ptit-subjects/sad-projects/qlst-project
```

Nếu làm việc với một bản giải nén mới hoặc `.venv` không còn hoạt động, tạo lại môi trường ảo bằng Python 3.14 đã cài trên Mac:

```bash
python3.14 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
```

Nếu môi trường ảo đã có và hoạt động, chỉ cần:

```bash
source .venv/bin/activate
python --version
python -m pip install -r requirements.txt
```

### 4.2. Cấu hình `.env`

Nếu thư mục dự án **chưa có** `.env`:

```bash
cp .env.example .env
```

Mở `.env` bằng trình soạn thảo và cấu hình các biến:

```dotenv
FLASK_SECRET_KEY=<chuoi-ngau-nhien-bi-mat>
FLASK_DEBUG=0
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3307
MYSQL_USER=<tai-khoan-mysql>
MYSQL_PASSWORD=<mat-khau-mysql>
MYSQL_DATABASE=qlst_test
MYSQL_CONNECT_TIMEOUT=5
```

Đoạn trên là **mẫu minh họa**, không sử dụng nguyên các chuỗi trong dấu `<...>`. Bạn có thể tạo giá trị secret key ngẫu nhiên bằng:

```bash
python -c 'import secrets; print(secrets.token_hex(32))'
```

**Chú ý:** `.env.example` trong mã nguồn gốc đang có `MYSQL_DATABASE=qlst`; sau khi sao chép, hãy **đổi thành `qlst_test` nếu chạy thử hoặc kiểm thử** để tránh thao tác nhầm lên database chính. `src/config.py` đọc `.env` qua `python-dotenv` và không tự ghi đè các biến đã đặt từ Terminal. Không commit hoặc chia sẻ `.env`, mật khẩu hay secret key. Khi công khai mã nguồn, cũng cần rà soát `database/init.sql` vì bản script gốc có thông tin tài khoản MySQL dạng rõ (plaintext).

### 4.3. Kiểm tra MySQL

Nếu sử dụng Docker, xem các container đang chạy:

```bash
docker ps
```

Chỉ khi container `qlst-mysql` **đã tồn tại nhưng đang dừng**, mới chạy:

```bash
docker start qlst-mysql
```

Cấu hình mẫu của dự án sử dụng MySQL ở `127.0.0.1:3307`. Database `qlst_test` phải tồn tại và có schema/Stored Procedure phù hợp trước khi thực hiện kiểm thử tích hợp.

**Không chạy `database/init.sql` trên database đang sử dụng:** script này chứa `DROP DATABASE IF EXISTS qlst` và `DROP USER IF EXISTS ...`, có thể xóa database và tài khoản hiện tại. Không tự chạy `schema.sql`, `seed.sql` hoặc `test.sql` trên dữ liệu cần giữ nguyên. Nếu cần khởi tạo môi trường mới, phải kiểm tra script và xác nhận đúng database đích trước.

## 5. Chạy ứng dụng

Tại thư mục gốc, kích hoạt `.venv`, kiểm tra `.env` rồi chạy:

```bash
source .venv/bin/activate
python app.py
```

Ứng dụng khởi chạy tại:

**http://127.0.0.1:5000**

`app.py` sử dụng `host="127.0.0.1"`, `port=5000` và `debug=False`, tức chỉ phục vụ cục bộ trên máy đang chạy.

Một số địa chỉ chính:

| Method   | URL                                           | Chức năng                                              |
| -------- | --------------------------------------------- | ------------------------------------------------------ |
| GET      | `/`                                           | Điều hướng theo trạng thái đăng nhập                   |
| GET/POST | `/login`                                      | Hiển thị và xử lý đăng nhập                            |
| POST     | `/logout`                                     | Đăng xuất có CSRF                                      |
| GET/POST | `/register`                                   | Đăng ký thành viên                                     |
| GET      | `/menu`                                       | Menu nhân viên đã đăng nhập                            |
| GET      | `/account`                                    | Trang tài khoản khách hàng                             |
| GET      | `/reports`                                    | Menu báo cáo (cần quyền)                               |
| GET      | `/revenue`                                    | Bộ lọc và thống kê doanh thu theo sản phẩm (cần quyền) |
| GET      | `/revenue/products/<product_id>/transactions` | Chi tiết giao dịch (cần quyền)                         |
| GET      | `/health`                                     | Xác nhận Flask đang chạy, **không kiểm tra MySQL**     |

Ví dụ URL báo cáo (sau khi đăng nhập bằng tài khoản đủ quyền):

```text
http://127.0.0.1:5000/revenue?start_date=2026-11-01&end_date=2026-11-30
```

Mở `/health` chỉ để kiểm tra web server; nhận JSON `{"status":"ok","component":"flask"}` không có nghĩa kết nối MySQL đã được xác nhận.

Dừng ứng dụng bằng **Ctrl + C** tại Terminal.

## 6. Kiểm thử

### 6.1. Module 2 — kiểm thử mock, không dùng MySQL

```bash
python -m unittest -v src.tests.test_revenue
```

Mặc định đây là các bài kiểm tra mock, không kết nối MySQL nếu `RUN_REVENUE_DB_TESTS` không bật.

### 6.2. Module 2 — kiểm thử tích hợp MySQL (chỉ `qlst_test`)

```bash
RUN_REVENUE_DB_TESTS=1 MYSQL_DATABASE=qlst_test \
  python -m unittest -v src.tests.test_revenue
```

Các bài kiểm thử truy vấn dữ liệu báo cáo theo cấu hình và không thêm/sửa/xóa bản ghi.

### 6.3. Module 1 — kiểm thử tích hợp (chỉ `qlst_test`)

```bash
MYSQL_DATABASE=qlst_test \
  python -m unittest -v src.tests.test_registration
```

Bộ kiểm thử Module 1 có thao tác tạo dữ liệu thử nghiệm và dọn dẹp chính dữ liệu thử nghiệm đó. Code kiểm thử có kiểm tra database đích, host và port trước khi thực hiện DML. **Không chạy khi chưa xác nhận database `qlst_test` là bản thử nghiệm.**

### 6.4. Lưu ý về `check_environment.py`

`src/tests/check_environment.py` hiện vẫn có các điều kiện **cố định theo `qlst`** và số lượng hash ở bộ dữ liệu mẫu trước đây. Vì vậy, **không dùng script này làm smoke test mặc định trên `qlst_test`** nếu chưa điều chỉnh lại tiêu chí; báo FAIL có thể do giả định cũ, không nhất thiết do ứng dụng lỗi.

Không chạy `python -m unittest discover` một cách tùy tiện nếu chưa kiểm soát biến `MYSQL_DATABASE`, vì có testcase tích hợp đụng đến dữ liệu thử nghiệm.

## 7. Kiến trúc và nguyên tắc bảo mật

Dự án tổ chức theo luồng:

```text
Browser / Jinja2
       ↓ HTTP
Controller / Blueprint
       ↓
Service / Model
       ↓
DAO
       ↓
MySQL / Stored Procedure
```

- Controller tiếp nhận HTTP, kiểm tra CSRF, session và phân quyền; không tự viết SQL nghiệp vụ.
- Service thực hiện xác thực và xử lý nghiệp vụ; các thao tác ghi đăng ký dùng transaction với commit/rollback.
- DAO tập trung truy vấn MySQL.
- Mật khẩu được băm bằng Argon2id; không lưu plaintext hoặc password hash trong Flask session.
- Các endpoint báo cáo đều yêu cầu xác thực và phân quyền phía server.
- Flask session được cấu hình permanent với thời hạn 30 phút; logout dùng POST có CSRF.
- Không đưa dữ liệu bí mật trong `.env` vào README, ảnh chụp, sơ đồ hoặc kho Git.

## 8. Tài liệu và sơ đồ

- `docs/diagrams/`: sơ đồ nghiệp vụ, phân tích và thiết kế hệ thống.
- `docs/report/`: bản thảo và sản phẩm báo cáo.
- `docs/prompts/`: tài liệu hỗ trợ quy trình biên soạn.

Các hình UML chính thức dùng trong báo cáo cần được vẽ và **xuất từ Visual Paradigm** theo yêu cầu môn học; ảnh dựng bằng công cụ khác chỉ nên dùng để xem trước, không khẳng định là ảnh xuất từ Visual Paradigm.

## 9. Khắc phục lỗi thường gặp

| Hiện tượng                                  | Kiểm tra                                                                    |
| ------------------------------------------- | --------------------------------------------------------------------------- |
| `ModuleNotFoundError`                       | Đã `source .venv/bin/activate` và cài `requirements.txt` chưa?              |
| `Thieu MYSQL_USER` / `Thieu MYSQL_PASSWORD` | Kiểm tra các biến trong `.env`; không gửi mật khẩu khi nhờ hỗ trợ           |
| Thiếu `FLASK_SECRET_KEY`                    | Tạo secret ngẫu nhiên, không dùng giá trị `CHANGE_ME...`                    |
| `Connection refused` đến MySQL              | Kiểm tra container/server và cổng 3307                                      |
| `Unknown database`                          | Kiểm tra `MYSQL_DATABASE`, database đã tồn tại chưa                         |
| 403 khi mở báo cáo                          | Tài khoản không thuộc vai trò đủ quyền hoặc hồ sơ/trạng thái không hợp lệ   |
| Chuyển sang `/login`                        | Chưa đăng nhập hoặc session đã hết hiệu lực                                 |
| `/health` hoạt động nhưng báo cáo lỗi       | `/health` không kiểm tra MySQL; cần kiểm tra riêng kết nối database         |
| Không mở được cổng 5000                     | Kiểm tra ứng dụng khác đang sử dụng cổng hoặc Terminal chạy server trước đó |

## 10. Ghi chú

Tài liệu này được lập theo cấu trúc mã nguồn có trong bản dự án hiện tại. Nếu thay đổi route, schema, yêu cầu môn học hoặc cách triển khai, cần cập nhật README và `run.txt` tương ứng.
