import logging
import sys
import structlog
from app.core.config import settings


def setup_logging() -> None:
    log_level = logging.DEBUG if settings.ENVIRONMENT == "development" else logging.INFO

    shared_processors = [
        structlog.contextvars.merge_contextvars,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
    ]

    structlog.configure(
        processors=shared_processors
        + [
            structlog.stdlib.ProcessorFormatter.wrap_for_formatter,
        ],
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )

    # Set up stdout handler
    handler = logging.StreamHandler(sys.stdout)

    # Choose formatter based on environment
    if settings.ENVIRONMENT == "production":
        formatter = structlog.stdlib.ProcessorFormatter(
            processor=structlog.processors.JSONRenderer(),
        )
    else:
        formatter = structlog.stdlib.ProcessorFormatter(
            processor=structlog.dev.ConsoleRenderer(),
        )

    handler.setFormatter(formatter)

    # Configure root logger
    root_logger = logging.getLogger()
    # Remove existing handlers to avoid duplicates
    for h in list(root_logger.handlers):
        root_logger.removeHandler(h)
    root_logger.addHandler(handler)
    root_logger.setLevel(log_level)

    # Suppress default handlers of libraries to prevent duplicate logging
    for logger_name in (
        "uvicorn",
        "uvicorn.error",
        "uvicorn.access",
        "sqlalchemy.engine",
    ):
        lib_logger = logging.getLogger(logger_name)
        lib_logger.handlers = []
        lib_logger.propagate = True

    # Ensure sqlalchemy engine logs at correct level if debug is enabled
    if settings.ENVIRONMENT == "development":
        logging.getLogger("sqlalchemy.engine").setLevel(logging.INFO)


# Export standard logger
logger = structlog.get_logger("ags-gold")
