"""Smoke test tu may Mac: Python / Flask / MySQL / Argon2id.

Chay: python -m src.tests.check_environment
Khong ghi hay sua du lieu trong MySQL.
"""
from __future__ import annotations

import sys
import secrets
from importlib.metadata import version

from src.dao.db import Database
from src.model.password_service import PasswordService


def main() -> int:
    failures = 0
    print(f"Python: {sys.version.split()[0]}")
    if sys.version_info[:3] != (3, 14, 8):
        print("[WARN] Du an du kien Python 3.14.8; vui long kiem tra .venv")
    for package in ("Flask", "PyMySQL", "argon2-cffi", "python-dotenv"):
        print(f"Library {package}: {version(package)}")

    service = PasswordService()
    candidate = secrets.token_urlsafe(24)
    encoded = service.hash_password(candidate)
    valid = encoded.startswith("$argon2id$") and service.verify_password(candidate, encoded)
    invalid = not service.verify_password(candidate + "sai", encoded)
    if valid and invalid:
        print("[PASS] Argon2id: hash + verify dung/sai")
    else:
        print("[FAIL] Argon2id")
        failures += 1

    try:
        with Database.connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute("SELECT 1 AS ok, DATABASE() AS db_name")
                row = cursor.fetchone()
                ok = row["ok"] == 1 and row["db_name"] == "qlst"
                print(f"[{'PASS' if ok else 'FAIL'}] MySQL SELECT 1, database={row['db_name']}")
                failures += int(not ok)

                cursor.execute("""
                    SELECT COUNT(*) AS n
                    FROM information_schema.tables
                    WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE'
                """)
                n_tables = cursor.fetchone()["n"]
                print(f"[{'PASS' if n_tables == 29 else 'FAIL'}] So bang: {n_tables}/29")
                failures += int(n_tables != 29)

                cursor.execute("""
                    SELECT COUNT(*) AS n
                    FROM users WHERE password_hash LIKE '$argon2id$%'
                """)
                n_hashes = cursor.fetchone()["n"]
                print(f"[{'PASS' if n_hashes == 7 else 'FAIL'}] Tai khoan Argon2id: {n_hashes}/7")
                failures += int(n_hashes != 7)
    except Exception as exc:
        # Tuyet doi khong in MYSQL_PASSWORD hoac noi dung .env.
        print(f"[FAIL] Khong ket noi/kiem tra duoc MySQL: {type(exc).__name__}: {exc}")
        failures += 1

    print("KET LUAN:", "PASS" if failures == 0 else f"FAIL ({failures} muc)")
    return 0 if failures == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
