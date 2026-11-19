"""Model dữ liệu thống kê doanh thu sản phẩm (Module 2).

Mỗi đối tượng ánh xạ đúng một dòng kết quả của Stored Procedure.
Không truy vấn MySQL, không tính lại doanh thu trong Python.
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal
from typing import Any, Mapping, Self


@dataclass(frozen=True, slots=True)
class ProductRevenue:
    """Một dòng từ sp_get_product_revenue_stats(start_date, end_date)."""

    product_id: int
    name: str
    brand: str | None
    barcode: str | None
    category_id: int
    category_name: str
    current_list_price: Decimal
    quantity_sold: int
    quantity_returned: int
    net_quantity: int
    sales_revenue: Decimal
    refund_amount: Decimal
    net_revenue: Decimal

    @classmethod
    def from_row(cls, row: Mapping[str, Any]) -> Self:
        """Chuyển một dòng DictCursor thành Model; không tính toán lại số liệu."""
        return cls(
            product_id=int(row["product_id"]),
            name=row["name"],
            brand=row["brand"],
            barcode=row["barcode"],
            category_id=int(row["category_id"]),
            category_name=row["category_name"],
            current_list_price=Decimal(row["current_list_price"]),
            quantity_sold=int(row["quantity_sold"]),
            quantity_returned=int(row["quantity_returned"]),
            net_quantity=int(row["net_quantity"]),
            sales_revenue=Decimal(row["sales_revenue"]),
            refund_amount=Decimal(row["refund_amount"]),
            net_revenue=Decimal(row["net_revenue"]),
        )


@dataclass(frozen=True, slots=True)
class ProductTransaction:
    """Một dòng bán/hoàn trả từ sp_get_product_transactions(...)."""

    transaction_type: str
    transaction_at: datetime
    document_type: str
    document_id: int
    document_code: str
    product_id: int
    product_name: str
    invoice_id: int
    invoice_detail_id: int
    return_id: int | None
    channel: str
    quantity_sold: int
    quantity_returned: int
    net_quantity: int
    sales_revenue: Decimal
    refund_amount: Decimal
    net_revenue: Decimal
    unit_price: Decimal
    original_line_discount: Decimal
    unit_id: int | None
    serial_number: str | None
    customer_name: str | None
    customer_phone: str | None

    @classmethod
    def from_row(cls, row: Mapping[str, Any]) -> Self:
        """Ánh xạ một dòng DictCursor; các cột NULL được giữ là None."""
        return cls(
            transaction_type=row["transaction_type"],
            transaction_at=row["transaction_at"],
            document_type=row["document_type"],
            document_id=int(row["document_id"]),
            document_code=row["document_code"],
            product_id=int(row["product_id"]),
            product_name=row["product_name"],
            invoice_id=int(row["invoice_id"]),
            invoice_detail_id=int(row["invoice_detail_id"]),
            return_id=int(row["return_id"]) if row["return_id"] is not None else None,
            channel=row["channel"],
            quantity_sold=int(row["quantity_sold"]),
            quantity_returned=int(row["quantity_returned"]),
            net_quantity=int(row["net_quantity"]),
            sales_revenue=Decimal(row["sales_revenue"]),
            refund_amount=Decimal(row["refund_amount"]),
            net_revenue=Decimal(row["net_revenue"]),
            unit_price=Decimal(row["unit_price"]),
            original_line_discount=Decimal(row["original_line_discount"]),
            unit_id=int(row["unit_id"]) if row["unit_id"] is not None else None,
            serial_number=row["serial_number"],
            customer_name=row["customer_name"],
            customer_phone=row["customer_phone"],
        )