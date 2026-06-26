from decimal import Decimal
from typing import Any, Optional
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.referral_reward import ReferralReward
from app.repositories.base import BaseRepository


class ReferralRewardRepository(BaseRepository[ReferralReward]):
    def __init__(self, db_session: AsyncSession):
        super().__init__(ReferralReward, db_session)

    async def get_for_pair(
        self, referrer_id: UUID, referee_id: UUID
    ) -> Optional[ReferralReward]:
        query = select(ReferralReward).where(
            ReferralReward.referrer_id == referrer_id,
            ReferralReward.referee_id == referee_id,
        )
        result = await self.db.execute(query)
        return result.scalars().first()

    async def list_for_referrer(
        self, referrer_id: UUID, *, limit: int = 10
    ) -> list[ReferralReward]:
        query = (
            select(ReferralReward)
            .where(ReferralReward.referrer_id == referrer_id)
            .order_by(ReferralReward.created_at.desc())
            .limit(limit)
        )
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def count_and_sum_for_referrer(
        self, referrer_id: UUID
    ) -> tuple[int, Decimal]:
        query = select(
            func.count(ReferralReward.id),
            func.coalesce(func.sum(ReferralReward.reward_inr), 0),
        ).where(ReferralReward.referrer_id == referrer_id)
        result = await self.db.execute(query)
        row = result.one()
        return int(row[0] or 0), Decimal(str(row[1] or 0))
