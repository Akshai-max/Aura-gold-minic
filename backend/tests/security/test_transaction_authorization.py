import uuid

import pytest
from httpx import AsyncClient

from tests.security.conftest import create_user_with_permissions

pytestmark = pytest.mark.security


@pytest.mark.asyncio
async def test_create_transaction_forbidden_without_create_permission(
    db_client: AsyncClient, test_db
):
    _, headers = await create_user_with_permissions(test_db, ["transaction.view"])

    response = await db_client.post(
        "/api/v1/transactions/",
        headers=headers,
        json={
            "transaction_type": "purchase",
            "payment_status": "pending",
            "lines": [
                {
                    "inventory_item_id": str(uuid.uuid4()),
                    "quantity": 1,
                    "unit_price": "100.00",
                }
            ],
        },
    )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_viewer_can_access_metrics(db_client: AsyncClient, test_db):
    _, headers = await create_user_with_permissions(test_db, ["transaction.view"])

    response = await db_client.get("/api/v1/transactions/metrics", headers=headers)
    assert response.status_code == 200
