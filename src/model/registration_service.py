"""Nghiệp vụ đăng ký thành viên (Module 1) — không chứa SQL hoặc Flask.

Phiên bản hiện tại:
* Khách hoàn toàn mới: tạo users + customers trong MỘT transaction.
* Hồ sơ khách vãng lai: từ chối liên kết khi chưa xác minh qua OTP.
* Thành viên hiện có: từ chối đăng ký trùng.

OTP chưa được triển khai, vì vậy tuyệt đối không gọi CustomerDAO.link_user().
Các DAO cùng nhận connection từ Database.transaction(); không tự commit.
"""
from __future__ import annotations

import re
from dataclasses import dataclass
from datetime import datetime
from typing import Callable

from pymysql.err import IntegrityError, MySQLError, OperationalError

from src.dao.customer_dao import CustomerDAO
from src.dao.db import Database
from src.dao.user_dao import UserDAO
from src.model.password_service import PasswordService


class RegistrationError(Exception):
    """Lỗi đăng ký có thể được Controller chuyển thành thông báo phù hợp."""


class RegistrationValidationError(RegistrationError):
    """Thông tin đăng ký không hợp lệ."""


class UsernameAlreadyExistsError(RegistrationError):
    """Tên đăng nhập đã có tài khoản sử dụng."""


class GuestVerificationRequiredError(RegistrationError):
    """Số điện thoại thuộc hồ sơ vãng lai, phải xác minh trước khi liên kết."""


class AlreadyRegisteredError(RegistrationError):
    """Khách hàng đã có tài khoản thành viên."""


class RegistrationConflictError(RegistrationError):
    """Dữ liệu đăng ký bị thay đổi/trùng trong một giao dịch đồng thời."""


class RegistrationStorageError(RegistrationError):
    """Có lỗi cấu hình hoặc truy cập MySQL; không đưa lỗi SQL ra giao diện."""


class RegistrationRetryableError(RegistrationStorageError):
    """Transaction gặp deadlock hoặc quá thời gian chờ khóa."""


@dataclass(frozen=True, slots=True)
class RegistrationResult:
    """Thông tin an toàn để Controller hiển thị sau khi COMMIT thành công."""

    user_id: int
    customer_id: int
    username: str
    full_name: str
    phone: str
    member_since: datetime


class RegistrationService:
    """Điều phối Model/DAO; không mở cursor và không viết SQL trực tiếp.

    `clock` và `password_service` có thể thay bằng đối tượng giả trong unit test.
    `database` mặc định là lớp Database đã kiểm thử trong dự án.
    """

    def __init__(
        self,
        *,
        password_service: PasswordService | None = None,
        database: type[Database] = Database,
        clock: Callable[[], datetime] | None = None,
    ) -> None:
        self._password_service = password_service or PasswordService()
        self._database = database
        self._clock = clock or datetime.now

    @staticmethod
    def normalize_phone(value: str) -> str:
        """Chuẩn hóa số di động Việt Nam về 0xxxxxxxxx để tra UNIQUE phone.

        Chấp nhận '090...', '+8490...' hoặc '8490...' và dấu phân cách
        thường gặp. Không giả định đã xác minh sở hữu số điện thoại.
        """
        if not isinstance(value, str):
            raise RegistrationValidationError("Vui lòng nhập số điện thoại.")
        phone = re.sub(r"[\s().-]", "", value)
        if phone.startswith("+84"):
            phone = "0" + phone[3:]
        elif phone.startswith("84") and len(phone) == 11:
            phone = "0" + phone[2:]
        if not re.fullmatch(r"0[0-9]{9}", phone):
            raise RegistrationValidationError(
                "Số điện thoại phải gồm 10 chữ số, bắt đầu bằng 0 "
                "(hoặc dùng mã quốc gia +84)."
            )
        return phone

    @staticmethod
    def _required_text(
        value: str, 
        *, 
        field_name: str, 
        max_length: int
    ) -> str:
        if not isinstance(value, str):
            raise RegistrationValidationError(f"Vui lòng nhập {field_name}.")
        cleaned = " ".join(value.split()) if field_name == "họ tên" else value.strip()
        if not cleaned:
            raise RegistrationValidationError(f"Vui lòng nhập {field_name}.")
        if len(cleaned) > max_length:
            raise RegistrationValidationError(
                f"{field_name.capitalize()} không được quá {max_length} ký tự."
            )
        return cleaned

    @staticmethod
    def _optional_text(
        value: str | None, 
        *, 
        field_name: str, 
        max_length: int
    ) -> str | None:
        if value is None:
            return None
        if not isinstance(value, str):
            raise RegistrationValidationError(f"{field_name.capitalize()} không hợp lệ.")
        cleaned = value.strip()
        if not cleaned:
            return None
        if len(cleaned) > max_length:
            raise RegistrationValidationError(
                f"{field_name.capitalize()} không được quá {max_length} ký tự."
            )
        return cleaned

    @classmethod
    def _validate_input(
        cls,
        *,
        full_name: str,
        phone: str,
        username: str,
        password: str,
        email: str | None,
        address: str | None,
    ) -> tuple[str, str, str, str | None, str | None]:
        name = cls._required_text(
            full_name, field_name="họ tên", max_length=100
        )
        normalized_phone = cls.normalize_phone(phone)
        normalized_username = cls._required_text(
            username, field_name="tên đăng nhập", max_length=50
        )
        if any(ch.isspace() for ch in normalized_username):
            raise RegistrationValidationError("Tên đăng nhập không được chứa khoảng trắng.")
        # Không in/log/mang mật khẩu sang Model hay giá trị trả về.
        if not isinstance(password, str) or not (8 <= len(password) <= 256):
            raise RegistrationValidationError("Mật khẩu phải từ 8 đến 256 ký tự.")
        normalized_email = cls._optional_text(
            email, field_name="email", max_length=100
        )
        if normalized_email is not None and not re.fullmatch(
            r"[^@\s]+@[^@\s]+\.[^@\s]+", normalized_email
        ):
            raise RegistrationValidationError("Địa chỉ email không đúng định dạng.")
        normalized_address = cls._optional_text(
            address, field_name="địa chỉ", max_length=255
        )
        return (
            name,
            normalized_phone,
            normalized_username,
            normalized_email,
            normalized_address,
        )

    def register(
        self,
        *,
        full_name: str,
        phone: str,
        username: str,
        password: str,
        email: str | None = None,
        address: str | None = None,
    ) -> RegistrationResult:
        """Đăng ký THÀNH VIÊN MỚI; không liên kết khách vãng lai.

        Ném RegistrationError khi yêu cầu không thể thực hiện. Khi xảy ra lỗi
        trong `with Database.transaction()`, context manager sẽ ROLLBACK.
        Trả RegistrationResult chỉ sau khi transaction COMMIT thành công.
        """
        name, normalized_phone, account_name, mail, location = self._validate_input(
            full_name=full_name,
            phone=phone,
            username=username,
            password=password,
            email=email,
            address=address,
        )

        try:
            with self._database.transaction() as connection:
                customers = CustomerDAO(connection)
                users = UserDAO(connection)

                existing = customers.find_by_phone(normalized_phone)
                if existing is not None:
                    if existing.is_member:
                        raise AlreadyRegisteredError(
                            "Số điện thoại này đã đăng ký thành viên."
                        )
                    raise GuestVerificationRequiredError(
                        "Số điện thoại đã có hồ sơ khách hàng. "
                        "Cần xác minh số điện thoại để kích hoạt thành viên."
                    )

                if users.find_by_username(account_name) is not None:
                    raise UsernameAlreadyExistsError(
                        "Tên đăng nhập đã được sử dụng. Vui lòng chọn tên khác."
                    )

                # Lấy role từ bảng roles, KHÔNG gắn cứng role_id theo seed.
                customer_role_id = users.get_customer_role_id()
                password_hash = self._password_service.hash_password(password)
                created_at = self._clock().replace(microsecond=0)

                user = users.create(
                    username=account_name,
                    password_hash=password_hash,
                    role_id=customer_role_id,
                    created_at=created_at,
                )
                customer = customers.create(
                    user_id=user.user_id,
                    full_name=name,
                    phone=normalized_phone,
                    email=mail,
                    address=location,
                    registered_at=created_at,
                    member_since=created_at,
                )
                outcome = RegistrationResult(
                    user_id=user.user_id,
                    customer_id=customer.customer_id,
                    username=user.username,
                    full_name=customer.full_name,
                    phone=customer.phone,
                    member_since=customer.member_since,
                )
            return outcome
        except IntegrityError as exc:
            # Bao gồm cả lỗi UNIQUE khi 2 request đồng thời qua bước SELECT.
            code = exc.args[0] if exc.args else None
            detail = str(exc.args[1] if len(exc.args) > 1 else "").lower()
            if code == 1062:
                if "uq_users_username" in detail:
                    raise UsernameAlreadyExistsError(
                        "Tên đăng nhập đã được sử dụng. Vui lòng chọn tên khác."
                    ) from exc
                if "uq_customers_phone" in detail:
                    raise RegistrationConflictError(
                        "Số điện thoại vừa được đăng ký bởi một yêu cầu khác. "
                        "Vui lòng thử lại."
                    ) from exc
                raise RegistrationConflictError(
                    "Thông tin đã trùng với một bản ghi khác. Vui lòng thử lại."
                ) from exc
            raise RegistrationStorageError(
                "Không thể lưu đăng ký do ràng buộc dữ liệu."
            ) from exc
        except OperationalError as exc:
            code = exc.args[0] if exc.args else None
            if code in (1205, 1213):
                raise RegistrationRetryableError(
                    "Hệ thống đang xử lý yêu cầu khác. Vui lòng thử lại."
                ) from exc
            raise RegistrationStorageError(
                "Không thể kết nối hoặc lưu dữ liệu lúc này."
            ) from exc
        except MySQLError as exc:
            raise RegistrationStorageError(
                "Có lỗi MySQL khi thực hiện đăng ký."
            ) from exc
        except LookupError as exc:
            raise RegistrationStorageError(
                "Hệ thống chưa được cấu hình vai trò khách hàng."
            ) from exc
