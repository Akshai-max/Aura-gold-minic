import base64
import pytest

from app.core.avatar import validate_and_encode_avatar
from app.core.exceptions import ValidationException

# 1x1 PNG
_TINY_PNG = base64.b64encode(
    bytes.fromhex(
        "89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c489"
        "0000000a49444154789c63000100000500010d0a2db40000000049454e44ae426082"
    )
).decode()


def test_validate_tiny_png():
    result, content_type = validate_and_encode_avatar(_TINY_PNG, "image/png")
    assert content_type == "image/png"
    assert len(result) > 0


def test_reject_invalid_base64():
    with pytest.raises(ValidationException):
        validate_and_encode_avatar("not-valid-base64!!!", "image/png")


def test_reject_magic_byte_mismatch():
    with pytest.raises(ValidationException):
        validate_and_encode_avatar(_TINY_PNG, "image/jpeg")
