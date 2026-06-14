import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.smoke


@pytest.mark.asyncio
async def test_customers_endpoint_requires_auth(db_client: AsyncClient):
    response = await db_client.get("/api/v1/customers/")
    assert response.status_code == 401
