from fastapi import APIRouter, Depends

from app.api.v1.deps import DbSession, current_user
from app.models.user import User
from app.schemas.trading import OrderCreate, OrderRead
from app.services.trading_service import TradingService

router = APIRouter()


@router.post("", response_model=OrderRead)
def buy_gold(
    payload: OrderCreate,
    db: DbSession,
    user: User = Depends(current_user),
) -> OrderRead:
    return TradingService(db).create_buy_order(user.id, payload)
