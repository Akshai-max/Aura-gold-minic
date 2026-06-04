from datetime import datetime
from decimal import Decimal
from enum import StrEnum
from pydantic import BaseModel, ConfigDict


class OrderType(StrEnum):
    BUY = "BUY"
    SELL = "SELL"


class OrderStatus(StrEnum):
    CREATED = "CREATED"
    PENDING_PAYMENT = "PENDING_PAYMENT"
    PROCESSING = "PROCESSING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"
    CANCELLED = "CANCELLED"


class PaymentStatus(StrEnum):
    PENDING = "PENDING"
    PROCESSING = "PROCESSING"
    SUCCESS = "SUCCESS"
    FAILED = "FAILED"
    CANCELLED = "CANCELLED"
    REFUNDED = "REFUNDED"


class OrderCreate(BaseModel):
    order_type: OrderType
    gold_quantity: Decimal | None = None
    amount: Decimal | None = None  # User can specify either amount (₹) or gold quantity (grams)


class OrderRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    order_type: OrderType
    gold_quantity: Decimal
    price: Decimal
    amount: Decimal
    fees: Decimal
    taxes: Decimal
    status: OrderStatus
    created_at: datetime
    updated_at: datetime


class PaymentRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    order_id: int
    gateway: str
    gateway_transaction_id: str | None
    amount: Decimal
    status: PaymentStatus
    created_at: datetime


class PaymentVerify(BaseModel):
    order_id: int
    razorpay_payment_id: str
    razorpay_order_id: str | None = None
    razorpay_signature: str | None = None


class TradeRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    order_id: int
    user_id: int
    gold_quantity: Decimal
    price: Decimal
    amount: Decimal
    created_at: datetime


class TradingSettingsRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    buy_margin: Decimal
    sell_margin: Decimal
    daily_limit: Decimal
    minimum_purchase_amount: Decimal
    maximum_purchase_amount: Decimal
    trading_enabled: bool


class TradingSettingsUpdate(BaseModel):
    buy_margin: Decimal
    sell_margin: Decimal
    daily_limit: Decimal
    minimum_purchase_amount: Decimal
    maximum_purchase_amount: Decimal
    trading_enabled: bool
