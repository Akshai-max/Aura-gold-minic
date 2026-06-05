import asyncio
from typing import AsyncGenerator, Generator
import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import AsyncSession

from app.main import app
from app.database.session import get_db_session

# Mock database session for testing framework behavior
class MockAsyncSession:
    async def execute(self, *args, **kwargs):
        class MockResult:
            def scalars(self):
                class MockScalars:
                    def all(self):
                        return []
                return MockScalars()
            def all(self):
                return []
        return MockResult()

    async def commit(self):
        pass

    async def rollback(self):
        pass

    async def close(self):
        pass

    async def get(self, *args, **kwargs):
        return None

    def add(self, *args, **kwargs):
        pass

    async def delete(self, *args, **kwargs):
        pass

@pytest.fixture(scope="session")
def event_loop() -> Generator[asyncio.AbstractEventLoop, None, None]:
    """Create an instance of the default event loop for each test case."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest_asyncio.fixture
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    """Fixture yielding a mock database session."""
    yield MockAsyncSession()  # type: ignore

@pytest_asyncio.fixture
async def client(db_session: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    """Fixture yielding an AsyncClient configured to request against the FastAPI application."""
    # Override database dependency injection
    app.dependency_overrides[get_db_session] = lambda: db_session
    
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://testserver"
    ) as ac:
        yield ac
        
    app.dependency_overrides.clear()
ZOOM_TEST_ENV = True
