from decimal import Decimal

from app.services.payment_settlement import (
    compute_purchase_settlement,
    grams_from_payment_amount,
    payment_amount_from_grams,
)


def test_settlement_for_1000_inr_gold():
    breakdown = compute_purchase_settlement(Decimal("1000"), metal="gold")
    assert breakdown.gross_amount_inr == Decimal("1000.00")
    assert breakdown.gst_percent == Decimal("3")
    assert breakdown.metal_value_inr == Decimal("970.87")
    assert breakdown.gst_amount_inr == Decimal("29.13")
    assert breakdown.razorpay_fee_inr == Decimal("23.60")
    assert breakdown.merchant_settlement_inr == Decimal("976.40")


def test_grams_from_10000_payment_at_14280_rate():
    grams = grams_from_payment_amount(
        Decimal("10000"),
        Decimal("14280"),
        metal="gold",
    )
    assert grams == Decimal("0.6799")
    amount = payment_amount_from_grams(grams, Decimal("14280"), metal="gold")
    # Grams are rounded to 4 dp; reverse amount may differ slightly from gross paid.
    assert amount == Decimal("10000.24")
