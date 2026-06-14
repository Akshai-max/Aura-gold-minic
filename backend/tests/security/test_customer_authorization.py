import pytest
from httpx import AsyncClient

from tests.security.conftest import create_user_with_permissions

pytestmark = pytest.mark.security


@pytest.mark.asyncio
async def test_customer_view_allowed_with_permission(db_client: AsyncClient, test_db):
    _, headers = await create_user_with_permissions(test_db, ["customer.view"])

    response = await db_client.get("/api/v1/customers/", headers=headers)
    assert response.status_code == 200


@pytest.mark.asyncio
async def test_customer_create_forbidden_without_permission(
    db_client: AsyncClient, test_db
):
    _, headers = await create_user_with_permissions(test_db, ["customer.view"])

    response = await db_client.post(
        "/api/v1/customers/",
        json={
            "customer_type": "individual",
            "full_name": "Blocked User",
            "mobile_number": "+919876543210",
            "email": "blocked@example.com",
            "address": "Nowhere",
        },
        headers=headers,
    )
    assert response.status_code == 403
    assert "customer.create" in response.json()["error"]["message"].lower()


@pytest.mark.asyncio
async def test_customer_list_forbidden_without_view(db_client: AsyncClient, test_db):
    _, headers = await create_user_with_permissions(test_db, ["customer.create"])

    response = await db_client.get("/api/v1/customers/", headers=headers)
    assert response.status_code == 403
