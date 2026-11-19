"""Service cho Module 2: kiểm tra đầu vào và điều phối RevenueDAO.

Không chứa SQL, không tự tính doanh thu, không sửa dữ liệu MySQL.
Controller sẽ chuyển chuỗi ngày từ biểu mẫu thành datetime.date trước khi gọi.
"""
from __future__ import annotations

from datetime import date

from pymysql.err import MySQLError

from src.dao.db import Database
from src.dao.revenue_dao import RevenueDAO
from src.model.revenue import ProductRevenue, ProductTransaction


class RevenueError(Exception):
    """Lỗi khi lấy báo cáo doanh thu."""


class RevenueValidationError(RevenueError):
    """Tham số thống kê không hợp lệ."""


class RevenueStorageError(RevenueError):
    """Lỗi truy cập MySQL; không để lộ chi tiết SQL ra giao diện."""


class RevenueService:
    """Kiểm tra tham số rồi lấy dữ liệu chỉ đọc qua RevenueDAO."""

    def __init__(self, *, database: type[Database] = Database) -> None:
        self._database = database

    @staticmethod
    def _validate_dates(start_date: date, end_date: date) -> None:
        """Nhận đúng datetime.date, không nhận chuỗi hay datetime."""
        if type(start_date) is not date or type(end_date) is not date:
            raise RevenueValidationError("Ngày bắt đầu và kết thúc phải là ngày hợp lệ.")
        if start_date > end_date:
            raise RevenueValidationError("Ngày bắt đầu không được sau ngày kết thúc.")

    @staticmethod
    def _validate_product_id(product_id: int) -> None:
        """ID sản phẩm phải thuộc miền INT UNSIGNED của MySQL."""
        if type(product_id) is not int or not 1 <= product_id <= 4_294_967_295:
            raise RevenueValidationError("Mã sản phẩm phải là số nguyên dương hợp lệ.")

    def get_product_revenue_stats(
        self, start_date: date, end_date: date
    ) -> list[ProductRevenue]:
        """Lấy thống kê doanh thu trong khoảng ngày bao gồm hai đầu."""
        self._validate_dates(start_date, end_date)
        try:
            with self._database.connection() as connection:
                return RevenueDAO(connection).get_product_revenue_stats(
                    start_date, end_date
                )
        except MySQLError as exc:
            raise RevenueStorageError(
                "Không thể tải thống kê doanh thu. Vui lòng thử lại sau."
            ) from exc

    def get_product_transactions(
        self, 
        product_id: int, 
        start_date: date, 
        end_date: date
    ) -> list[ProductTransaction]:
        """Lấy giao dịch bán/hoàn trả của một sản phẩm trong khoảng ngày."""
        self._validate_product_id(product_id)
        self._validate_dates(start_date, end_date)
        try:
            with self._database.connection() as connection:
                return RevenueDAO(connection).get_product_transactions(
                    product_id, start_date, end_date
                )
        except MySQLError as exc:
            raise RevenueStorageError(
                "Không thể tải giao dịch sản phẩm. Vui lòng thử lại sau."
            ) from exc
