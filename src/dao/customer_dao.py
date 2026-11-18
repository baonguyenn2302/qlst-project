"""DAO cho bảng customers của Module 1: đăng ký thành viên.

Nhận kết nối từ Database.connection()/Database.transaction(); KHÔNG tự mở
kết nối, commit hay rollback. Số điện thoại phải được tầng nghiệp vụ
chuẩn hóa trước khi gọi DAO; xác minh quyền sở hữu hồ sơ cũ cũng là trách
nhiệm của tầng nghiệp vụ, KHÔNG phải của DAO.
"""
from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING

from src.model.customer import Customer

if TYPE_CHECKING:
    from pymysql.connections import Connection


class CustomerLinkConflictError(RuntimeError):
    """Không thể liên kết: hồ sơ không tồn tại, đã liên kết hoặc bị vô hiệu."""


class CustomerDAO:
    """Truy cập bảng customers qua kết nối do lớp gọi truyền vào."""

    def __init__(self, connection: Connection) -> None:
        self._connection = connection

    def _require_transaction(self) -> None:
        """Ngăn lệnh ghi/khóa hàng chạy trên kết nối đang autocommit."""
        if self._connection.get_autocommit():
            raise RuntimeError(
                "CustomerDAO yêu cầu kết nối autocommit=False; "
                "hãy dùng Database.transaction()"
            )

    def find_by_phone(self, phone: str) -> Customer | None:
        """Tìm hồ sơ theo số điện thoại ĐÃ chuẩn hóa; không tự sửa số điện thoại.

        Phù hợp để hiển thị/tra cứu. Đối với luồng nâng cấp thành viên,
        hãy dùng find_by_phone_for_update() trong một transaction.
        """
        with self._connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT customer_id, user_id, full_name, phone, email, address,
                       loyalty_points, registered_at, member_since, is_active
                FROM customers
                WHERE phone = %s
                LIMIT 1
                """,
                (phone,),
            )
            row = cursor.fetchone()
        return Customer(**row) if row is not None else None

    def find_by_phone_for_update(self, phone: str) -> Customer | None:
        """Khóa hồ sơ hiện có bằng SELECT ... FOR UPDATE đến hết transaction.

        Nếu không có hồ sơ, trả None. Trường hợp hai yêu cầu đăng ký mới
        đồng thời vẫn cần dựa vào UNIQUE(customers.phone) và xử lý
        IntegrityError tại tầng nghiệp vụ; khóa một hàng chưa tồn tại
        không thay thế được ràng buộc UNIQUE.
        """
        self._require_transaction()
        with self._connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT customer_id, user_id, full_name, phone, email, address,
                       loyalty_points, registered_at, member_since, is_active
                FROM customers
                WHERE phone = %s
                LIMIT 1 FOR UPDATE
                """,
                (phone,),
            )
            row = cursor.fetchone()
        return Customer(**row) if row is not None else None

    def create(
        self,
        *,
        user_id: int | None,
        full_name: str,
        phone: str,
        registered_at: datetime,
        member_since: datetime | None,
        email: str | None = None,
        address: str | None = None,
    ) -> Customer:
        """Tạo hồ sơ mới; trả về Customer với ID vừa được MySQL cấp.

        Với thành viên mới, tầng nghiệp vụ truyền user_id của tài khoản
        vừa tạo và cùng một thời điểm cho registered_at/member_since.
        Với khách vãng lai, user_id/member_since đều None. CHECK và
        UNIQUE trong MySQL là lớp bảo vệ cuối cùng.

        Dùng trong cùng Database.transaction() với UserDAO.create().
        KHÔNG tự commit/rollback và KHÔNG bắt IntegrityError tại DAO.
        """
        self._require_transaction()
        with self._connection.cursor() as cursor:
            cursor.execute(
                """
                INSERT INTO customers (
                    user_id, full_name, phone, email, address,
                    loyalty_points, registered_at, member_since, is_active
                ) VALUES (%s, %s, %s, %s, %s, 0, %s, %s, TRUE)
                """,
                (user_id, full_name, phone, email, address,
                 registered_at, member_since),
            )
            customer_id = int(cursor.lastrowid)
            cursor.execute(
                """
                SELECT customer_id, user_id, full_name, phone, email, address,
                       loyalty_points, registered_at, member_since, is_active
                FROM customers
                WHERE customer_id = %s
                """,
                (customer_id,),
            )
            row = cursor.fetchone()
        if row is None:
            raise RuntimeError("Không đọc được hồ sơ khách hàng vừa tạo")
        return Customer(**row)

    def link_user(
        self,
        *,
        customer_id: int,
        user_id: int,
        member_since: datetime,
    ) -> Customer:
        """Liên kết tài khoản với hồ sơ khách vãng lai ĐÃ xác minh sở hữu.

        Tầng nghiệp vụ phải xác minh quyền sở hữu trước khi gọi hàm này,
        sau đó dùng find_by_phone_for_update() trong cùng transaction.
        UPDATE chỉ thành công nếu hồ sơ vẫn chưa liên kết và còn hoạt động.
        Không thay đổi customer_id, phone, registered_at, loyalty_points,
        lịch sử giao dịch hoặc các thông tin khách hàng khác.
        """
        self._require_transaction()
        with self._connection.cursor() as cursor:
            cursor.execute(
                """
                UPDATE customers
                SET user_id = %s, member_since = %s
                WHERE customer_id = %s
                  AND user_id IS NULL
                  AND member_since IS NULL
                  AND is_active = TRUE
                """,
                (user_id, member_since, customer_id),
            )
            if cursor.rowcount != 1:
                raise CustomerLinkConflictError(
                    "Không thể liên kết: hồ sơ không tồn tại, "
                    "không hoạt động hoặc đã có tài khoản"
                )
            cursor.execute(
                """
                SELECT customer_id, user_id, full_name, phone, email, address,
                       loyalty_points, registered_at, member_since, is_active
                FROM customers
                WHERE customer_id = %s
                """,
                (customer_id,),
            )
            row = cursor.fetchone()
        if row is None:
            raise RuntimeError("Không đọc được hồ sơ khách hàng sau liên kết")
        return Customer(**row)
