"""Hash va xac minh password bang Argon2id (khong tu luu plain text)."""
from __future__ import annotations

from argon2 import PasswordHasher, Type
from argon2.exceptions import InvalidHashError, VerificationError, VerifyMismatchError

class PasswordService:
    def __init__(self) -> None:
        self._hasher = PasswordHasher(type=Type.ID)

    def hash_password(self, plaintext: str) -> str:
        return self._hasher.hash(plaintext)

    def verify_password(self, plaintext: str, encoded_hash: str) -> bool:
        try:
            return bool(self._hasher.verify(encoded_hash, plaintext))
        except (VerifyMismatchError, VerificationError, InvalidHashError):
            return False

    def needs_rehash(self, encoded_hash: str) -> bool:
        return self._hasher.check_needs_rehash(encoded_hash)