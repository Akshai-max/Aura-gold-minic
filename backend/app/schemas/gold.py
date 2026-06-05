from __future__ import annotations

from datetime import date as dt_date
from datetime import datetime
from decimal import Decimal
from enum import StrEnum

from pydantic import BaseModel, ConfigDict


class TransactionType(StrEnum):
    BUY = "BUY"
    SELL = "SELL"
    SIP = "SIP"
    STAKE = "STAKE"
    UNSTAKE = "UNSTAKE"
    REWARD = "REWARD"
    REDEEM = "REDEEM"


class TransactionStatus(StrEnum):
    PENDING = "PENDING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"


class PricePoint(BaseModel):
    label: str
    price: Decimal


class PortfolioPoint(BaseModel):
    label: str
    value: Decimal


class GoldPriceRead(BaseModel):
    current_price: Decimal
    price_24k: Decimal
    price_22k: Decimal
    price_change: Decimal
    percentage_change: Decimal
    todays_high: Decimal
    todays_low: Decimal
    opening_price: Decimal
    source: str
    last_updated: datetime
    history: list[PricePoint]


class GoldSettingsRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    auto_price_feed_enabled: bool
    current_provider: str
    update_frequency: str
    manual_override_price: Decimal


class GoldSettingsUpdate(BaseModel):
    auto_price_feed_enabled: bool
    current_provider: str
    update_frequency: str
    manual_override_price: Decimal


class TreasuryRead(BaseModel):
    available_gold: Decimal
    total_supplied: Decimal
    updated_at: datetime


class TreasuryUpdate(BaseModel):
    available_gold: Decimal


class WalletRead(BaseModel):
    wallet_id: int
    user_id: int
    gold_balance: Decimal
    available_gold: Decimal
    locked_gold: Decimal
    pending_gold: Decimal
    total_invested: Decimal
    current_value: Decimal
    profit_loss: Decimal
    created_at: datetime
    updated_at: datetime


class PortfolioRead(BaseModel):
    portfolio_value: Decimal
    current_portfolio_value: Decimal
    invested_amount: Decimal
    profit_loss: Decimal
    percentage_return: Decimal
    total_gold_holdings: Decimal
    average_purchase_price: Decimal
    current_gold_price: Decimal
    unrealized_gain_loss: Decimal
    daily_change: Decimal
    weekly_change: Decimal
    monthly_change: Decimal
    growth: list[PortfolioPoint]


class PlatformPortfolioRead(BaseModel):
    total_gold_holdings: Decimal
    total_platform_assets: Decimal
    total_portfolio_value: Decimal


class TransactionRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    transaction_id: int
    user_id: int
    transaction_type: TransactionType
    gold_amount: Decimal
    gold_price: Decimal
    amount: Decimal
    status: TransactionStatus
    created_at: datetime


class TransactionFilters(BaseModel):
    date: dt_date | None = None
    type: TransactionType | None = None
    status: TransactionStatus | None = None
