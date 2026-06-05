from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from app.core.config import settings

# Configure database pool and connection settings
engine = create_async_engine(
    settings.DATABASE_URL,
    echo=False,
    pool_pre_ping=True,
    pool_size=20,
    max_overflow=10,
    pool_recycle=1800,
)

# Async session factory
async_session_maker = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)

async def get_db_session() -> AsyncGenerator[AsyncSession, None]:
    """Dependency injection generator yielding an async database session."""
    async with async_session_maker() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
            
async def verify_db_connection() -> bool:
    """Helper to verify connection viability during startup checks."""
    try:
        from sqlalchemy import text
        async with async_session_maker() as session:
            await session.execute(text("SELECT 1"))
        return True
    except Exception:
        return False
