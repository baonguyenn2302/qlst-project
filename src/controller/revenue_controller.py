"""Flask Controller cho Module 2: báo cáo và giao dịch doanh thu sản phẩm.

Chỉ xử lý HTTP GET, chuyển tham số và hiển thị dữ liệu từ RevenueService.
Không gọi DAO, không tính lại doanh thu và không ghi dữ liệu MySQL.
"""
from __future__ import annotations

from datetime import date

from flask import Blueprint, current_app, render_template, request

from src.controller.auth_controller import require_revenue_access
from src.model.revenue import ProductRevenue, ProductTransaction
from src.model.revenue_service import (
    RevenueService,
    RevenueStorageError,
    RevenueValidationError,
)

revenue_bp = Blueprint("revenue", __name__)


def _parse_date_range() -> tuple[date, date]:
    """Chuyển hai tham số GET YYYY-MM-DD thành date; không kiểm tra nghiệp vụ."""
    start_text = request.args.get("start_date", "")
    end_text = request.args.get("end_date", "")
    if not start_text or not end_text:
        raise RevenueValidationError("Vui lòng nhập đủ ngày bắt đầu và ngày kết thúc.")
    try:
        start_date = date.fromisoformat(start_text)
        end_date = date.fromisoformat(end_text)
    except ValueError as exc:
        raise RevenueValidationError(
            "Ngày phải có định dạng YYYY-MM-DD và là ngày hợp lệ."
        ) from exc
    if start_date.isoformat() != start_text or end_date.isoformat() != end_text:
        raise RevenueValidationError("Ngày phải có định dạng YYYY-MM-DD.")
    return start_date, end_date


def _parse_product_id(raw_id: str) -> int:
    """Chuyển ID từ URL thành int; Service kiểm tra miền giá trị hợp lệ."""
    try:
        return int(raw_id)
    except ValueError as exc:
        raise RevenueValidationError("Mã sản phẩm phải là số nguyên hợp lệ.") from exc


def _render_report(
    *,
    products: list[ProductRevenue] | None = None,
    error: str | None = None,
    has_searched: bool = False,
    status: int = 200,
) -> tuple[str, int]:
    """Chuyển dữ liệu và trạng thái tìm kiếm cho template báo cáo."""
    return render_template(
        "revenue_report.html",
        title="Thống kê doanh thu sản phẩm",
        start_date=request.args.get("start_date", ""),
        end_date=request.args.get("end_date", ""),
        products=products if products is not None else [],
        error=error,
        has_searched=has_searched,
    ), status


def _render_transactions(
    *,
    product_id: str | int,
    transactions: list[ProductTransaction] | None = None,
    error: str | None = None,
    status: int = 200,
) -> tuple[str, int]:
    """Chuyển dữ liệu giao dịch cho template chi tiết sản phẩm."""
    return render_template(
        "product_transactions.html",
        title="Chi tiết giao dịch sản phẩm",
        product_id=product_id,
        start_date=request.args.get("start_date", ""),
        end_date=request.args.get("end_date", ""),
        transactions=transactions if transactions is not None else [],
        error=error,
    ), status


@revenue_bp.get("/revenue")
@require_revenue_access
def report():
    """GET /revenue: hiển thị form hoặc báo cáo theo khoảng ngày."""
    # Mở trang lần đầu: chưa yêu cầu truy vấn, không mở connection.
    if "start_date" not in request.args and "end_date" not in request.args:
        return _render_report()

    try:
        start_date, end_date = _parse_date_range()
        products = RevenueService().get_product_revenue_stats(start_date, end_date)
    except RevenueValidationError as exc:
        return _render_report(error=str(exc), status=400, has_searched=True)
    except RevenueStorageError:
        current_app.logger.exception("Revenue report storage error")
        return _render_report(
            error="Không thể tải báo cáo doanh thu. Vui lòng thử lại sau.",
            status=503,
            has_searched=True,
        )
    return _render_report(products=products, has_searched=True)


@revenue_bp.get("/revenue/products/<product_id>/transactions")
@require_revenue_access
def transactions(product_id: str):
    """GET: hiển thị giao dịch bán/hoàn trả của một sản phẩm trong kỳ."""
    try:
        parsed_product_id = _parse_product_id(product_id)
        start_date, end_date = _parse_date_range()
        rows = RevenueService().get_product_transactions(
            parsed_product_id, start_date, end_date
        )
    except RevenueValidationError as exc:
        return _render_transactions(product_id=product_id, error=str(exc), status=400)
    except RevenueStorageError:
        current_app.logger.exception("Revenue transactions storage error")
        return _render_transactions(
            product_id=product_id,
            error="Không thể tải giao dịch sản phẩm. Vui lòng thử lại sau.",
            status=503,
        )
    return _render_transactions(product_id=parsed_product_id, transactions=rows)
