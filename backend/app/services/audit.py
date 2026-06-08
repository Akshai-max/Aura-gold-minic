import asyncio
import csv
import io
import logging
import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional, TYPE_CHECKING

from app.models.audit_log import AuditLog
from app.repositories.audit_log import AuditLogRepository
from app.middleware.audit_middleware import client_ip_ctx, user_agent_ctx
from app.core import audit_actions
from app.core.config import settings

if TYPE_CHECKING:
    from app.services.notification import NotificationService

logger = logging.getLogger(__name__)


class AuditService:
    """Service class encapsulating Audit Logging business logic."""

    def __init__(
        self,
        audit_repo: AuditLogRepository,
        notification_service: Optional["NotificationService"] = None,
    ):
        self.audit_repo = audit_repo
        self.notification_service = notification_service

    def _dispatch_notification(
        self,
        action: str,
        user_id: Optional[uuid.UUID],
        entity_type: Optional[str],
        entity_id: Optional[str],
        metadata: Optional[dict],
    ) -> None:
        """Fire-and-forget notification dispatch; never blocks or fails audit writes."""
        if not self.notification_service:
            return

        async def _safe_notify() -> None:
            try:
                from app.database.session import async_session_maker
                from app.repositories.notification import NotificationRepository
                from app.repositories.user import UserRepository
                from app.repositories.user_settings import UserSettingsRepository
                from app.services.notification import NotificationService

                async with async_session_maker() as session:
                    service = NotificationService(
                        NotificationRepository(session),
                        UserRepository(session),
                        UserSettingsRepository(session),
                    )
                    await service.handle_audit_event(
                        action=action,
                        user_id=user_id,
                        entity_type=entity_type,
                        entity_id=entity_id,
                        metadata=metadata,
                    )
            except Exception:
                logger.exception(
                    "notification_dispatch_failed",
                    extra={"action": action, "user_id": str(user_id)},
                )

        try:
            loop = asyncio.get_running_loop()
            loop.create_task(_safe_notify())
        except RuntimeError:
            pass

    async def log_action(
        self,
        user_id: Optional[uuid.UUID],
        action: str,
        entity_type: Optional[str] = None,
        entity_id: Optional[str] = None,
        metadata: Optional[dict] = None,
    ) -> AuditLog:
        """Log a new audit event, automatically resolving client context."""
        ip_address = client_ip_ctx.get()
        user_agent = user_agent_ctx.get()

        enriched_metadata = dict(metadata) if metadata else {}
        if ip_address and "ip" not in enriched_metadata:
            enriched_metadata["ip"] = ip_address

        log_data = {
            "user_id": user_id,
            "action": action,
            "entity_type": entity_type,
            "entity_id": entity_id,
            "meta_data": enriched_metadata or None,
            "ip_address": ip_address,
            "user_agent": user_agent,
            "timestamp": datetime.now(timezone.utc),
        }

        audit_log = await self.audit_repo.create(log_data)

        self._dispatch_notification(
            action=action,
            user_id=user_id,
            entity_type=entity_type,
            entity_id=entity_id,
            metadata=enriched_metadata,
        )

        return audit_log

    async def list_audit_logs(
        self,
        skip: int = 0,
        limit: int = 100,
        user_id: Optional[uuid.UUID] = None,
        action: Optional[str] = None,
        entity_type: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        search: Optional[str] = None,
    ) -> tuple[list[AuditLog], int]:
        """Fetch audit logs matching filters with total count."""
        items = await self.audit_repo.list_audit_logs(
            skip=skip,
            limit=limit,
            user_id=user_id,
            action=action,
            entity_type=entity_type,
            start_date=start_date,
            end_date=end_date,
            search=search,
        )
        total = await self.audit_repo.count_audit_logs(
            user_id=user_id,
            action=action,
            entity_type=entity_type,
            start_date=start_date,
            end_date=end_date,
            search=search,
        )
        return items, total

    async def get_audit_log(
        self, log_id: uuid.UUID, timestamp: datetime
    ) -> Optional[AuditLog]:
        """Fetch a single audit log by composite key."""
        return await self.audit_repo.get_by_id_and_timestamp(log_id, timestamp)

    async def export_audit_logs_csv(
        self,
        user_id: Optional[uuid.UUID] = None,
        action: Optional[str] = None,
        entity_type: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        search: Optional[str] = None,
        limit: Optional[int] = None,
    ) -> tuple[str, int, bool]:
        """Export filtered audit logs as CSV string with truncation metadata."""
        export_limit = limit or settings.AUDIT_EXPORT_MAX_ROWS
        total = await self.audit_repo.count_audit_logs(
            user_id=user_id,
            action=action,
            entity_type=entity_type,
            start_date=start_date,
            end_date=end_date,
            search=search,
        )
        truncated = total > export_limit
        items = await self.audit_repo.list_audit_logs(
            skip=0,
            limit=export_limit,
            user_id=user_id,
            action=action,
            entity_type=entity_type,
            start_date=start_date,
            end_date=end_date,
            search=search,
        )
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(
            [
                "id",
                "user_id",
                "action",
                "entity_type",
                "entity_id",
                "ip_address",
                "user_agent",
                "timestamp",
                "metadata",
            ]
        )
        for log in items:
            writer.writerow(
                [
                    str(log.id),
                    str(log.user_id) if log.user_id else "",
                    log.action,
                    log.entity_type or "",
                    log.entity_id or "",
                    log.ip_address or "",
                    log.user_agent or "",
                    log.timestamp.isoformat(),
                    str(log.meta_data) if log.meta_data else "",
                ]
            )
        return output.getvalue(), total, truncated

    async def get_login_statistics(
        self, user_id: Optional[uuid.UUID] = None, system_wide: bool = False
    ) -> dict[str, int]:
        """Return login success counts for today, week, and month."""
        now = datetime.now(timezone.utc)
        today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        week_start = today_start - timedelta(days=7)
        month_start = today_start.replace(day=1)

        filter_user = None if system_wide else user_id
        return {
            "today": await self.audit_repo.count_logins_since(
                audit_actions.LOGIN_SUCCESS, today_start, filter_user
            ),
            "week": await self.audit_repo.count_logins_since(
                audit_actions.LOGIN_SUCCESS, week_start, filter_user
            ),
            "month": await self.audit_repo.count_logins_since(
                audit_actions.LOGIN_SUCCESS, month_start, filter_user
            ),
        }

    async def get_activity_trend(
        self, days: int = 7, user_id: Optional[uuid.UUID] = None
    ) -> list[dict[str, int | str]]:
        """Return daily login counts for dashboard chart."""
        return await self.audit_repo.get_daily_login_counts(days=days, user_id=user_id)
