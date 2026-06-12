import uuid

import pytest
from decimal import Decimal
from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories.inventory_item import InventoryItemRepository
from app.repositories.stock_movement import StockMovementRepository
from app.repositories.supplier import SupplierRepository

pytestmark = pytest.mark.integration


@pytest.mark.asyncio
async def test_inventory_repository_metrics_and_low_stock(test_db: AsyncSession):
    supplier_repo = SupplierRepository(test_db)
    inventory_repo = InventoryItemRepository(test_db)

    supplier = await supplier_repo.create(
        {"name": f"Supplier_{uuid.uuid4().hex[:6]}", "is_active": True},
        commit=True,
    )

    await inventory_repo.create(
        {
            "item_name": "Low Stock Bar",
            "item_category": "gold_bar",
            "weight": Decimal("10"),
            "purity": Decimal("99.9"),
            "purchase_price": Decimal("50000"),
            "current_value": Decimal("55000"),
            "stock_quantity": 2,
            "reorder_level": 5,
            "supplier_id": supplier.id,
            "status": "active",
        },
        commit=True,
    )
    await inventory_repo.create(
        {
            "item_name": "Healthy Stock Coin",
            "item_category": "gold_coin",
            "weight": Decimal("5"),
            "purity": Decimal("91.6"),
            "purchase_price": Decimal("25000"),
            "current_value": Decimal("27000"),
            "stock_quantity": 50,
            "reorder_level": 10,
            "status": "active",
        },
        commit=True,
    )

    metrics = await inventory_repo.get_metrics()
    assert metrics["total_stock"] == 52
    assert metrics["low_stock_count"] == 1

    low_stock = await inventory_repo.list_low_stock(limit=5)
    assert len(low_stock) == 1
    assert low_stock[0].item_name == "Low Stock Bar"


@pytest.mark.asyncio
async def test_stock_movement_repository_list_for_item(test_db: AsyncSession):
    inventory_repo = InventoryItemRepository(test_db)
    movement_repo = StockMovementRepository(test_db)

    item = await inventory_repo.create(
        {
            "item_name": "Movement Test",
            "item_category": "raw_gold",
            "weight": Decimal("100"),
            "purity": Decimal("99.5"),
            "purchase_price": Decimal("100000"),
            "current_value": Decimal("105000"),
            "stock_quantity": 0,
            "reorder_level": 5,
            "status": "active",
        },
        commit=True,
    )

    await movement_repo.create(
        {
            "inventory_item_id": item.id,
            "movement_type": "stock_in",
            "quantity_change": 10,
            "quantity_before": 0,
            "quantity_after": 10,
        },
        commit=True,
    )

    movements = await movement_repo.list_for_item(item.id)
    assert len(movements) == 1
    assert movements[0].movement_type == "stock_in"
