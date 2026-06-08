import uuid
from typing import Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user_settings import UserSettings
from app.repositories.base import BaseRepository


class UserSettingsRepository(BaseRepository[UserSettings]):
    """Repository class handling query logic for UserSettings model."""

    def __init__(self, db_session: AsyncSession):
        super().__init__(UserSettings, db_session)

    async def get_by_user_id(self, user_id: uuid.UUID) -> Optional[UserSettings]:
        query = select(UserSettings).where(UserSettings.user_id == user_id)
        result = await self.db.execute(query)
        return result.scalars().first()

    async def get_or_create(self, user_id: uuid.UUID) -> UserSettings:
        settings = await self.get_by_user_id(user_id)
        if settings:
            return settings
        return await self.create({"user_id": user_id})
