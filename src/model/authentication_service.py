"""Xac thuc tai khoan va kiem tra quyen truy cap bao cao."""

from __future__ import annotations

from typing import Literal

from src.dao.db import Database
from src.dao.user_dao import UserDAO
from src.model.password_service import PasswordService


_EMPLOYEE_ROLES = frozenset({
    "admin",
    "manager",
    "warehouse",
    "sales",
    "delivery",
})

_REVENUE_ROLES = frozenset({"admin", "manager"})

RevenueAccess = Literal["allowed", "forbidden", "login_required"]


class AuthenticationService:
    """Xu ly xac thuc va phan quyen, khong phu thuoc Flask."""

    def __init__(
        self,
        *,
        password_service: PasswordService | None = None,
        database: type[Database] = Database,
    ) -> None:
        self._password_service = password_service or PasswordService()
        self._database = database

    @staticmethod
    def _is_active_context(context: dict[str, object] | None) -> bool:
        """Kiem tra tai khoan va ho so lien ket con hoat dong."""
        if context is None:
            return False

        if context.get("user_is_active") != 1:
            return False

        role = context.get("role_code")

        if role == "customer":
            return (
                context.get("customer_id") is not None
                and context.get("customer_is_active") == 1
                and context.get("employee_id") is None
            )

        if role in _EMPLOYEE_ROLES:
            return (
                context.get("employee_id") is not None
                and context.get("employee_is_active") == 1
                and context.get("customer_id") is None
            )

        return False

    def authenticate(self, username: str, password: str) -> int | None:
        """Xac minh thong tin dang nhap, chi tra ve user_id."""
        if not isinstance(username, str) or not isinstance(password, str):
            return None

        normalized_username = username.strip()

        if (
            not normalized_username
            or len(normalized_username) > 50
            or any(char.isspace() for char in normalized_username)
            or not password
            or len(password) > 256
        ):
            return None

        with self._database.connection() as connection:
            users = UserDAO(connection)
            user = users.find_by_username(normalized_username)

            if user is None or not user.is_active:
                return None

            if not self._password_service.verify_password(
                password, user.password_hash
            ):
                return None

            context = users.get_auth_context_by_user_id(user.user_id)

        if not self._is_active_context(context):
            return None

        if context.get("user_id") != user.user_id:
            return None

        return user.user_id

    def get_active_context(
        self, user_id: int
    ) -> dict[str, object] | None:
        """Doc lai trang thai va vai tro tu database."""
        if type(user_id) is not int or user_id <= 0:
            return None

        with self._database.connection() as connection:
            context = UserDAO(connection).get_auth_context_by_user_id(
                user_id
            )

        if not self._is_active_context(context):
            return None

        if context.get("user_id") != user_id:
            return None

        return context

    def revenue_access(self, user_id: int) -> RevenueAccess:
        """Kiem tra quyen bao cao bang du lieu MySQL moi nhat."""
        context = self.get_active_context(user_id)

        if context is None:
            return "login_required"

        if (
            context["role_code"] in _REVENUE_ROLES
            and context["employee_id"] is not None
            and context["employee_is_active"] == 1
        ):
            return "allowed"

        return "forbidden"
