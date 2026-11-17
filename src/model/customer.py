"""Model cho bảng customers, gồm khách vãng lai và thành viên."""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime


@dataclass(frozen=True, slots=True)
class Customer:
    """Hồ sơ khách hàng đã lưu trong MySQL.

    registered_at là ngày tạo hồ sơ, member_since là ngày trở thành thành viên.
    Việc nâng cấp khách vãng lai không tạo customer_id mới.
    """

    customer_id: int
    user_id: int | None
    full_name: str
    phone: str
    email: str | None
    address: str | None
    loyalty_points: int
    registered_at: datetime
    member_since: datetime | None
    is_active: bool

    @property
    def is_member(self) -> bool:
        """Chỉ báo trạng thái từ dữ liệu đã được ràng buộc tại MySQL."""
        return self.user_id is not None and self.member_since is not None
