from decimal import Decimal
from datetime import datetime
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.db.base import Base
from app.models import GoldPrice, GoldTreasury, Wallet, LedgerTransaction
from app.models.trading import Order, Payment, Trade, TradingSetting
from app.schemas.trading import OrderCreate, PaymentVerify, TradingSettingsUpdate
from app.services.trading_service import TradingService
from app.services.gold_service import wallet_read


def test_trading_service_calculations_and_fifo_realized_profit() -> None:
    # 1. Setup in-memory sqlite database for isolation
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(engine)
    session_factory = sessionmaker(bind=engine)
    db = session_factory()

    try:
        # Instantiate trading service
        service = TradingService(db)

        # Seed initial gold settings
        settings = service.get_trading_settings()
        assert settings.trading_enabled is True
        assert settings.buy_margin == Decimal("4.00")
        assert settings.sell_margin == Decimal("2.00")

        # Set specific margins and limits for predictable calculations
        service.update_trading_settings(
            TradingSettingsUpdate(
                buy_margin=Decimal("4.00"),
                sell_margin=Decimal("2.00"),
                daily_limit=Decimal("50000.00"),
                minimum_purchase_amount=Decimal("100.00"),
                maximum_purchase_amount=Decimal("30000.00"),
                trading_enabled=True,
            )
        )

        # 2. Add gold prices and treasury for simulation
        # Base price: ₹6000 / g
        db.add(GoldPrice(gold_type="24K", price=Decimal("6000.00"), source="Test Price Feed"))
        db.add(
            GoldTreasury(
                available_gold=Decimal("1000.0000"),
                total_supplied=Decimal("1000.0000"),
            )
        )
        db.commit()

        # Buy rate = 6000 * 1.04 = ₹6240 / g

        # 3. Create BUY Order 1: Buy ₹12240 worth of gold (payable amount)
        # Total cost ratio = (1 + 0.03 + 0.02) = 1.05
        # Gold cost = 12240 / 1.05 = ₹11657.14
        # Fees = 11657.14 * 0.02 = ₹233.14
        # Taxes = 11657.14 * 0.03 = ₹349.71
        # Gold quantity = 11657.14 / 6240 = 1.8681 g
        order1 = service.create_buy_order(user_id=1, payload=OrderCreate(order_type="BUY", amount=Decimal("12240.00")))
        assert order1.status == "PENDING_PAYMENT"
        assert order1.price == Decimal("6240.00")
        assert order1.amount == Decimal("12240.00")
        assert order1.gold_quantity == Decimal("1.8681")
        assert order1.remaining_quantity == Decimal("1.8681")

        # Verify Payment 1
        service.verify_payment(
            PaymentVerify(
                order_id=order1.id,
                razorpay_payment_id="pay_mock_1",
                razorpay_signature="mock_signature",
            )
        )

        # Assert wallet balances updated
        wallet = wallet_read(db, user_id=1)
        assert wallet.gold_balance == Decimal("1.8681")
        assert wallet.available_gold == Decimal("1.8681")
        assert wallet.total_invested == Decimal("12240.00")

        # 4. Change gold base price to ₹7000 / g
        # Buy rate = 7000 * 1.04 = ₹7280 / g
        db.add(GoldPrice(gold_type="24K", price=Decimal("7000.00"), source="Test Price Feed"))
        db.commit()

        # Create BUY Order 2: Buy 1.0 g of gold
        # Gold Cost = 1 * 7280 = ₹7280.00
        # Fees = 7280 * 0.02 = ₹145.60
        # Taxes = 7280 * 0.03 = ₹218.40
        # Amount = 7280 + 145.60 + 218.40 = ₹7644.00
        order2 = service.create_buy_order(user_id=1, payload=OrderCreate(order_type="BUY", gold_quantity=Decimal("1.0000")))
        assert order2.price == Decimal("7280.00")
        assert order2.amount == Decimal("7644.00")

        # Verify Payment 2
        service.verify_payment(
            PaymentVerify(
                order_id=order2.id,
                razorpay_payment_id="pay_mock_2",
                razorpay_signature="mock_signature",
            )
        )

        wallet = wallet_read(db, user_id=1)
        assert wallet.gold_balance == Decimal("2.8681")
        assert wallet.total_invested == Decimal("12240.00") + Decimal("7644.00")

        # 5. Sell Gold: Sell 2.4048 g of gold
        # We hold:
        # - BUY 1: 1.8681 g bought at ₹6240 / g
        # - BUY 2: 1.0000 g bought at ₹7280 / g
        #
        # FIFO Deductions:
        # - Deduct 1.8681 g from BUY 1 (cost basis: 1.8681 * 6240 = ₹11656.94)
        # - Deduct 0.5000 g from BUY 2 (cost basis: 0.5000 * 7280 = ₹3640.00)
        # Total cost basis = ₹15296.94
        #
        # Current gold base price: ₹7500 / g
        # Sell rate = 7500 * 0.98 = ₹7350 / g
        # Payout amount = 2.3681 * 7350 = ₹17405.54
        db.add(GoldPrice(gold_type="24K", price=Decimal("7500.00"), source="Test Price Feed"))
        db.commit()

        sell_order = service.create_sell_order(
            user_id=1,
            payload=OrderCreate(order_type="SELL", gold_quantity=Decimal("2.3681")),
        )
        assert sell_order.status == "COMPLETED"
        assert sell_order.price == Decimal("7350.00")
        assert sell_order.amount == Decimal("17405.54")

        # Wallet should be updated
        wallet = wallet_read(db, user_id=1)
        # Remaining gold: 2.8681 - 2.3681 = 0.5000 g
        assert wallet.gold_balance == Decimal("0.5000")
        # Wallet total invested remaining should be: (Original total ₹19884.00) - (Cost basis ₹15296.94)
        assert wallet.total_invested == Decimal("4587.06")

        # Verify BUY 1 remaining_quantity is 0
        order1_refreshed = db.get(Order, order1.id)
        assert order1_refreshed.remaining_quantity == Decimal("0.0000")

        # Verify BUY 2 remaining_quantity is 0.5
        order2_refreshed = db.get(Order, order2.id)
        assert order2_refreshed.remaining_quantity == Decimal("0.5000")

    finally:
        db.close()
