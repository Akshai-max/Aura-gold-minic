from datetime import datetime
from decimal import Decimal

from sqlalchemy import Boolean, Date, DateTime, ForeignKey, Numeric, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class Wallet(Base):
    __tablename__ = "wallets"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), unique=True, index=True)
    gold_balance: Mapped[Decimal] = mapped_column(Numeric(14, 4), default=0)
    available_gold: Mapped[Decimal] = mapped_column(Numeric(14, 4), default=0)
    locked_gold: Mapped[Decimal] = mapped_column(Numeric(14, 4), default=0)
    pending_gold: Mapped[Decimal] = mapped_column(Numeric(14, 4), default=0)
    total_invested: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )


class PortfolioSnapshot(Base):
    __tablename__ = "portfolio_snapshots"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    portfolio_value: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0)
    profit_loss: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0)
    snapshot_date: Mapped[datetime] = mapped_column(Date(), index=True)


class GoldPrice(Base):
    __tablename__ = "gold_prices"

    id: Mapped[int] = mapped_column(primary_key=True)
    gold_type: Mapped[str] = mapped_column(String(20), default="24K")
    price: Mapped[Decimal] = mapped_column(Numeric(14, 2))
    source: Mapped[str] = mapped_column(String(80), default="Admin Price Feed")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class LedgerTransaction(Base):
    __tablename__ = "transactions"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    transaction_type: Mapped[str] = mapped_column(String(20), index=True)
    gold_amount: Mapped[Decimal] = mapped_column(Numeric(14, 4), default=0)
    gold_price: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0)
    amount: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0)
    status: Mapped[str] = mapped_column(String(30), default="PENDING", index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class GoldSetting(Base):
    __tablename__ = "gold_settings"

    id: Mapped[int] = mapped_column(primary_key=True)
    auto_price_feed_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    current_provider: Mapped[str] = mapped_column(String(80), default="Manual Price Feed")
    update_frequency: Mapped[str] = mapped_column(String(40), default="5 minutes")
    manual_override_price: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0)
