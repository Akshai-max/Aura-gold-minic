from fastapi import APIRouter, Depends
from sqlalchemy import select, desc
from app.api.v1.deps import DbSession, current_user
from app.models.user import User
from app.models.trading import Trade
from app.schemas.trading import TradeRead

router = APIRouter()


@router.get("", response_model=list[TradeRead])
def list_trades(
    db: DbSession,
    user: User = Depends(current_user),
    skip: int = 0,
    limit: int = 50,
) -> list[TradeRead]:
    query = select(Trade).where(Trade.user_id == user.id).order_by(desc(Trade.created_at)).offset(skip).limit(limit)
    return list(db.scalars(query))
