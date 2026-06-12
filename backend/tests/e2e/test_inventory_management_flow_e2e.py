import uuid

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from tests.e2e.conftest import bearer_headers, login

pytestmark = pytest.mark.e2e


@pytest.mark.asyncio
async def test_inventory_crud_and_stock_flow(
    db_client: AsyncClient,
    test_db: AsyncSession,
    admin_actor: tuple,
):
    admin_user, password = admin_actor
    tokens = await login(db_client, admin_user.email, password)
    headers = bearer_headers(tokens["access_token"])

    supplier_resp = await db_client.post(
        "/api/v1/suppliers/",
        headers=headers,
        json={"name": f"Supplier_{uuid.uuid4().hex[:6]}"},
    )
    assert supplier_resp.status_code == 201, supplier_resp.text
    supplier_id = supplier_resp.json()["id"]

    create_resp = await db_client.post(
        "/api/v1/inventory/",
        headers=headers,
        json={
            "item_name": "E2E Gold Bar",
            "item_category": "gold_bar",
            "weight": "10.0000",
            "purity": "99.900",
            "purchase_price": "50000.00",
            "current_value": "55000.00",
            "stock_quantity": 5,
            "reorder_level": 10,
            "supplier_id": supplier_id,
            "status": "active",
        },
    )
    assert create_resp.status_code == 201, create_resp.text
    item = create_resp.json()
    item_id = item["id"]
    assert item["is_low_stock"] is True

    movements_after_create = await db_client.get(
        f"/api/v1/inventory/{item_id}/movements",
        headers=headers,
    )
    assert movements_after_create.status_code == 200
    assert movements_after_create.json()["total"] >= 1

    stock_in = await db_client.post(
        f"/api/v1/inventory/{item_id}/stock-in",
        headers=headers,
        json={"quantity": 10, "reference": "PO-E2E"},
    )
    assert stock_in.status_code == 200, stock_in.text
    assert stock_in.json()["stock_quantity"] == 15

    stock_out = await db_client.post(
        f"/api/v1/inventory/{item_id}/stock-out",
        headers=headers,
        json={"quantity": 3, "reference": "SALE-E2E"},
    )
    assert stock_out.status_code == 200, stock_out.text
    assert stock_out.json()["stock_quantity"] == 12

    adjust = await db_client.post(
        f"/api/v1/inventory/{item_id}/stock-adjust",
        headers=headers,
        json={"new_quantity": 8, "reason": "Count correction"},
    )
    assert adjust.status_code == 200, adjust.text
    assert adjust.json()["stock_quantity"] == 8

    movements = await db_client.get(
        f"/api/v1/inventory/{item_id}/movements",
        headers=headers,
    )
    assert movements.status_code == 200
    assert movements.json()["total"] >= 3

    metrics = await db_client.get("/api/v1/inventory/metrics", headers=headers)
    assert metrics.status_code == 200
    assert metrics.json()["total_stock"] >= 8

    delete_resp = await db_client.delete(
        f"/api/v1/inventory/{item_id}",
        headers=headers,
    )
    assert delete_resp.status_code == 200
