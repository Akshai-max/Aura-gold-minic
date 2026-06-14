import uuid
from typing import Optional

from sqlalchemy import desc, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.stock_movement import StockMovement
from app.repositories.base import BaseRepository


class StockMovementRepository(BaseRepository[StockMovement]):
    """Repository for immutable stock movement ledger."""

    def __init__(self, db_session: AsyncSession):
        super().__init__(StockMovement, db_session)

    async def list_for_item(
        self,
        inventory_item_id: uuid.UUID,
        skip: int = 0,
        limit: int = 50,
    ) -> list[StockMovement]:
        limit = min(limit, 100)
        query = (
            select(StockMovement)
            .options(selectinload(StockMovement.inventory_item))
            .where(StockMovement.inventory_item_id == inventory_item_id)
            .order_by(desc(StockMovement.created_at))
            .offset(skip)
            .limit(limit)
        )
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def count_for_item(self, inventory_item_id: uuid.UUID) -> int:
        query = (
            select(func.count(StockMovement.id))
            .select_from(StockMovement)
            .where(StockMovement.inventory_item_id == inventory_item_id)
        )
        result = await self.db.execute(query)
        return result.scalar() or 0

    async def list_movements(
        self,
        skip: int = 0,
        limit: int = 50,
        inventory_item_id: Optional[uuid.UUID] = None,
        movement_type: Optional[str] = None,
    ) -> list[StockMovement]:
        limit = min(limit, 100)
        query = select(StockMovement).options(
            selectinload(StockMovement.inventory_item)
        )
        if inventory_item_id is not None:
            query = query.where(StockMovement.inventory_item_id == inventory_item_id)
        if movement_type is not None:
            query = query.where(StockMovement.movement_type == movement_type)
        query = query.order_by(desc(StockMovement.created_at)).offset(skip).limit(limit)
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def count_movements(
        self,
        inventory_item_id: Optional[uuid.UUID] = None,
        movement_type: Optional[str] = None,
    ) -> int:
        query = select(func.count(StockMovement.id)).select_from(StockMovement)
        if inventory_item_id is not None:
            query = query.where(StockMovement.inventory_item_id == inventory_item_id)
        if movement_type is not None:
            query = query.where(StockMovement.movement_type == movement_type)
        result = await self.db.execute(query)
        return result.scalar() or 0
