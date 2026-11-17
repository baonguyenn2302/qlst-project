"""Model cho bảng users. Không lưu mật khẩu ở dạng plaintext."""
from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime


@dataclass(frozen=True, slots=True)
class User:
    """Một tài khoản đã được lưu trong MySQL.

    role_id liên kết với roles; không mặc định role_id=6 trong mã nguồn.
    """

    user_id: int
    username: str
    password_hash: str = field(repr=False)
    role_id: int
    is_active: bool
    last_login_at: datetime | None
    created_at: datetime
