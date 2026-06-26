import re

from app.core.exceptions import ValidationException

_INDIAN_MOBILE = re.compile(r"^[6-9]\d{9}$")


def normalize_mobile(raw: str) -> str:
    digits = re.sub(r"\D", "", raw or "")
    if digits.startswith("91") and len(digits) == 12:
        digits = digits[2:]
    if not _INDIAN_MOBILE.match(digits):
        raise ValidationException("Enter a valid 10-digit Indian mobile number.")
    return digits
