"""Connection factory cho DAO. KHONG viet SQL nghiep vu trong Controller."""
from __future__ import annotations

from contextlib import contextmanager
from collections.abc import Generator

import pymysql
from pymysql.connections import Connection
from pymysql.cursors import DictCursor

from src.config import DatabaseSettings


class Database:
    @staticmethod
    def open() -> Connection:
        s = DatabaseSettings.from_env()
        return pymysql.connect(
            host=s.host,
            port=s.port,
            user=s.user,
            password=s.password,
            database=s.database,
            charset="utf8mb4",
            cursorclass=DictCursor,
            autocommit=False,
            connect_timeout=s.connect_timeout,
        )

    @classmethod
    @contextmanager
    def connection(cls) -> Generator[Connection, None, None]:
        """Cho truy vấn chỉ đọc. Không tự động commit."""
        conn = cls.open()
        try:
            yield conn
        finally:
            conn.close()

    @classmethod
    @contextmanager
    def transaction(cls) -> Generator[Connection, None, None]:
        """DAO chia sẻ một connection: commit khi thành công, rollback khi lỗi."""
        conn = cls.open()
        try:
            yield conn
            conn.commit()
        except BaseException:
            conn.rollback()
            raise
        finally:
            conn.close()
