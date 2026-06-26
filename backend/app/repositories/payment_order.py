import uuid
from decimal import Decimal
from typing import Optional

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.payment_order import PaymentOrder
from app.repositories.base import BaseRepository


class PaymentOrderRepository(BaseRepository[PaymentOrder]):
    def __init__(self, db_session: AsyncSession):
        super().__init__(PaymentOrder, db_session)

    async def get_by_razorpay_order_id(
        self, razorpay_order_id: str
    ) -> Optional[PaymentOrder]:
        result = await self.db.execute(
            select(PaymentOrder).where(
                PaymentOrder.razorpay_order_id == razorpay_order_id
            )
        )
        return result.scalar_one_or_none()

    async def get_for_user(
        self, order_id: uuid.UUID, user_id: uuid.UUID
    ) -> Optional[PaymentOrder]:
        result = await self.db.execute(
            select(PaymentOrder).where(
                PaymentOrder.id == order_id,
                PaymentOrder.user_id == user_id,
            )
        )
        return result.scalar_one_or_none()

    async def list_paid_orders(
        self,
        skip: int = 0,
        limit: int = 50,
    ) -> list[PaymentOrder]:
        query = (
            select(PaymentOrder)
            .options(selectinload(PaymentOrder.user))
            .where(PaymentOrder.status == "paid")
            .order_by(PaymentOrder.paid_at.desc())
            .offset(skip)
            .limit(limit)
        )
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def count_paid_orders(self) -> int:
        result = await self.db.execute(
            select(func.count())
            .select_from(PaymentOrder)
            .where(PaymentOrder.status == "paid")
        )
        return int(result.scalar_one())
