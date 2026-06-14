from __future__ import annotations

from sqlalchemy import Index, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, SoftDeleteMixin, TimestampMixin, UUIDPrimaryKeyMixin


class Supplier(Base, UUIDPrimaryKeyMixin, TimestampMixin, SoftDeleteMixin):
    """Supplier entity for gold inventory procurement."""

    __tablename__ = "suppliers"

    name: Mapped[str] = mapped_column(String(200), nullable=False)
    contact_person: Mapped[str | None] = mapped_column(String(100), nullable=True)
    mobile_number: Mapped[str | None] = mapped_column(String(20), nullable=True)
    email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    address: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_active: Mapped[bool] = mapped_column(default=True, nullable=False)

    inventory_items: Mapped[list["InventoryItem"]] = relationship(
        "InventoryItem", back_populates="supplier"
    )

    __table_args__ = (
        Index(
            "ix_suppliers_name_active",
            "name",
            unique=True,
            postgresql_where="is_deleted = false",
        ),
    )
