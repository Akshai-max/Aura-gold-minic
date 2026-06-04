from datetime import datetime
from decimal import Decimal
from sqlalchemy import Boolean, ForeignKey, Numeric, String, DateTime, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class Order(Base):
    __tablename__ = "orders"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    order_type: Mapped[str] = mapped_column(String(20), index=True)  # BUY, SELL
    gold_quantity: Mapped[Decimal] = mapped_column(Numeric(14, 4))
    remaining_quantity: Mapped[Decimal] = mapped_column(Numeric(14, 4), default=0)
    price: Mapped[Decimal] = mapped_column(Numeric(14, 2))
    amount: Mapped[Decimal] = mapped_column(Numeric(14, 2))
    fees: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0)
    taxes: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0)
    status: Mapped[str] = mapped_column(String(30), default="CREATED", index=True)  # CREATED, PENDING_PAYMENT, PROCESSING, COMPLETED, FAILED, CANCELLED
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )


class Payment(Base):
    __tablename__ = "payments"

    id: Mapped[int] = mapped_column(primary_key=True)
    order_id: Mapped[int] = mapped_column(ForeignKey("orders.id"), index=True)
    gateway: Mapped[str] = mapped_column(String(50), default="razorpay")
    gateway_transaction_id: Mapped[str] = mapped_column(String(100), nullable=True)
    amount: Mapped[Decimal] = mapped_column(Numeric(14, 2))
    status: Mapped[str] = mapped_column(String(30), default="PENDING", index=True)  # PENDING, PROCESSING, SUCCESS, FAILED, CANCELLED, REFUNDED
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class Trade(Base):
    __tablename__ = "trades"

    id: Mapped[int] = mapped_column(primary_key=True)
    order_id: Mapped[int] = mapped_column(ForeignKey("orders.id"), index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    gold_quantity: Mapped[Decimal] = mapped_column(Numeric(14, 4))
    price: Mapped[Decimal] = mapped_column(Numeric(14, 2))
    amount: Mapped[Decimal] = mapped_column(Numeric(14, 2))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class TradingSetting(Base):
    __tablename__ = "trading_settings"

    id: Mapped[int] = mapped_column(primary_key=True)
    buy_margin: Mapped[Decimal] = mapped_column(Numeric(5, 2), default=0.0)  # margin percentage (e.g. 1.5%)
    sell_margin: Mapped[Decimal] = mapped_column(Numeric(5, 2), default=0.0)  # margin percentage (e.g. 1.0%)
    daily_limit: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=100000.00)
    minimum_purchase_amount: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=10.00)
    maximum_purchase_amount: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=50000.00)
    trading_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
