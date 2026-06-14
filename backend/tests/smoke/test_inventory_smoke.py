import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.smoke


@pytest.mark.asyncio
async def test_inventory_routes_registered(client: AsyncClient):
    response = await client.get("/api/v1/inventory/")
    assert response.status_code in (401, 403)


@pytest.mark.asyncio
async def test_supplier_routes_registered(client: AsyncClient):
    response = await client.get("/api/v1/suppliers/")
    assert response.status_code in (401, 403)


@pytest.mark.asyncio
async def test_inventory_metrics_route_registered(client: AsyncClient):
    response = await client.get("/api/v1/inventory/metrics")
    assert response.status_code in (401, 403)
