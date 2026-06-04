from fastapi import APIRouter, Depends

from app.api.v1.deps import DbSession, current_user, require_role
from app.models.user import User
from app.schemas.trading import TradingSettingsRead, TradingSettingsUpdate
from app.services.trading_service import TradingService

router = APIRouter()


@router.get("", response_model=TradingSettingsRead)
def get_trading_settings(
    db: DbSession,
    _: User = Depends(current_user),
) -> TradingSettingsRead:
    return TradingService(db).get_trading_settings()


@router.put("", response_model=TradingSettingsRead)
def update_trading_settings(
    payload: TradingSettingsUpdate,
    db: DbSession,
    _: User = Depends(require_role("ADMIN")),
) -> TradingSettingsRead:
    return TradingService(db).update_trading_settings(payload)
