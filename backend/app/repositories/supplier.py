from typing import Optional

from sqlalchemy import asc, desc, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.supplier import Supplier
from app.repositories.base import BaseRepository

SORT_COLUMNS = {
    "name": Supplier.name,
    "created_at": Supplier.created_at,
    "is_active": Supplier.is_active,
}


class SupplierRepository(BaseRepository[Supplier]):
    """Repository for Supplier queries."""

    def __init__(self, db_session: AsyncSession):
        super().__init__(Supplier, db_session)

    def _apply_filters(
        self,
        query,
        search: Optional[str] = None,
        is_active: Optional[bool] = None,
    ):
        query = query.where(Supplier.is_deleted.is_(False))
        if search:
            pattern = f"%{search}%"
            query = query.where(
                or_(
                    Supplier.name.ilike(pattern),
                    Supplier.contact_person.ilike(pattern),
                    Supplier.email.ilike(pattern),
                    Supplier.mobile_number.ilike(pattern),
                )
            )
        if is_active is not None:
            query = query.where(Supplier.is_active == is_active)
        return query

    def _apply_sort(self, query, sort_by: str, sort_order: str):
        column = SORT_COLUMNS.get(sort_by, Supplier.created_at)
        direction = asc if sort_order == "asc" else desc
        return query.order_by(direction(column))

    async def get_active(self, supplier_id) -> Optional[Supplier]:
        query = select(Supplier).where(
            Supplier.id == supplier_id,
            Supplier.is_deleted.is_(False),
        )
        result = await self.db.execute(query)
        return result.scalars().first()

    async def get_by_name(self, name: str) -> Optional[Supplier]:
        query = select(Supplier).where(
            Supplier.name == name,
            Supplier.is_deleted.is_(False),
        )
        result = await self.db.execute(query)
        return result.scalars().first()

    async def list_suppliers(
        self,
        skip: int = 0,
        limit: int = 100,
        search: Optional[str] = None,
        is_active: Optional[bool] = None,
        sort_by: str = "created_at",
        sort_order: str = "desc",
    ) -> list[Supplier]:
        limit = min(limit, 100)
        query = select(Supplier)
        query = self._apply_filters(query, search, is_active)
        query = self._apply_sort(query, sort_by, sort_order)
        query = query.offset(skip).limit(limit)
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def count_suppliers(
        self,
        search: Optional[str] = None,
        is_active: Optional[bool] = None,
    ) -> int:
        query = select(func.count(Supplier.id)).select_from(Supplier)
        query = self._apply_filters(query, search, is_active)
        result = await self.db.execute(query)
        return result.scalar() or 0

    async def count_linked_inventory_items(self, supplier_id) -> int:
        from app.models.inventory_item import InventoryItem

        query = (
            select(func.count(InventoryItem.id))
            .select_from(InventoryItem)
            .where(
                InventoryItem.supplier_id == supplier_id,
                InventoryItem.is_deleted.is_(False),
            )
        )
        result = await self.db.execute(query)
        return result.scalar() or 0
