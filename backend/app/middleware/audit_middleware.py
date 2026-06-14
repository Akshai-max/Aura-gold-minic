import contextvars
from typing import Optional
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware

from app.core.client_ip import resolve_client_ip

# Context variables to hold request client metadata within async execution chains
client_ip_ctx: contextvars.ContextVar[Optional[str]] = contextvars.ContextVar(
    "client_ip", default=None
)
user_agent_ctx: contextvars.ContextVar[Optional[str]] = contextvars.ContextVar(
    "user_agent", default=None
)


class AuditRequestContextMiddleware(BaseHTTPMiddleware):
    """Middleware capturing request host metadata (IP, user agent) into context variables."""

    async def dispatch(self, request: Request, call_next):
        ip = resolve_client_ip(request)
        ua = request.headers.get("user-agent")

        token_ip = client_ip_ctx.set(ip)
        token_ua = user_agent_ctx.set(ua)

        try:
            return await call_next(request)
        finally:
            client_ip_ctx.reset(token_ip)
            user_agent_ctx.reset(token_ua)
