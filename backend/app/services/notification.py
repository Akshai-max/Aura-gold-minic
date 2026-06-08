import uuid
from datetime import datetime, timedelta, timezone
from typing import List, Optional

from app.core import audit_actions
from app.core.config import settings
from app.models.notification import Notification
from app.repositories.notification import NotificationRepository
from app.repositories.user import UserRepository
from app.repositories.user_settings import UserSettingsRepository


class NotificationService:
    """Service class encapsulating in-app notification business logic."""

    CATEGORY_SYSTEM = "system"
    CATEGORY_SECURITY = "security"

    def __init__(
        self,
        notification_repo: NotificationRepository,
        user_repo: UserRepository,
        settings_repo: UserSettingsRepository,
    ):
        self.notification_repo = notification_repo
        self.user_repo = user_repo
        self.settings_repo = settings_repo

    async def _is_category_enabled(self, user_id: uuid.UUID, category: str) -> bool:
        user_settings = await self.settings_repo.get_or_create(user_id)
        if category == self.CATEGORY_SECURITY:
            return user_settings.notification_security_alerts
        if category == self.CATEGORY_SYSTEM:
            return user_settings.notification_system_updates
        return True

    async def create_notification(
        self,
        user_id: uuid.UUID,
        title: str,
        message: str,
        category: str,
        metadata: Optional[dict] = None,
    ) -> Optional[Notification]:
        if not await self._is_category_enabled(user_id, category):
            return None

        return await self.notification_repo.create(
            {
                "user_id": user_id,
                "title": title,
                "message": message,
                "category": category,
                "meta_data": metadata,
            }
        )

    async def list_notifications(
        self,
        user_id: uuid.UUID,
        skip: int = 0,
        limit: int = 50,
        category: Optional[str] = None,
        is_read: Optional[bool] = None,
    ) -> tuple[list[Notification], int, int]:
        items = await self.notification_repo.list_for_user(
            user_id=user_id,
            skip=skip,
            limit=limit,
            category=category,
            is_read=is_read,
        )
        total = await self.notification_repo.count_for_user(
            user_id=user_id, category=category, is_read=is_read
        )
        unread = await self.notification_repo.count_for_user(
            user_id=user_id, is_read=False
        )
        return items, total, unread

    async def mark_read(
        self,
        user_id: uuid.UUID,
        notification_ids: Optional[List[uuid.UUID]] = None,
        mark_all: bool = False,
    ) -> int:
        if not mark_all and not notification_ids:
            return 0
        return await self.notification_repo.mark_read(
            user_id=user_id,
            notification_ids=notification_ids,
            mark_all=mark_all,
        )

    async def get_unread_count(self, user_id: uuid.UUID) -> int:
        return await self.notification_repo.count_for_user(
            user_id=user_id, is_read=False
        )

    async def handle_audit_event(
        self,
        action: str,
        user_id: Optional[uuid.UUID],
        entity_type: Optional[str],
        entity_id: Optional[str],
        metadata: Optional[dict],
    ) -> None:
        """Create notifications based on audit events."""
        metadata = metadata or {}

        if action == audit_actions.LOGIN_SUCCESS and user_id:
            since = datetime.now(timezone.utc) - timedelta(
                minutes=settings.NOTIFICATION_LOGIN_COOLDOWN_MINUTES
            )
            if await self.notification_repo.has_recent_notification(
                user_id=user_id,
                category=self.CATEGORY_SECURITY,
                title="New login detected",
                since=since,
            ):
                return

            await self.create_notification(
                user_id=user_id,
                title="New login detected",
                message="A successful login was recorded on your account.",
                category=self.CATEGORY_SECURITY,
                metadata={"action": action, "ip": metadata.get("ip")},
            )
        elif action == audit_actions.LOGIN_FAILURE:
            email = metadata.get("email")
            if email:
                user = await self.user_repo.get_by_email(email)
                if user:
                    await self.create_notification(
                        user_id=user.id,
                        title="Failed login attempt",
                        message=f"A failed login attempt was made for {email}.",
                        category=self.CATEGORY_SECURITY,
                        metadata={
                            "action": action,
                            "reason": metadata.get("reason"),
                        },
                    )
        elif action in (audit_actions.ROLE_ASSIGN, audit_actions.ROLE_REMOVE):
            if entity_id:
                target_id = uuid.UUID(entity_id)
                role_name = metadata.get("role_name", "a role")
                verb = (
                    "assigned to"
                    if action == audit_actions.ROLE_ASSIGN
                    else "removed from"
                )
                await self.create_notification(
                    user_id=target_id,
                    title="Role change",
                    message=f"Role '{role_name}' was {verb} your account.",
                    category=self.CATEGORY_SYSTEM,
                    metadata=metadata,
                )
        elif action == audit_actions.USER_UPDATE and entity_id:
            target_id = uuid.UUID(entity_id)
            await self.create_notification(
                user_id=target_id,
                title="Account updated",
                message="Your account details were updated.",
                category=self.CATEGORY_SYSTEM,
                metadata=metadata,
            )
        elif action in (
            audit_actions.PERMISSION_ASSIGN,
            audit_actions.PERMISSION_REMOVE,
        ):
            role_id_str = entity_id
            if role_id_str:
                role_id = uuid.UUID(role_id_str)
                perm_name = metadata.get("permission_name", "a permission")
                verb = (
                    "added to"
                    if action == audit_actions.PERMISSION_ASSIGN
                    else "removed from"
                )
                user_ids = await self.notification_repo.get_users_with_role(role_id)
                for uid in user_ids:
                    await self.create_notification(
                        user_id=uid,
                        title="Permission change",
                        message=f"Permission '{perm_name}' was {verb} one of your roles.",
                        category=self.CATEGORY_SYSTEM,
                        metadata=metadata,
                    )
        elif action == audit_actions.PROFILE_UPDATE and user_id:
            await self.create_notification(
                user_id=user_id,
                title="Profile updated",
                message="Your profile was successfully updated.",
                category=self.CATEGORY_SYSTEM,
                metadata=metadata,
            )
        elif action == audit_actions.PASSWORD_CHANGE and user_id:
            await self.create_notification(
                user_id=user_id,
                title="Password changed",
                message="Your account password was changed.",
                category=self.CATEGORY_SECURITY,
                metadata=metadata,
            )
