from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.core.logging import setup_logging, logger
from app.core.exceptions import (
    AppException,
    app_exception_handler,
    general_exception_handler,
)
from app.middleware.logging_middleware import RequestLoggingMiddleware
from app.api.health import router as health_router
from app.database.session import verify_db_connection


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    setup_logging()
    logger.info("app_startup", message="Initializing AGS Gold API services...")

    db_connected = await verify_db_connection()
    if db_connected:
        logger.info(
            "db_connection_success",
            message="Database connection verified successfully.",
        )
    else:
        logger.warning(
            "db_connection_failed",
            message="Could not connect to database on startup. Please verify credentials/server status.",
        )

    yield

    # Shutdown
    logger.info("app_shutdown", message="Shutting down AGS Gold API services...")


app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    lifespan=lifespan,
)

# CORS configuration
cors_origins = settings.BACKEND_CORS_ORIGINS
if not cors_origins and settings.ENVIRONMENT == "development":
    cors_origins = ["*"]

if cors_origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[str(origin).strip("/") for origin in cors_origins],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

# Logging Middleware
app.add_middleware(RequestLoggingMiddleware)

# Exception Handlers
app.add_exception_handler(AppException, app_exception_handler)
app.add_exception_handler(Exception, general_exception_handler)

# Routers
# Mount health check endpoint directly at /health
app.include_router(health_router)
