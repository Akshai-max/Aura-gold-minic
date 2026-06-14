from __future__ import annotations

from datetime import datetime
from decimal import Decimal

from sqlalchemy import CheckConstraint, DateTime, Index, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, SoftDeleteMixin, TimestampMixin, UUIDPrimaryKeyMixin


class Customer(Base, UUIDPrimaryKeyMixin, TimestampMixin, SoftDeleteMixin):
    """Customer entity supporting individual and business types."""

    __tablename__ = "customers"

    customer_type: Mapped[str] = mapped_column(String(20), nullable=False)
    full_name: Mapped[str] = mapped_column(String(200), nullable=False)
    mobile_number: Mapped[str] = mapped_column(String(20), nullable=False)
    email: Mapped[str] = mapped_column(String(255), nullable=False)
    address: Mapped[str] = mapped_column(Text, nullable=False)
    gst_number: Mapped[str | None] = mapped_column(String(15), nullable=True)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="active")
    total_purchases: Mapped[int] = mapped_column(default=0, nullable=False)
    total_revenue: Mapped[Decimal] = mapped_column(
        Numeric(14, 2), default=0, nullable=False
    )
    last_transaction_date: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    __table_args__ = (
        Index(
            "ix_customers_email_active",
            "email",
            unique=True,
            postgresql_where="is_deleted = false",
        ),
        Index(
            "ix_customers_mobile_active",
            "mobile_number",
            unique=True,
            postgresql_where="is_deleted = false",
        ),
        Index("ix_customers_status", "status"),
        Index("ix_customers_customer_type", "customer_type"),
        Index("ix_customers_full_name", "full_name"),
        Index("ix_customers_created_at", "created_at"),
        CheckConstraint(
            "customer_type IN ('individual', 'business')",
            name="ck_customers_type",
        ),
        CheckConstraint(
            "status IN ('active', 'inactive', 'blacklisted')",
            name="ck_customers_status",
        ),
    )
