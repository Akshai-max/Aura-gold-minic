from datetime import UTC, date, datetime, timedelta
from decimal import Decimal

from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from app.models.gold import GoldPrice, GoldSetting, PortfolioSnapshot, Wallet
from app.schemas.gold import (
    GoldPriceRead,
    GoldSettingsRead,
    PlatformPortfolioRead,
    PortfolioPoint,
    PortfolioRead,
    PricePoint,
    WalletRead,
)

def _parse_frequency_delta(value: str) -> timedelta:
    clean = value.lower().strip()
    if "1 minute" in clean:
        return timedelta(minutes=1)
    if "5 minutes" in clean:
        return timedelta(minutes=5)
    if "15 minutes" in clean:
        return timedelta(minutes=15)
    if "1 hour" in clean:
        return timedelta(hours=1)
    return timedelta(minutes=5)


class GoldPriceService:
    def __init__(self, db: Session) -> None:
        self.db = db

    def current_price(self) -> GoldPriceRead:
        settings = self.settings()
        prices = list(
            self.db.scalars(select(GoldPrice).order_by(desc(GoldPrice.created_at), desc(GoldPrice.id)).limit(30))
        )
        latest = prices[0] if prices else None

        # Fetch from API if auto feed is enabled and no manual override is active
        if settings.auto_price_feed_enabled and settings.manual_override_price <= 0:
            freq = _parse_frequency_delta(settings.update_frequency)
            now = datetime.now(UTC)
            needs_fetch = True
            if latest is not None:
                latest_created = latest.created_at
                if latest_created.tzinfo is None:
                    latest_created = latest_created.replace(tzinfo=UTC)
                if now - latest_created < freq:
                    needs_fetch = False

            if needs_fetch:
                provider_lower = settings.current_provider.lower()
                if "massive" in provider_lower:
                    try:
                        import urllib.request
                        import json
                        api_key = "nJAf2ePTTkJD5tgyaOSqeiBuEsgIyEl6"
                        # 1. Fetch Gold/USD aggregate
                        url_gold = f"https://api.massive.com/v2/aggs/ticker/C:XAUUSD/prev?apiKey={api_key}"
                        req_gold = urllib.request.Request(url_gold, headers={'User-Agent': 'Mozilla/5.0'})
                        with urllib.request.urlopen(req_gold, timeout=5) as resp_gold:
                            data_gold = json.loads(resp_gold.read().decode())
                            gold_usd = Decimal(str(data_gold["results"][0]["c"]))
                        
                        # 2. Fetch USD/INR aggregate
                        url_inr = f"https://api.massive.com/v2/aggs/ticker/C:USDINR/prev?apiKey={api_key}"
                        req_inr = urllib.request.Request(url_inr, headers={'User-Agent': 'Mozilla/5.0'})
                        with urllib.request.urlopen(req_inr, timeout=5) as resp_inr:
                            data_inr = json.loads(resp_inr.read().decode())
                            usd_inr = Decimal(str(data_inr["results"][0]["c"]))

                        # Convert ounces to grams and scale to INR
                        price_per_gram = ((gold_usd * usd_inr) / Decimal("31.1034768")).quantize(Decimal("0.01"))
                        new_price = GoldPrice(
                            gold_type="24K",
                            price=price_per_gram,
                            source="MassiveAPI",
                        )
                        self.db.add(new_price)
                        self.db.commit()
                        self.db.refresh(new_price)
                        prices.insert(0, new_price)
                        latest = new_price
                    except Exception as e:
                        print(f"Error fetching from MassiveAPI: {e}")
                else:
                    try:
                        import urllib.request
                        import json
                        api_key = "60566186b0932101fe906cc81ee02262"
                        url = f"https://api.metalpriceapi.com/v1/latest?api_key={api_key}&base=XAU&currencies=INR"
                        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
                        with urllib.request.urlopen(req, timeout=5) as response:
                            data = json.loads(response.read().decode())
                            if data.get("success"):
                                rate_inr_ounce = Decimal(str(data["rates"]["INR"]))
                                price_per_gram = (rate_inr_ounce / Decimal("31.1034768")).quantize(Decimal("0.01"))
                                new_price = GoldPrice(
                                    gold_type="24K",
                                    price=price_per_gram,
                                    source="MetalPriceAPI",
                                )
                                self.db.add(new_price)
                                self.db.commit()
                                self.db.refresh(new_price)
                                prices.insert(0, new_price)
                                latest = new_price
                    except Exception as e:
                        print(f"Error fetching from MetalPriceAPI: {e}")

        if settings.manual_override_price > 0:
            current = settings.manual_override_price
            source = "Manual Override"
        elif latest is not None:
            current = latest.price
            source = latest.source
        else:
            current = Decimal("0")
            source = "No price configured"
        previous = prices[1].price if len(prices) > 1 else current
        price_change = (current - previous).quantize(Decimal("0.01"))
        percentage_change = (
            Decimal("0")
            if previous == 0
            else ((price_change / previous) * 100).quantize(Decimal("0.01"))
        )
        today_prices = [
            price.price
            for price in prices
            if price.created_at is not None and price.created_at.date() == date.today()
        ]
        opening = today_prices[-1] if today_prices else current
        high = max(today_prices) if today_prices else current
        low = min(today_prices) if today_prices else current
        return GoldPriceRead(
            current_price=current,
            price_24k=current,
            price_22k=(current * Decimal("0.916667")).quantize(Decimal("0.01")),
            price_change=price_change,
            percentage_change=percentage_change,
            todays_high=high,
            todays_low=low,
            opening_price=opening,
            source=source,
            last_updated=latest.created_at if latest else datetime.now(UTC),
            history=[
                PricePoint(label=price.created_at.strftime("%d %b"), price=price.price)
                for price in reversed(prices[:10])
            ],
        )

    def settings(self) -> GoldSetting:
        settings = self.db.scalar(select(GoldSetting))
        if settings is None:
            settings = GoldSetting()
            self.db.add(settings)
            self.db.commit()
            self.db.refresh(settings)
        return settings

    def update_settings(self, payload: GoldSettingsRead) -> GoldSetting:
        settings = self.settings()
        for key, value in payload.model_dump().items():
            setattr(settings, key, value)
        if payload.manual_override_price > 0:
            self.db.add(
                GoldPrice(
                    gold_type="24K",
                    price=payload.manual_override_price,
                    source="Manual Override",
                )
            )
        self.db.commit()
        self.db.refresh(settings)
        return settings


def get_or_create_wallet(db: Session, user_id: int) -> Wallet:
    wallet = db.scalar(select(Wallet).where(Wallet.user_id == user_id))
    if wallet is None:
        wallet = Wallet(user_id=user_id)
        db.add(wallet)
        db.commit()
        db.refresh(wallet)
    return wallet


def wallet_read(db: Session, user_id: int) -> WalletRead:
    wallet = get_or_create_wallet(db, user_id)
    current_price = GoldPriceService(db).current_price().current_price
    current_value = (wallet.gold_balance * current_price).quantize(Decimal("0.01"))
    return WalletRead(
        wallet_id=wallet.id,
        user_id=wallet.user_id,
        gold_balance=wallet.gold_balance,
        available_gold=wallet.available_gold,
        locked_gold=wallet.locked_gold,
        pending_gold=wallet.pending_gold,
        total_invested=wallet.total_invested,
        current_value=current_value,
        profit_loss=(current_value - wallet.total_invested).quantize(Decimal("0.01")),
        created_at=wallet.created_at,
        updated_at=wallet.updated_at,
    )


def portfolio_read(db: Session, user_id: int, range_name: str | None = None) -> PortfolioRead:
    wallet = wallet_read(db, user_id)
    current_price = GoldPriceService(db).current_price().current_price
    invested = wallet.total_invested
    gain = wallet.profit_loss
    percent = Decimal("0") if invested == 0 else ((gain / invested) * 100).quantize(Decimal("0.01"))
    snapshots = _portfolio_snapshots(db, user_id, range_name)
    growth = [
        PortfolioPoint(
            label=snapshot.snapshot_date.strftime("%d %b"), value=snapshot.portfolio_value
        )
        for snapshot in snapshots
    ]
    if not growth:
        growth = [PortfolioPoint(label="Now", value=wallet.current_value)]
    return PortfolioRead(
        portfolio_value=wallet.current_value,
        current_portfolio_value=wallet.current_value,
        invested_amount=invested,
        profit_loss=gain,
        percentage_return=percent,
        total_gold_holdings=wallet.gold_balance,
        average_purchase_price=(
            Decimal("0")
            if wallet.gold_balance == 0
            else (invested / wallet.gold_balance).quantize(Decimal("0.01"))
        ),
        current_gold_price=current_price,
        unrealized_gain_loss=gain,
        daily_change=_change_since(db, user_id, wallet.current_value, days=1),
        weekly_change=_change_since(db, user_id, wallet.current_value, days=7),
        monthly_change=_change_since(db, user_id, wallet.current_value, days=30),
        growth=growth,
    )


def platform_portfolio_read(db: Session) -> PlatformPortfolioRead:
    wallets = list(db.scalars(select(Wallet)))
    current_price = GoldPriceService(db).current_price().current_price
    total_gold = sum((wallet.gold_balance for wallet in wallets), Decimal("0"))
    total_invested = sum((wallet.total_invested for wallet in wallets), Decimal("0"))
    total_value = (total_gold * current_price).quantize(Decimal("0.01"))
    return PlatformPortfolioRead(
        total_gold_holdings=total_gold,
        total_platform_assets=total_value,
        total_portfolio_value=max(total_value, total_invested),
    )


def _portfolio_snapshots(
    db: Session,
    user_id: int,
    range_name: str | None,
) -> list[PortfolioSnapshot]:
    days = {
        "oneDay": 1,
        "oneWeek": 7,
        "oneMonth": 30,
        "threeMonths": 90,
        "oneYear": 365,
    }.get(range_name or "oneMonth", 30)
    start_date = date.today() - timedelta(days=days)
    return list(
        db.scalars(
            select(PortfolioSnapshot)
            .where(
                PortfolioSnapshot.user_id == user_id,
                PortfolioSnapshot.snapshot_date >= start_date,
            )
            .order_by(PortfolioSnapshot.snapshot_date)
        )
    )


def _change_since(db: Session, user_id: int, current_value: Decimal, days: int) -> Decimal:
    snapshot = db.scalar(
        select(PortfolioSnapshot)
        .where(
            PortfolioSnapshot.user_id == user_id,
            PortfolioSnapshot.snapshot_date <= date.today() - timedelta(days=days),
        )
        .order_by(desc(PortfolioSnapshot.snapshot_date))
    )
    if snapshot is None:
        return Decimal("0")
    return (current_value - snapshot.portfolio_value).quantize(Decimal("0.01"))
