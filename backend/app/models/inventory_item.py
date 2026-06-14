from __future__ import annotations

import uuid
from decimal import Decimal

from sqlalchemy import CheckConstraint, ForeignKey, Index, Numeric, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, SoftDeleteMixin, TimestampMixin, UUIDPrimaryKeyMixin


class InventoryItem(Base, UUIDPrimaryKeyMixin, TimestampMixin, SoftDeleteMixin):
    """Gold inventory item with stock and valuation fields."""

    __tablename__ = "inventory_items"

    item_name: Mapped[str] = mapped_column(String(200), nullable=False)
    item_category: Mapped[str] = mapped_column(String(30), nullable=False)
    weight: Mapped[Decimal] = mapped_column(Numeric(12, 4), nullable=False)
    purity: Mapped[Decimal] = mapped_column(Numeric(6, 3), nullable=False)
    purchase_price: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    current_value: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    stock_quantity: Mapped[int] = mapped_column(default=0, nullable=False)
    reorder_level: Mapped[int] = mapped_column(default=5, nullable=False)
    supplier_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("suppliers.id"), nullable=True
    )
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="active")
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    supplier: Mapped["Supplier | None"] = relationship(
        "Supplier", back_populates="inventory_items"
    )
    movements: Mapped[list["StockMovement"]] = relationship(
        "StockMovement", back_populates="inventory_item"
    )

    __table_args__ = (
        Index("ix_inventory_items_item_name", "item_name"),
        Index("ix_inventory_items_item_category", "item_category"),
        Index("ix_inventory_items_status", "status"),
        Index("ix_inventory_items_supplier_id", "supplier_id"),
        Index("ix_inventory_items_stock_quantity", "stock_quantity"),
        CheckConstraint(
            "item_category IN ('gold_bar', 'gold_coin', 'gold_ornament', 'raw_gold')",
            name="ck_inventory_items_category",
        ),
        CheckConstraint(
            "status IN ('active', 'inactive', 'discontinued')",
            name="ck_inventory_items_status",
        ),
        CheckConstraint("stock_quantity >= 0", name="ck_inventory_items_stock_nonneg"),
        CheckConstraint("reorder_level >= 0", name="ck_inventory_items_reorder_nonneg"),
    )
