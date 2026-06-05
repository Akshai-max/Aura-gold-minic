import json
import urllib.request
from decimal import Decimal

from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.gold import GoldPrice

GRAMS_PER_TROY_OUNCE = Decimal("31.1034768")


def fetch_live_gold_price_inr() -> tuple[Decimal, str] | None:
    if not settings.gold_price_api_key:
        return None

    url = (
        f"{settings.gold_price_api_url}"
        f"?api_key={settings.gold_price_api_key}&base=XAU&currencies=INR"
    )
    request = urllib.request.Request(url, headers={"User-Agent": "AGS/0.1"})
    with urllib.request.urlopen(request, timeout=10) as response:
        data = json.loads(response.read().decode())
    if not data.get("success"):
        return None

    rate_inr_per_ounce = Decimal(str(data["rates"]["INR"]))
    price_per_gram = (rate_inr_per_ounce / GRAMS_PER_TROY_OUNCE).quantize(Decimal("0.01"))
    return price_per_gram, "MetalPriceAPI"


def sync_live_gold_price(db: Session) -> GoldPrice | None:
    fetched = fetch_live_gold_price_inr()
    if fetched is None:
        return None

    price_per_gram, source = fetched
    record = GoldPrice(
        gold_type="24K",
        price=price_per_gram,
        source=source,
    )
    db.add(record)
    db.commit()
    db.refresh(record)
    return record
