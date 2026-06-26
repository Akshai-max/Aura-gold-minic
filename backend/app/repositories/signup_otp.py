from datetime import datetime, timezone

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.signup_otp import SignupOtpChallenge
from app.repositories.base import BaseRepository


class SignupOtpRepository(BaseRepository[SignupOtpChallenge]):
    def __init__(self, db_session: AsyncSession):
        super().__init__(SignupOtpChallenge, db_session)

    async def invalidate_pending(self, mobile_number: str) -> None:
        await self.db.execute(
            update(SignupOtpChallenge)
            .where(
                SignupOtpChallenge.mobile_number == mobile_number,
                SignupOtpChallenge.consumed.is_(False),
            )
            .values(consumed=True)
        )

    async def get_latest_active(
        self, mobile_number: str
    ) -> SignupOtpChallenge | None:
        now = datetime.now(timezone.utc)
        query = (
            select(SignupOtpChallenge)
            .where(
                SignupOtpChallenge.mobile_number == mobile_number,
                SignupOtpChallenge.consumed.is_(False),
                SignupOtpChallenge.expires_at > now,
            )
            .order_by(SignupOtpChallenge.created_at.desc())
            .limit(1)
        )
        result = await self.db.execute(query)
        return result.scalars().first()

    async def count_recent_sends(
        self, mobile_number: str, since: datetime
    ) -> int:
        from sqlalchemy import func

        query = select(func.count(SignupOtpChallenge.id)).where(
            SignupOtpChallenge.mobile_number == mobile_number,
            SignupOtpChallenge.created_at >= since,
        )
        result = await self.db.execute(query)
        return int(result.scalar() or 0)

    async def get_latest_send(
        self, mobile_number: str
    ) -> SignupOtpChallenge | None:
        query = (
            select(SignupOtpChallenge)
            .where(SignupOtpChallenge.mobile_number == mobile_number)
            .order_by(SignupOtpChallenge.created_at.desc())
            .limit(1)
        )
        result = await self.db.execute(query)
        return result.scalars().first()
