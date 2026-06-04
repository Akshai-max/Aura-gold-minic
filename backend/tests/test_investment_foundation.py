from app.models import GoldPrice, GoldSetting, LedgerTransaction, PortfolioSnapshot, Wallet
from app.schemas.gold import TransactionType
from app.services.gold_service import portfolio_read, wallet_read
from app.db.base import Base
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker


def test_gold_models_are_registered() -> None:
    assert Wallet.__tablename__ == "wallets"
    assert PortfolioSnapshot.__tablename__ == "portfolio_snapshots"
    assert GoldPrice.__tablename__ == "gold_prices"
    assert LedgerTransaction.__tablename__ == "transactions"
    assert GoldSetting.__tablename__ == "gold_settings"


def test_transaction_types_prepare_future_flows() -> None:
    assert {item.value for item in TransactionType} == {
        "BUY",
        "SELL",
        "SIP",
        "STAKE",
        "UNSTAKE",
        "REWARD",
        "REDEEM",
    }


def test_new_wallet_starts_empty_and_portfolio_uses_real_zero_state() -> None:
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(engine)
    session_factory = sessionmaker(bind=engine)
    db = session_factory()
    try:
        wallet = wallet_read(db, user_id=1)
        portfolio = portfolio_read(db, user_id=1)

        assert wallet.gold_balance == 0
        assert wallet.total_invested == 0
        assert wallet.current_value == 0
        assert portfolio.average_purchase_price == 0
        assert portfolio.daily_change == 0
        assert portfolio.growth[0].value == 0
    finally:
        db.close()
