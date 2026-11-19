"""DAO chỉ đọc cho Module 2: gọi Stored Procedure thống kê doanh thu.

Connection do Database.connection() quản lý ở tầng gọi; DAO không mở,
đóng, commit hoặc rollback connection và không tính lại doanh thu.
"""
from __future__ import annotations

from datetime import date
from typing import TYPE_CHECKING, Any

from src.model.revenue import ProductRevenue, ProductTransaction

if TYPE_CHECKING:
    from pymysql.connections import Connection


class RevenueDAO:
    """Đọc thống kê và chi tiết giao dịch bằng hai Stored Procedure có sẵn."""

    def __init__(self, connection: Connection) -> None:
        self._connection = connection

    def _call_procedure(
        self, 
        procedure_name: str, 
        parameters: tuple[object, ...]
    ) -> list[dict[str, Any]]:
        """Đọc result set chính và giải phóng các result set còn lại của CALL.

        Database.open() cấu hình DictCursor, nên mỗi dòng là dictionary.
        Tên procedure chỉ được truyền từ hai phương thức bên dưới.
        """
        with self._connection.cursor() as cursor:
            cursor.callproc(procedure_name, parameters)
            try:
                rows = cursor.fetchall()
            finally:
                # MySQL CALL có thể kèm result set trạng thái ở cuối.
                # Đọc hết để connection dùng tiếp được an toàn.
                while cursor.nextset():
                    if cursor.description is not None:
                        cursor.fetchall()
            return list(rows)

    def get_product_revenue_stats(
        self, 
        start_date: date, 
        end_date: date
    ) -> list[ProductRevenue]:
        """Thống kê từng sản phẩm trong khoảng ngày (bao gồm hai đầu)."""
        rows = self._call_procedure(
            "sp_get_product_revenue_stats", 
            (start_date, end_date)
        )
        return [ProductRevenue.from_row(row) for row in rows]

    def get_product_transactions(
        self, 
        product_id: int, 
        start_date: date, 
        end_date: date
    ) -> list[ProductTransaction]:
        """Liệt kê giao dịch bán/hoàn trả của một sản phẩm trong kỳ."""
        rows = self._call_procedure(
            "sp_get_product_transactions", 
            (product_id, start_date, end_date)
        )
        return [ProductTransaction.from_row(row) for row in rows]
