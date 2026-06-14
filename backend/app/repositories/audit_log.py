from datetime import datetime, timedelta, timezone
from typing import Any, Optional
from sqlalchemy import select, func, or_, cast, String
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.audit_log import AuditLog
from app.repositories.base import BaseRepository


class AuditLogRepository(BaseRepository[AuditLog]):
    """Repository class handling query logic for AuditLog model."""

    def __init__(self, db_session: AsyncSession):
        super().__init__(AuditLog, db_session)

    def _apply_filters(
        self,
        query,
        user_id: Optional[Any] = None,
        action: Optional[str] = None,
        entity_type: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        search: Optional[str] = None,
    ):
        if user_id is not None:
            query = query.where(AuditLog.user_id == user_id)
        if action:
            query = query.where(AuditLog.action == action)
        if entity_type:
            query = query.where(AuditLog.entity_type == entity_type)
        if start_date is not None:
            query = query.where(AuditLog.timestamp >= start_date)
        if end_date is not None:
            query = query.where(AuditLog.timestamp <= end_date)
        if search:
            pattern = f"%{search}%"
            query = query.where(
                or_(
                    AuditLog.action.ilike(pattern),
                    AuditLog.entity_type.ilike(pattern),
                    AuditLog.entity_id.ilike(pattern),
                    cast(AuditLog.meta_data, String).ilike(pattern),
                )
            )
        return query

    async def list_audit_logs(
        self,
        skip: int = 0,
        limit: int = 100,
        user_id: Optional[Any] = None,
        action: Optional[str] = None,
        entity_type: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        search: Optional[str] = None,
    ) -> list[AuditLog]:
        """Fetch audit logs matching filters ordered by timestamp descending."""
        limit = min(limit, 5000)

        query = select(AuditLog).order_by(AuditLog.timestamp.desc())
        query = self._apply_filters(
            query, user_id, action, entity_type, start_date, end_date, search
        )
        query = query.offset(skip).limit(limit)
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def count_audit_logs(
        self,
        user_id: Optional[Any] = None,
        action: Optional[str] = None,
        entity_type: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        search: Optional[str] = None,
    ) -> int:
        """Count audit logs matching filters."""
        query = select(func.count()).select_from(AuditLog)
        query = self._apply_filters(
            query, user_id, action, entity_type, start_date, end_date, search
        )
        result = await self.db.execute(query)
        return result.scalar() or 0

    async def get_by_id_and_timestamp(
        self, log_id: Any, timestamp: datetime
    ) -> Optional[AuditLog]:
        """Fetch a single audit log by composite primary key."""
        query = select(AuditLog).where(
            AuditLog.id == log_id,
            AuditLog.timestamp == timestamp,
        )
        result = await self.db.execute(query)
        return result.scalars().first()

    async def count_logins_since(
        self,
        action: str,
        since: datetime,
        user_id: Optional[Any] = None,
    ) -> int:
        """Count audit logs of a given action since a datetime."""
        query = (
            select(func.count())
            .select_from(AuditLog)
            .where(AuditLog.action == action, AuditLog.timestamp >= since)
        )
        if user_id is not None:
            query = query.where(AuditLog.user_id == user_id)
        result = await self.db.execute(query)
        return result.scalar() or 0

    async def get_daily_login_counts(
        self, days: int = 7, user_id: Optional[Any] = None
    ) -> list[dict[str, int | str]]:
        """Return per-day login success counts for the last N days."""
        from app.core import audit_actions

        now = datetime.now(timezone.utc)
        start = (now - timedelta(days=days - 1)).replace(
            hour=0, minute=0, second=0, microsecond=0
        )
        day_col = func.date(AuditLog.timestamp).label("day")
        query = (
            select(day_col, func.count().label("count"))
            .where(
                AuditLog.action == audit_actions.LOGIN_SUCCESS,
                AuditLog.timestamp >= start,
            )
            .group_by(day_col)
            .order_by(day_col)
        )
        if user_id is not None:
            query = query.where(AuditLog.user_id == user_id)

        result = await self.db.execute(query)
        counts_by_day = {
            str(row.day): row.count for row in result.all() if row.day is not None
        }

        trend: list[dict[str, int | str]] = []
        for offset in range(days):
            day = (start + timedelta(days=offset)).date()
            key = str(day)
            trend.append(
                {"label": day.strftime("%a"), "count": counts_by_day.get(key, 0)}
            )
        return trend
