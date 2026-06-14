"""Shared client IP resolution with trusted-proxy support."""

from starlette.requests import Request

from app.core.config import settings


def resolve_client_ip(request: Request) -> str | None:
    """Resolve the client IP, honoring proxy headers only when configured."""
    if settings.TRUSTED_PROXY:
        forwarded = request.headers.get("x-forwarded-for")
        if forwarded:
            return forwarded.split(",")[0].strip()
        real_ip = request.headers.get("x-real-ip")
        if real_ip:
            return real_ip.strip()

    if request.client:
        return request.client.host
    return None
