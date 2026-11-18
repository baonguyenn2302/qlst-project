"""Integration tests for Module 1 RegistrationService on qlst_test ONLY.

Run from qlst-project:
    MYSQL_DATABASE=qlst_test python -m unittest -v src.tests.test_registration

SAFETY:
- No DROP, TRUNCATE, schema reset, or seed reload.
- Requires explicit MYSQL_DATABASE=qlst_test and a non-root app connection.
- Checks SELECT DATABASE() on every connection before any DML.
- Successful registrations use randomly tagged names and are cleaned up by exact
  matching username + phone + IDs, in customers-then-users FK order.
- All SQL is in this integration test, never in RegistrationService.
"""
from __future__ import annotations

import os
import secrets
import unittest
from collections.abc import Generator
from contextlib import contextmanager
from datetime import timedelta
from typing import Any
from unittest.mock import patch

from pymysql.connections import Connection

from src.config import DatabaseSettings
from src.dao.customer_dao import CustomerDAO
from src.dao.db import Database
from src.dao.user_dao import UserDAO
from src.model.password_service import PasswordService
from src.model.registration_service import (
    AlreadyRegisteredError,
    GuestVerificationRequiredError,
    RegistrationService,
    RegistrationStorageError,
    RegistrationValidationError,
    UsernameAlreadyExistsError,
)

EXPECTED_DATABASE = "qlst_test"
EXPECTED_HOST = "127.0.0.1"
EXPECTED_PORT = 3307
TAG_PREFIX = "it_reg_"
TEST_PASSWORD = "KiemThu@2026!"


def _check_configuration() -> None:
    """Fail closed before opening any connection when run against the wrong DB."""
    explicit_db = os.environ.get("MYSQL_DATABASE")
    if explicit_db != EXPECTED_DATABASE:
        raise RuntimeError(
            "SAFETY STOP: run with MYSQL_DATABASE=qlst_test explicitly; "
            "never run integration writes against qlst."
        )
    settings = DatabaseSettings.from_env()
    if settings.database != EXPECTED_DATABASE:
        raise RuntimeError("SAFETY STOP: effective database is not qlst_test")
    if settings.host != EXPECTED_HOST or settings.port != EXPECTED_PORT:
        raise RuntimeError("SAFETY STOP: expected MySQL Docker at 127.0.0.1:3307")
    if settings.user.lower() == "root":
        raise RuntimeError("SAFETY STOP: use the limited-permission app user, not root")


def _check_connection(conn: Connection) -> None:
    """Verify actual server-side default schema, not just configuration text."""
    with conn.cursor() as cursor:
        cursor.execute("SELECT DATABASE() AS db_name")
        row = cursor.fetchone()
    if row is None or row["db_name"] != EXPECTED_DATABASE:
        raise RuntimeError("SAFETY STOP: MySQL connection is not using qlst_test")


@contextmanager
def _read_connection() -> Generator[Connection, None, None]:
    _check_configuration()
    with Database.connection() as conn:
        _check_connection(conn)
        yield conn


class GuardedTestDatabase(Database):
    """Injectable Database: verify each transaction's actual target before DML."""

    @classmethod
    @contextmanager
    def transaction(cls) -> Generator[Connection, None, None]:
        _check_configuration()
        with super().transaction() as conn:
            _check_connection(conn)
            yield conn


def _number_of_rows(table: str) -> int:
    # Fixed allowlist only; table identifiers cannot be user-supplied.
    if table not in {"users", "customers"}:
        raise ValueError("Unsupported table")
    with _read_connection() as conn:
        with conn.cursor() as cursor:
            cursor.execute(f"SELECT COUNT(*) AS n FROM {table}")
            return int(cursor.fetchone()["n"])


def _rows_for_identity(username: str, phone: str) -> tuple[list[dict], list[dict]]:
    with _read_connection() as conn:
        with conn.cursor() as cursor:
            cursor.execute(
                "SELECT user_id, username, password_hash, role_id, created_at "
                "FROM users WHERE username = %s",
                (username,),
            )
            users = list(cursor.fetchall())
            cursor.execute(
                "SELECT customer_id, user_id, full_name, phone, registered_at, "
                "member_since, loyalty_points "
                "FROM customers WHERE phone = %s",
                (phone,),
            )
            customers = list(cursor.fetchall())
    return users, customers


def _fresh_identity() -> tuple[str, str]:
    """Create a uniquely tagged username and a valid, unused VN phone number."""
    for _ in range(30):
        username = TAG_PREFIX + secrets.token_hex(6)
        phone = "09" + f"{secrets.randbelow(10**8):08d}"
        users, customers = _rows_for_identity(username, phone)
        if not users and not customers:
            return username, phone
    raise RuntimeError("Cannot find an unused test identity")


def _cleanup_owned_identity(username: str, phone: str) -> None:
    """Delete only records belonging to THIS test's unique identity.

    Never delete a seed customer: require test prefix, exact username/phone,
    and matching foreign-key relationship before deleting anything.
    """
    if not username.startswith(TAG_PREFIX) or len(phone) != 10 or not phone.isdigit():
        raise RuntimeError("SAFETY STOP: refused cleanup of untagged identity")

    with GuardedTestDatabase.transaction() as conn:
        with conn.cursor() as cursor:
            cursor.execute(
                "SELECT user_id FROM users WHERE username = %s FOR UPDATE",
                (username,),
            )
            user_rows = list(cursor.fetchall())
            cursor.execute(
                "SELECT customer_id, user_id FROM customers "
                "WHERE phone = %s FOR UPDATE",
                (phone,),
            )
            customer_rows = list(cursor.fetchall())

            if len(user_rows) > 1 or len(customer_rows) > 1:
                raise RuntimeError("Unexpected duplicate test identity: no cleanup")
            user = user_rows[0] if user_rows else None
            customer = customer_rows[0] if customer_rows else None

            if customer and (not user or customer["user_id"] != user["user_id"]):
                raise RuntimeError(
                    "Test phone points to another account: no cleanup attempted"
                )

            if customer:
                cursor.execute(
                    "DELETE FROM customers WHERE customer_id = %s "
                    "AND user_id = %s AND phone = %s",
                    (customer["customer_id"], user["user_id"], phone),
                )
                if cursor.rowcount != 1:
                    raise AssertionError("Cleanup failed to delete test customer")

            if user:
                cursor.execute(
                    "DELETE FROM users WHERE user_id = %s AND username = %s",
                    (user["user_id"], username),
                )
                if cursor.rowcount != 1:
                    raise AssertionError("Cleanup failed to delete test user")


def _guest_snapshot(phone: str) -> dict[str, Any]:
    with _read_connection() as conn:
        with conn.cursor() as cursor:
            cursor.execute(
                "SELECT customer_id, user_id, full_name, phone, "
                "registered_at, member_since, loyalty_points, is_active "
                "FROM customers WHERE phone = %s",
                (phone,),
            )
            row = cursor.fetchone()
    if row is None:
        raise AssertionError(f"Missing seed customer for phone {phone}")
    return dict(row)


class RegistrationIntegrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        _check_configuration()
        with _read_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute(
                    "SELECT COUNT(*) AS n FROM information_schema.TABLES "
                    "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_TYPE = 'BASE TABLE'"
                )
                if cursor.fetchone()["n"] != 29:
                    raise RuntimeError("SAFETY STOP: qlst_test does not have 29 tables")
                cursor.execute(
                    "SELECT COUNT(*) AS n FROM information_schema.TABLE_CONSTRAINTS "
                    "WHERE CONSTRAINT_SCHEMA = DATABASE() AND CONSTRAINT_TYPE = 'CHECK' "
                    "AND ENFORCED = 'YES' "
                    "AND CONSTRAINT_NAME IN "
                    "('chk_customers_membership', 'chk_customers_member_date')"
                )
                if cursor.fetchone()["n"] != 2:
                    raise RuntimeError("SAFETY STOP: expected customers CHECKs absent")
                cursor.execute(
                    "SELECT COUNT(*) AS n FROM information_schema.TABLE_CONSTRAINTS "
                    "WHERE CONSTRAINT_SCHEMA = DATABASE() AND "
                    "((TABLE_NAME = 'users' AND CONSTRAINT_NAME = 'uq_users_username') "
                    "OR (TABLE_NAME = 'customers' AND CONSTRAINT_NAME = 'uq_customers_phone')) "
                    "AND CONSTRAINT_TYPE = 'UNIQUE'"
                )
                if cursor.fetchone()["n"] != 2:
                    raise RuntimeError("SAFETY STOP: expected UNIQUE constraints absent")
                cursor.execute(
                    "SELECT COUNT(*) AS n FROM information_schema.TABLE_CONSTRAINTS "
                    "WHERE CONSTRAINT_SCHEMA = DATABASE() AND "
                    "TABLE_NAME = 'customers' AND CONSTRAINT_NAME = 'fk_customers_user' "
                    "AND CONSTRAINT_TYPE = 'FOREIGN KEY'"
                )
                if cursor.fetchone()["n"] != 1:
                    raise RuntimeError("SAFETY STOP: customers->users FK is absent")

        cls.original_user_count = _number_of_rows("users")
        cls.original_customer_count = _number_of_rows("customers")
        if (cls.original_user_count, cls.original_customer_count) != (7, 3):
            raise RuntimeError(
                "SAFETY STOP: expected untouched seed (7 users, 3 customers)"
            )
        cls.service = RegistrationService(database=GuardedTestDatabase)
        cls.password_service = PasswordService()

    @classmethod
    def tearDownClass(cls) -> None:
        # Each successful write should have been cleaned up by unittest cleanup.
        if (_number_of_rows("users"), _number_of_rows("customers")) != (
            cls.original_user_count,
            cls.original_customer_count,
        ):
            raise AssertionError("qlst_test row counts changed after tests; inspect tagged data")

    def test_01_new_customer_commit_argon2_link(self) -> None:
        username, phone = _fresh_identity()
        self.addCleanup(_cleanup_owned_identity, username, phone)
        result = self.service.register(
            full_name="  Khách   Kiểm   Thử  ",
            phone="+84" + phone[1:],
            username=username,
            password=TEST_PASSWORD,
            email="integration@example.test",
            address="Hà Nội",
        )
        users, customers = _rows_for_identity(username, phone)
        self.assertEqual(len(users), 1, "COMMIT must persist exactly one user")
        self.assertEqual(len(customers), 1, "COMMIT must persist exactly one customer")
        user, customer = users[0], customers[0]
        self.assertEqual(result.user_id, user["user_id"])
        self.assertEqual(result.customer_id, customer["customer_id"])
        self.assertEqual(customer["user_id"], user["user_id"])
        self.assertEqual(customer["phone"], phone)
        self.assertEqual(customer["full_name"], "Khách Kiểm Thử")
        self.assertEqual(user["created_at"], customer["registered_at"])
        self.assertEqual(customer["registered_at"], customer["member_since"])
        self.assertEqual(result.member_since, customer["member_since"])
        self.assertEqual(customer["loyalty_points"], 0)
        self.assertTrue(user["password_hash"].startswith("$argon2id$"))
        self.assertNotEqual(user["password_hash"], TEST_PASSWORD)
        self.assertTrue(
            self.password_service.verify_password(TEST_PASSWORD, user["password_hash"])
        )
        print("PASS TC01: New registration, FK, Argon2id, and committed rows")

    def test_02_duplicate_username_rejected(self) -> None:
        _, phone = _fresh_identity()
        before = (_number_of_rows("users"), _number_of_rows("customers"))
        with self.assertRaises(UsernameAlreadyExistsError):
            self.service.register(
                full_name="Trùng tài khoản", phone=phone,
                username="khachhang01", password=TEST_PASSWORD,
            )
        self.assertEqual(_rows_for_identity("__nonexistent_test_user__", phone)[1], [])
        self.assertEqual(before, (_number_of_rows("users"), _number_of_rows("customers")))
        print("PASS TC02: Duplicate username rejected without writes")

    def test_03_guest_requires_otp_and_stays_unchanged(self) -> None:
        username, _ = _fresh_identity()
        guest_phone = "0903456789"
        before = _guest_snapshot(guest_phone)
        with self.assertRaises(GuestVerificationRequiredError):
            self.service.register(
                full_name="Khách vãng lai", phone=guest_phone,
                username=username, password=TEST_PASSWORD,
            )
        self.assertEqual(before, _guest_snapshot(guest_phone))
        users, _ = _rows_for_identity(username, guest_phone)
        self.assertEqual(users, [])
        print("PASS TC03: Guest recognized; no linking before OTP")

    def test_04_member_already_registered(self) -> None:
        username, _ = _fresh_identity()
        member_phone = "0901234567"
        before = _guest_snapshot(member_phone)
        with self.assertRaises(AlreadyRegisteredError):
            self.service.register(
                full_name="Thành viên cũ", phone=member_phone,
                username=username, password=TEST_PASSWORD,
            )
        self.assertEqual(before, _guest_snapshot(member_phone))
        users, _ = _rows_for_identity(username, member_phone)
        self.assertEqual(users, [])
        print("PASS TC04: Existing member rejected; data unchanged")

    def test_05_rollback_when_customer_check_fails(self) -> None:
        username, phone = _fresh_identity()
        self.addCleanup(_cleanup_owned_identity, username, phone)
        original_create = CustomerDAO.create

        def insert_invalid_customer(dao: CustomerDAO, **kwargs: Any):
            # UserDAO has inserted into the SAME transaction. Make MySQL
            # reject the next INSERT through chk_customers_member_date.
            invalid = dict(kwargs)
            invalid["member_since"] = invalid["registered_at"] - timedelta(days=1)
            return original_create(dao, **invalid)

        with patch.object(CustomerDAO, "create", new=insert_invalid_customer):
            with self.assertRaises(RegistrationStorageError):
                self.service.register(
                    full_name="Rollback CHECK", phone=phone,
                    username=username, password=TEST_PASSWORD,
                )
        users, customers = _rows_for_identity(username, phone)
        self.assertEqual(users, [], "User insert must roll back")
        self.assertEqual(customers, [], "Invalid customer must not persist")
        print("PASS TC05: Real MySQL CHECK failure rolls back user INSERT")

    def test_06_rollback_when_user_insert_fails(self) -> None:
        username, phone = _fresh_identity()
        self.addCleanup(_cleanup_owned_identity, username, phone)
        original_create = UserDAO.create

        def insert_duplicate_user(dao: UserDAO, **kwargs: Any):
            # Force a real MySQL UNIQUE 1062 *during* the insert, bypassing
            # the earlier pre-check in a controlled test-only patch.
            invalid = dict(kwargs)
            invalid["username"] = "khachhang01"
            return original_create(dao, **invalid)

        with patch.object(UserDAO, "create", new=insert_duplicate_user):
            with self.assertRaises(UsernameAlreadyExistsError):
                self.service.register(
                    full_name="Rollback UNIQUE", phone=phone,
                    username=username, password=TEST_PASSWORD,
                )
        self.assertEqual(_rows_for_identity(username, phone), ([], []))
        print("PASS TC06: Real MySQL UNIQUE failure leaves no new rows")

    def test_07_same_phone_cannot_register_twice(self) -> None:
        username, phone = _fresh_identity()
        self.addCleanup(_cleanup_owned_identity, username, phone)
        self.service.register(
            full_name="Chỉ một thành viên", phone=phone,
            username=username, password=TEST_PASSWORD,
        )
        other_username = TAG_PREFIX + secrets.token_hex(6)
        with self.assertRaises(AlreadyRegisteredError):
            self.service.register(
                full_name="Đăng ký lần hai", phone=phone,
                username=other_username, password=TEST_PASSWORD,
            )
        users, customers = _rows_for_identity(username, phone)
        self.assertEqual(len(users), 1)
        self.assertEqual(len(customers), 1)
        with _read_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute("SELECT COUNT(*) AS n FROM users WHERE username = %s", (other_username,))
                self.assertEqual(cursor.fetchone()["n"], 0)
        print("PASS TC07: Duplicate phone cannot create a second account")

    def test_08_invalid_input_no_writes(self) -> None:
        username, phone = _fresh_identity()
        before = (_number_of_rows("users"), _number_of_rows("customers"))
        with self.assertRaises(RegistrationValidationError):
            self.service.register(
                full_name="   ", phone=phone,
                username=username, password=TEST_PASSWORD,
            )
        with self.assertRaises(RegistrationValidationError):
            self.service.register(
                full_name="Khách", phone="not-a-phone",
                username=username, password=TEST_PASSWORD,
            )
        self.assertEqual(before, (_number_of_rows("users"), _number_of_rows("customers")))
        self.assertEqual(_rows_for_identity(username, phone), ([], []))
        print("PASS TC08: Invalid input rejected before database writes")


if __name__ == "__main__":
    unittest.main(verbosity=2)
