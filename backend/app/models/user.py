from __future__ import annotations
from typing import List, TYPE_CHECKING
from sqlalchemy import String, Boolean, Index, Text, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.base import Base, UUIDPrimaryKeyMixin, TimestampMixin, SoftDeleteMixin
from app.models.associations import user_roles

if TYPE_CHECKING:
    from app.models.role import Role


class User(Base, UUIDPrimaryKeyMixin, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "users"

    email: Mapped[str] = mapped_column(String(255), nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    is_superuser: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    first_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    last_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    avatar_base64: Mapped[str | None] = mapped_column(Text, nullable=True)
    avatar_content_type: Mapped[str | None] = mapped_column(String(50), nullable=True)
    token_version: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    # Relationships
    roles: Mapped[List["Role"]] = relationship(
        "Role", secondary=user_roles, back_populates="users"
    )

    __table_args__ = (
        Index(
            "ix_users_email_active",
            "email",
            unique=True,
            postgresql_where="is_deleted = false",
        ),
    )
