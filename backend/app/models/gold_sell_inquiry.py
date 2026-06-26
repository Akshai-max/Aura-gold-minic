from __future__ import annotations

import uuid
from datetime import datetime
from typing import TYPE_CHECKING, Optional

from sqlalchemy import DateTime, ForeignKey, Index, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.models.user import User


class GoldSellInquiry(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    __tablename__ = "gold_sell_inquiries"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    mobile_number: Mapped[str] = mapped_column(String(15), nullable=False)
    message: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[str] = mapped_column(
        String(20), default="pending", nullable=False
    )
    admin_response: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    responded_by_user_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    responded_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    user: Mapped["User"] = relationship(
        "User",
        foreign_keys=[user_id],
        lazy="joined",
    )
    responded_by: Mapped[Optional["User"]] = relationship(
        "User",
        foreign_keys=[responded_by_user_id],
        lazy="joined",
    )

    __table_args__ = (
        Index("ix_gold_sell_inquiries_user_id", "user_id"),
        Index("ix_gold_sell_inquiries_status", "status"),
        Index("ix_gold_sell_inquiries_created_at", "created_at"),
    )
