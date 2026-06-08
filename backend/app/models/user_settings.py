import uuid
from sqlalchemy import String, Boolean, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column
from app.models.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


class UserSettings(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    __tablename__ = "user_settings"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
        index=True,
    )
    locale: Mapped[str] = mapped_column(String(10), default="en", nullable=False)
    notification_email_enabled: Mapped[bool] = mapped_column(
        Boolean, default=True, nullable=False
    )
    notification_push_enabled: Mapped[bool] = mapped_column(
        Boolean, default=True, nullable=False
    )
    notification_security_alerts: Mapped[bool] = mapped_column(
        Boolean, default=True, nullable=False
    )
    notification_system_updates: Mapped[bool] = mapped_column(
        Boolean, default=True, nullable=False
    )
