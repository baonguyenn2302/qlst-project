"""Doc cau hinh moi truong. Khong luu mat khau MySQL trong code."""
from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv

PROJECT_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(PROJECT_ROOT / ".env", override=False)


@dataclass(frozen=True, slots=True)
class DatabaseSettings:
    host: str
    port: int
    user: str
    password: str
    database: str
    connect_timeout: int

    @classmethod
    def from_env(cls) -> "DatabaseSettings":
        user = os.getenv("MYSQL_USER", "").strip()
        password = os.getenv("MYSQL_PASSWORD", "")
        if not user:
            raise RuntimeError("Thieu MYSQL_USER trong .env")
        if not password:
            raise RuntimeError("Thieu MYSQL_PASSWORD trong .env")
        try:
            port = int(os.getenv("MYSQL_PORT", "3307"))
            timeout = int(os.getenv("MYSQL_CONNECT_TIMEOUT", "5"))
        except ValueError as exc:
            raise RuntimeError("MYSQL_PORT / MYSQL_CONNECT_TIMEOUT phai la so nguyen") from exc
        if not 1 <= port <= 65535 or timeout <= 0:
            raise RuntimeError("MYSQL_PORT hoac MYSQL_CONNECT_TIMEOUT khong hop le")
        return cls(
            host=os.getenv("MYSQL_HOST", "127.0.0.1"),
            port=port,
            user=user,
            password=password,
            database=os.getenv("MYSQL_DATABASE", "qlst"),
            connect_timeout=timeout,
        )


def get_flask_secret_key() -> str:
    key = os.getenv("FLASK_SECRET_KEY", "")
    if not key or key.startswith("CHANGE_ME"):
        raise RuntimeError("Can dat FLASK_SECRET_KEY ngau nhien trong .env")
    return key
