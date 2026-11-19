"""Kiểm thử Module 2: Model, RevenueDAO và RevenueService.

Chạy mặc định (chỉ mock, không kết nối MySQL):
    python -m unittest -v src.tests.test_revenue

Chạy cả mock và tích hợp MySQL (chỉ qlst_test):
    RUN_REVENUE_DB_TESTS=1 MYSQL_DATABASE=qlst_test \
        python -m unittest -v src.tests.test_revenue

Không có INSERT/UPDATE/DELETE, không tạo dữ liệu và không tự dọn dữ liệu.
"""
from __future__ import annotations

import os
import unittest
from contextlib import contextmanager
from dataclasses import FrozenInstanceError, fields
from datetime import date, datetime
from decimal import Decimal
from unittest.mock import MagicMock, patch

from pymysql.err import MySQLError

from src.config import DatabaseSettings
from src.dao.db import Database
from src.dao.revenue_dao import RevenueDAO
from src.model.revenue import ProductRevenue, ProductTransaction
from src.model.revenue_service import (
    RevenueService,
    RevenueStorageError,
    RevenueValidationError,
)

OCTOBER_START = date(2026, 10, 1)
OCTOBER_END = date(2026, 10, 31)
NOVEMBER_START = date(2026, 11, 1)
NOVEMBER_END = date(2026, 11, 30)


def _revenue_row() -> dict:
    """13 cột theo sp_get_product_revenue_stats, sản phẩm #5 tháng 11."""
    return {
        "product_id": 5,
        "name": "Củ sạc nhanh Apple 20W USB-C",
        "brand": "Apple",
        "barcode": "8938505970059",
        "category_id": 5,
        "category_name": "Phụ kiện công nghệ",
        "current_list_price": 500000,
        "quantity_sold": Decimal("0"),
        "quantity_returned": Decimal("1"),
        "net_quantity": Decimal("-1"),
        "sales_revenue": Decimal("0"),
        "refund_amount": Decimal("500000"),
        "net_revenue": Decimal("-500000"),
    }


def _transaction_row() -> dict:
    """23 cột theo sp_get_product_transactions, phiếu trả RET-2."""
    return {
        "transaction_type": "return",
        "transaction_at": datetime(2026, 11, 5, 10, 30),
        "document_type": "return",
        "document_id": 2,
        "document_code": "RET-2",
        "product_id": 5,
        "product_name": "Củ sạc nhanh Apple 20W USB-C",
        "invoice_id": 3,
        "invoice_detail_id": 6,
        "return_id": 2,
        "channel": "online",
        "quantity_sold": Decimal("0"),
        "quantity_returned": Decimal("1"),
        "net_quantity": Decimal("-1"),
        "sales_revenue": Decimal("0"),
        "refund_amount": Decimal("500000"),
        "net_revenue": Decimal("-500000"),
        "unit_price": 500000,
        "original_line_discount": 0,
        "unit_id": None,
        "serial_number": None,
        "customer_name": "Trần Thị Bình",
        "customer_phone": "0902345678",
    }


class ProductModelsTests(unittest.TestCase):
    """Ánh xạ dữ liệu Model; hoàn toàn không sử dụng database."""

    def test_01_product_revenue_has_13_columns_and_preserves_negative(self):
        raw = _revenue_row()
        self.assertEqual(tuple(f.name for f in fields(ProductRevenue)), tuple(raw))
        model = ProductRevenue.from_row(raw)
        self.assertEqual(model.product_id, 5)
        self.assertEqual(model.net_quantity, -1)
        self.assertIsInstance(model.quantity_returned, int)
        self.assertIsInstance(model.current_list_price, Decimal)
        self.assertEqual(model.net_revenue, Decimal("-500000"))
        self.assertIsInstance(model.net_revenue, Decimal)

    def test_02_product_transaction_has_23_columns_and_nullable_fields(self):
        raw = _transaction_row()
        self.assertEqual(tuple(f.name for f in fields(ProductTransaction)), tuple(raw))
        model = ProductTransaction.from_row(raw)
        self.assertEqual(model.transaction_type, "return")
        self.assertEqual(model.document_code, "RET-2")
        self.assertIsInstance(model.transaction_at, datetime)
        self.assertIsNone(model.unit_id)
        self.assertIsNone(model.serial_number)
        self.assertEqual(model.customer_phone, "0902345678")
        self.assertEqual(model.refund_amount, Decimal("500000"))
        self.assertEqual(model.net_revenue, Decimal("-500000"))

    def test_03_models_cannot_be_modified_accidentally(self):
        revenue = ProductRevenue.from_row(_revenue_row())
        transaction = ProductTransaction.from_row(_transaction_row())
        with self.assertRaises(FrozenInstanceError):
            revenue.net_revenue = Decimal("0")
        with self.assertRaises(FrozenInstanceError):
            transaction.net_revenue = Decimal("0")


class RevenueDAOUnitTests(unittest.TestCase):
    """Giả lập DictCursor để kiểm tra DAO, không gọi MySQL thật."""

    @staticmethod
    def _fake_connection(rows: list[dict]):
        connection = MagicMock()
        cursor = MagicMock()
        connection.cursor.return_value.__enter__.return_value = cursor
        cursor.fetchall.return_value = rows
        cursor.nextset.return_value = False
        return connection, cursor

    def test_01_stats_calls_exact_procedure_and_maps_models(self):
        connection, cursor = self._fake_connection([_revenue_row()])
        models = RevenueDAO(connection).get_product_revenue_stats(
            NOVEMBER_START, NOVEMBER_END
        )
        cursor.callproc.assert_called_once_with(
            "sp_get_product_revenue_stats", (NOVEMBER_START, NOVEMBER_END)
        )
        cursor.execute.assert_not_called()
        cursor.fetchall.assert_called_once_with()
        self.assertEqual(len(models), 1)
        self.assertIsInstance(models[0], ProductRevenue)
        self.assertEqual(models[0].net_revenue, Decimal("-500000"))
        connection.cursor.return_value.__exit__.assert_called_once()

    def test_02_transactions_calls_exact_procedure_and_maps_models(self):
        connection, cursor = self._fake_connection([_transaction_row()])
        models = RevenueDAO(connection).get_product_transactions(
            5, NOVEMBER_START, NOVEMBER_END
        )
        cursor.callproc.assert_called_once_with(
            "sp_get_product_transactions", (5, NOVEMBER_START, NOVEMBER_END)
        )
        cursor.execute.assert_not_called()
        self.assertEqual(len(models), 1)
        self.assertIsInstance(models[0], ProductTransaction)
        self.assertEqual(models[0].return_id, 2)
        self.assertEqual(models[0].net_revenue, Decimal("-500000"))

    def test_03_extra_resultsets_are_consumed(self):
        connection, cursor = self._fake_connection([_revenue_row()])
        # CALL có thể trả result set phụ. DAO chỉ giữ dữ liệu chính.
        cursor.fetchall.side_effect = [
            [_revenue_row()],
            [{"procedure_status": "ignored"}],
        ]
        cursor.nextset.side_effect = [True, False]
        cursor.description = ("procedure_status",)
        result = RevenueDAO(connection).get_product_revenue_stats(
            NOVEMBER_START, NOVEMBER_END
        )
        self.assertEqual(len(result), 1)
        self.assertEqual(cursor.fetchall.call_count, 2)
        self.assertEqual(cursor.nextset.call_count, 2)
        self.assertEqual(result[0].net_revenue, Decimal("-500000"))

    def test_04_database_error_is_not_hidden_as_empty_list(self):
        connection, cursor = self._fake_connection([])
        cursor.callproc.side_effect = MySQLError("simulated procedure failure")
        with self.assertRaises(MySQLError):
            RevenueDAO(connection).get_product_revenue_stats(
                NOVEMBER_START, NOVEMBER_END
            )


class FakeDatabase:
    """Connection giả lập; đếm số lần mở và đóng, không đụng MySQL."""

    opened = 0
    closed = 0
    fake_connection = object()

    @classmethod
    @contextmanager
    def connection(cls):
        cls.opened += 1
        try:
            yield cls.fake_connection
        finally:
            cls.closed += 1


class RevenueServiceUnitTests(unittest.TestCase):
    """Kiểm tra nghiệp vụ Service bằng mock, mặc định chạy an toàn."""

    def setUp(self):
        FakeDatabase.opened = 0
        FakeDatabase.closed = 0
        self.service = RevenueService(database=FakeDatabase)

    def test_01_stats_delegates_and_preserves_negative_decimal(self):
        sample = ProductRevenue.from_row(_revenue_row())
        with patch("src.model.revenue_service.RevenueDAO") as dao_class:
            dao_class.return_value.get_product_revenue_stats.return_value = [sample]
            result = self.service.get_product_revenue_stats(
                NOVEMBER_START, NOVEMBER_END
            )
            dao_class.assert_called_once_with(FakeDatabase.fake_connection)
            dao_class.return_value.get_product_revenue_stats.assert_called_once_with(
                NOVEMBER_START, NOVEMBER_END
            )
        self.assertEqual(result, [sample])
        self.assertEqual(result[0].net_revenue, Decimal("-500000"))
        self.assertEqual((FakeDatabase.opened, FakeDatabase.closed), (1, 1))

    def test_02_transaction_detail_delegates_with_product_id(self):
        sample = ProductTransaction.from_row(_transaction_row())
        with patch("src.model.revenue_service.RevenueDAO") as dao_class:
            dao_class.return_value.get_product_transactions.return_value = [sample]
            result = self.service.get_product_transactions(
                5, NOVEMBER_START, NOVEMBER_END
            )
            dao_class.return_value.get_product_transactions.assert_called_once_with(
                5, NOVEMBER_START, NOVEMBER_END
            )
        self.assertEqual(result, [sample])
        self.assertEqual((FakeDatabase.opened, FakeDatabase.closed), (1, 1))

    def test_03_single_day_range_is_accepted(self):
        day = date(2026, 11, 5)
        with patch("src.model.revenue_service.RevenueDAO") as dao_class:
            dao_class.return_value.get_product_revenue_stats.return_value = []
            self.assertEqual(self.service.get_product_revenue_stats(day, day), [])
            dao_class.return_value.get_product_revenue_stats.assert_called_once_with(
                day, day
            )
        self.assertEqual((FakeDatabase.opened, FakeDatabase.closed), (1, 1))

    def test_04_invalid_dates_are_rejected_before_opening_connection(self):
        bad_pairs = [
            (NOVEMBER_END, NOVEMBER_START),
            (None, NOVEMBER_END),
            (NOVEMBER_START, None),
            ("2026-11-01", NOVEMBER_END),
            (NOVEMBER_START, "2026-11-30"),
            (datetime(2026, 11, 1), NOVEMBER_END),
            (NOVEMBER_START, datetime(2026, 11, 30)),
        ]
        for start, end in bad_pairs:
            with self.subTest(start=start, end=end):
                with self.assertRaises(RevenueValidationError):
                    self.service.get_product_revenue_stats(start, end)
                with self.assertRaises(RevenueValidationError):
                    self.service.get_product_transactions(5, start, end)
        self.assertEqual((FakeDatabase.opened, FakeDatabase.closed), (0, 0))

    def test_05_invalid_product_ids_are_rejected_without_connection(self):
        for product_id in (0, -1, True, False, "5", 5.0, None, 4_294_967_296):
            with self.subTest(product_id=product_id):
                with self.assertRaises(RevenueValidationError):
                    self.service.get_product_transactions(
                        product_id, NOVEMBER_START, NOVEMBER_END
                    )
        self.assertEqual((FakeDatabase.opened, FakeDatabase.closed), (0, 0))

    def test_06_empty_list_means_success_not_database_error(self):
        with patch("src.model.revenue_service.RevenueDAO") as dao_class:
            dao_class.return_value.get_product_revenue_stats.return_value = []
            dao_class.return_value.get_product_transactions.return_value = []
            self.assertEqual(
                self.service.get_product_revenue_stats(
                    NOVEMBER_START, NOVEMBER_END
                ),
                [],
            )
            self.assertEqual(
                self.service.get_product_transactions(
                    5, NOVEMBER_START, NOVEMBER_END
                ),
                [],
            )
        self.assertEqual((FakeDatabase.opened, FakeDatabase.closed), (2, 2))

    def test_07_mysql_errors_from_both_dao_methods_are_wrapped(self):
        with patch("src.model.revenue_service.RevenueDAO") as dao_class:
            dao_class.return_value.get_product_revenue_stats.side_effect = MySQLError(
                "private database detail"
            )
            dao_class.return_value.get_product_transactions.side_effect = MySQLError(
                "private database detail"
            )
            with self.assertRaises(RevenueStorageError) as stats_error:
                self.service.get_product_revenue_stats(
                    NOVEMBER_START, NOVEMBER_END
                )
            with self.assertRaises(RevenueStorageError) as detail_error:
                self.service.get_product_transactions(
                    5, NOVEMBER_START, NOVEMBER_END
                )
        for error in (stats_error.exception, detail_error.exception):
            self.assertIsInstance(error.__cause__, MySQLError)
            self.assertNotIn("private database detail", str(error))
        self.assertEqual((FakeDatabase.opened, FakeDatabase.closed), (2, 2))

    def test_08_mysql_connection_error_is_wrapped(self):
        class BrokenDatabase:
            @classmethod
            @contextmanager
            def connection(cls):
                raise MySQLError("simulated connection failure")
                yield  # Generator cho contextmanager; không bao giờ chạy tới đây.

        service = RevenueService(database=BrokenDatabase)
        with self.assertRaises(RevenueStorageError) as error:
            service.get_product_revenue_stats(NOVEMBER_START, NOVEMBER_END)
        self.assertIsInstance(error.exception.__cause__, MySQLError)

    def test_09_connection_is_closed_even_when_dao_fails(self):
        with patch("src.model.revenue_service.RevenueDAO") as dao_class:
            dao_class.return_value.get_product_revenue_stats.side_effect = MySQLError(
                "fake failure"
            )
            with self.assertRaises(RevenueStorageError):
                self.service.get_product_revenue_stats(
                    NOVEMBER_START, NOVEMBER_END
                )
        self.assertEqual((FakeDatabase.opened, FakeDatabase.closed), (1, 1))


class GuardedRevenueDatabase(Database):
    """Chỉ cho DAO đọc khi SELECT DATABASE() của kết nối là qlst_test."""

    @classmethod
    @contextmanager
    def connection(cls):
        with super().connection() as connection:
            with connection.cursor() as cursor:
                cursor.execute("SELECT DATABASE() AS db_name")
                row = cursor.fetchone()
                if row is None or row["db_name"] != "qlst_test":
                    raise RuntimeError(
                        "SAFETY STOP: ket noi hien tai KHONG phai qlst_test"
                    )
            yield connection


@unittest.skipUnless(
    os.environ.get("RUN_REVENUE_DB_TESTS") == "1",
    "MySQL test disabled; set RUN_REVENUE_DB_TESTS=1 MYSQL_DATABASE=qlst_test",
)
class RevenueMySQLIntegrationTests(unittest.TestCase):
    """Chỉ đọc qlst_test, chỉ chạy khi người dùng bật cờ rõ ràng."""

    @classmethod
    def setUpClass(cls):
        # Chốt an toàn trước khi mở bất kỳ kết nối nào.
        if os.environ.get("MYSQL_DATABASE") != "qlst_test":
            raise RuntimeError(
                "SAFETY STOP: phai truyen MYSQL_DATABASE=qlst_test ro rang"
            )
        settings = DatabaseSettings.from_env()
        if (
            settings.database != "qlst_test"
            or settings.host != "127.0.0.1"
            or settings.port != 3307
            or settings.user.strip().lower() == "root"
        ):
            raise RuntimeError(
                "SAFETY STOP: cau hinh MySQL khong dung qlst_test / 127.0.0.1:3307"
            )
        cls.service = RevenueService(database=GuardedRevenueDatabase)
        cls.baseline = cls._counts()

    @staticmethod
    def _counts() -> tuple[int, ...]:
        """Đọc số bản ghi trước/sau để phát hiện thay đổi ngoài mong muốn."""
        with GuardedRevenueDatabase.connection() as connection:
            with connection.cursor() as cursor:
                cursor.execute(
                    """SELECT
                        (SELECT COUNT(*) FROM users) AS users_count,
                        (SELECT COUNT(*) FROM customers) AS customers_count,
                        (SELECT COUNT(*) FROM products) AS products_count,
                        (SELECT COUNT(*) FROM invoices) AS invoices_count,
                        (SELECT COUNT(*) FROM invoice_details) AS details_count,
                        (SELECT COUNT(*) FROM returns) AS returns_count
                    """
                )
                counts = cursor.fetchone()
                return tuple(counts.values())

    @classmethod
    def tearDownClass(cls):
        # Không xóa dữ liệu, chỉ chứng minh số dòng không tăng/giảm.
        if cls.baseline != cls._counts():
            raise AssertionError(
                "So luong ban ghi da thay doi khi test chi-doc; can kiem tra"
            )

    def test_01_october_product_revenues_match_accepted_seed(self):
        rows = self.service.get_product_revenue_stats(OCTOBER_START, OCTOBER_END)
        self.assertEqual(len(rows), 4)
        self.assertTrue(all(isinstance(row, ProductRevenue) for row in rows))
        self.assertEqual(
            {row.product_id: row.net_revenue for row in rows},
            {
                1: Decimal("63000000"),
                2: Decimal("28000000"),
                3: Decimal("13500000"),
                5: Decimal("2500000"),
            },
        )

    def test_02_november_negative_revenue_is_preserved(self):
        rows = self.service.get_product_revenue_stats(NOVEMBER_START, NOVEMBER_END)
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].product_id, 5)
        self.assertEqual(rows[0].quantity_sold, 0)
        self.assertEqual(rows[0].quantity_returned, 1)
        self.assertEqual(rows[0].net_quantity, -1)
        self.assertEqual(rows[0].net_revenue, Decimal("-500000"))
        self.assertIsInstance(rows[0].net_revenue, Decimal)

    def test_03_november_return_transaction_matches_seed(self):
        rows = self.service.get_product_transactions(
            5, NOVEMBER_START, NOVEMBER_END
        )
        self.assertEqual(len(rows), 1)
        transaction = rows[0]
        self.assertIsInstance(transaction, ProductTransaction)
        self.assertEqual(transaction.transaction_type, "return")
        self.assertEqual(transaction.document_code, "RET-2")
        self.assertEqual(transaction.return_id, 2)
        self.assertEqual(transaction.quantity_returned, 1)
        self.assertEqual(transaction.refund_amount, Decimal("500000"))
        self.assertEqual(transaction.net_revenue, Decimal("-500000"))
        self.assertIsInstance(transaction.transaction_at, datetime)
        self.assertIsNone(transaction.unit_id)

    def test_04_empty_date_range_returns_empty_list(self):
        self.assertEqual(
            self.service.get_product_revenue_stats(
                date(2020, 1, 1), date(2020, 1, 31)
            ),
            [],
        )
        self.assertEqual(
            self.service.get_product_transactions(
                5, date(2020, 1, 1), date(2020, 1, 31)
            ),
            [],
        )

    def test_05_dao_reuses_one_connection_after_multiple_calls(self):
        with GuardedRevenueDatabase.connection() as connection:
            dao = RevenueDAO(connection)
            october = dao.get_product_revenue_stats(OCTOBER_START, OCTOBER_END)
            november = dao.get_product_revenue_stats(
                NOVEMBER_START, NOVEMBER_END
            )
            details = dao.get_product_transactions(
                5, NOVEMBER_START, NOVEMBER_END
            )
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1 AS ok")
                self.assertEqual(cursor.fetchone()["ok"], 1)
        self.assertEqual(len(october), 4)
        self.assertEqual(len(november), 1)
        self.assertEqual(len(details), 1)

    def test_06_nonexistent_product_has_no_transactions(self):
        self.assertEqual(
            self.service.get_product_transactions(
                4_294_967_295, NOVEMBER_START, NOVEMBER_END
            ),
            [],
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
