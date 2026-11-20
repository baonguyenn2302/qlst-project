"""Truy vấn tài khoản. Không mở kết nối và không commit/rollback tại DAO."""
from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING

from src.model.user import User

if TYPE_CHECKING:
    from pymysql.connections import Connection


class UserDAO:
    """Nhận connection do Database.connection()/transaction() quản lý."""

    def __init__(self, connection: Connection) -> None:
        self._connection = connection

    def find_by_username(self, username: str) -> User | None:
        """Tìm tài khoản, dùng cả để kiểm tra trùng username.

        UNIQUE uq_users_username vẫn là hàng rào cuối cùng khi hai request đồng thời.
        """
        with self._connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT user_id, username, password_hash, role_id,
                       is_active, last_login_at, created_at
                FROM users
                WHERE username = %s
                LIMIT 1
                """,
                (username,),
            )
            row = cursor.fetchone()
        return User(**row) if row is not None else None

    def get_customer_role_id(self) -> int:
        """Tra vai trò theo mã, tránh phụ thuộc giá trị ID của dữ liệu demo."""
        with self._connection.cursor() as cursor:
            cursor.execute(
                "SELECT role_id FROM roles WHERE code = %s LIMIT 1",
                ("customer",),
            )
            row = cursor.fetchone()
        if row is None:
            raise LookupError("Không tìm thấy vai trò 'customer' trong bảng roles")
        return int(row["role_id"])

    def create(
        self,
        *,
        username: str,
        password_hash: str,
        role_id: int,
        created_at: datetime,
    ) -> User:
        """Tạo tài khoản từ hash đã do PasswordService sinh.

        Cố ý không gọi commit; toàn bộ giao dịch đăng ký do lớp nghiệp vụ
        bao trong Database.transaction(). IntegrityError được truyền lên
        để lớp nghiệp vụ phân loại, rollback và trả thông báo phù hợp.
        """
        with self._connection.cursor() as cursor:
            cursor.execute(
                """
                INSERT INTO users (username, password_hash, role_id,
                                   is_active, created_at)
                VALUES (%s, %s, %s, TRUE, %s)
                """,
                (username, password_hash, role_id, created_at),
            )
            user_id = int(cursor.lastrowid)
        return User(
            user_id=user_id,
            username=username,
            password_hash=password_hash,
            role_id=role_id,
            is_active=True,
            last_login_at=None,
            created_at=created_at,
        )

    def get_auth_context_by_user_id(self, user_id: int) -> dict[str, object] | None:
        """Tra cuu vai tro va trang thai tai khoan de xac thuc, phan quyen.

        Chi truy van du lieu; khong cap quyen tai DAO.
        Khong tra ve password_hash va khong thuc hien thao tac ghi.
        """
        with self._connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT
                    u.user_id,
                    u.username,
                    u.is_active AS user_is_active,
                    r.code AS role_code,
                    e.employee_id,
                    e.is_active AS employee_is_active,
                    c.customer_id,
                    c.is_active AS customer_is_active
                FROM users AS u
                INNER JOIN roles AS r
                    ON r.role_id = u.role_id
                LEFT JOIN employees AS e
                    ON e.user_id = u.user_id
                LEFT JOIN customers AS c
                    ON c.user_id = u.user_id
                WHERE u.user_id = %s
                LIMIT 1
                """,
                (user_id,),
            )
            return cursor.fetchone()
