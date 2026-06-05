import time
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from app.core.logging import logger

SENSITIVE_KEYS = {"password", "token", "secret", "api_key", "key", "authorization"}

def sanitize_params(params: dict) -> dict:
    """Mask sensitive query parameters to prevent credentials leaks in logs."""
    return {
        k: "***" if any(s in k.lower() for s in SENSITIVE_KEYS) else v
        for k, v in params.items()
    }

class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """Middleware to log details of every incoming request and outgoing response."""
    
    async def dispatch(self, request: Request, call_next):
        start_time = time.perf_counter()
        
        method = request.method
        path = request.url.path
        query_params = sanitize_params(dict(request.query_params))
        
        logger.info(
            "request_started",
            method=method,
            path=path,
            query_params=query_params,
        )
        
        try:
            response = await call_next(request)
            process_time = time.perf_counter() - start_time
            
            logger.info(
                "request_completed",
                method=method,
                path=path,
                status_code=response.status_code,
                duration_ms=round(process_time * 1000, 2),
            )
            return response
        except Exception as e:
            process_time = time.perf_counter() - start_time
            logger.exception(
                "request_failed",
                method=method,
                path=path,
                duration_ms=round(process_time * 1000, 2),
                error=str(e),
            )
            raise
