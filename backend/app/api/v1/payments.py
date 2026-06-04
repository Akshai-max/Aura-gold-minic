from fastapi import APIRouter, Depends

from app.api.v1.deps import DbSession, current_user
from app.models.user import User
from app.schemas.trading import OrderRead, PaymentVerify
from app.services.trading_service import TradingService

router = APIRouter()


@router.post("/verify", response_model=OrderRead)
def verify_payment(
    payload: PaymentVerify,
    db: DbSession,
    _: User = Depends(current_user),
) -> OrderRead:
    return TradingService(db).verify_payment(payload)
