import base64
import hashlib

from cryptography.fernet import Fernet

from app.core.config import settings


def _fernet() -> Fernet:
    digest = hashlib.sha256(settings.SECRET_KEY.encode()).digest()
    key = base64.urlsafe_b64encode(digest)
    return Fernet(key)


def encrypt_aadhaar(aadhaar_number: str) -> str:
    return _fernet().encrypt(aadhaar_number.encode()).decode()


def decrypt_aadhaar(token: str) -> str:
    return _fernet().decrypt(token.encode()).decode()
