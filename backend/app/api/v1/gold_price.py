from fastapi import APIRouter, Depends

from app.api.v1.deps import DbSession, current_user, require_role
from app.models.user import User
from app.schemas.gold import GoldPriceRead, GoldSettingsRead, GoldSettingsUpdate
from app.services.gold_service import GoldPriceService

router = APIRouter()


@router.get("", response_model=GoldPriceRead)
def get_gold_price(db: DbSession, _: User = Depends(current_user)) -> GoldPriceRead:
    return GoldPriceService(db).current_price()


@router.get("/settings", response_model=GoldSettingsRead)
def get_gold_settings(
    db: DbSession,
    _: User = Depends(require_role("ADMIN")),
):
    return GoldPriceService(db).settings()


@router.put("/settings", response_model=GoldSettingsRead)
def update_gold_settings(
    payload: GoldSettingsUpdate,
    db: DbSession,
    _: User = Depends(require_role("ADMIN")),
):
    return GoldPriceService(db).update_settings(payload)
