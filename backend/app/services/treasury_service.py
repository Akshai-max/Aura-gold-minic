from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.gold import GoldTreasury
from app.schemas.gold import TreasuryRead, TreasuryUpdate


class TreasuryService:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_or_create(self) -> GoldTreasury:
        treasury = self.db.scalar(select(GoldTreasury).limit(1))
        if treasury is None:
            treasury = GoldTreasury(
                available_gold=Decimal("1000.0000"),
                total_supplied=Decimal("1000.0000"),
            )
            self.db.add(treasury)
            self.db.commit()
            self.db.refresh(treasury)
        return treasury

    def read(self) -> TreasuryRead:
        treasury = self.get_or_create()
        return TreasuryRead(
            available_gold=treasury.available_gold,
            total_supplied=treasury.total_supplied,
            updated_at=treasury.updated_at,
        )

    def update(self, payload: TreasuryUpdate, admin_id: int) -> TreasuryRead:
        treasury = self.get_or_create()
        treasury.available_gold = payload.available_gold
        treasury.total_supplied = payload.available_gold
        treasury.updated_by = admin_id
        self.db.commit()
        self.db.refresh(treasury)
        return self.read()

    def ensure_available(self, quantity: Decimal) -> None:
        treasury = self.get_or_create()
        if quantity > treasury.available_gold:
            raise Exception(
                f"Insufficient treasury gold. Only {treasury.available_gold} g available for purchase."
            )

    def deduct(self, quantity: Decimal) -> None:
        treasury = self.get_or_create()
        if quantity > treasury.available_gold:
            raise Exception(
                f"Insufficient treasury gold. Only {treasury.available_gold} g available for purchase."
            )
        treasury.available_gold -= quantity
        self.db.add(treasury)

    def add(self, quantity: Decimal) -> None:
        treasury = self.get_or_create()
        treasury.available_gold += quantity
        self.db.add(treasury)
