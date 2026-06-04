from fastapi import APIRouter

from app.api.v1.deps import CurrentUser, DbSession
from app.schemas.gold import WalletRead
from app.services.gold_service import wallet_read

router = APIRouter()


@router.get("", response_model=WalletRead)
def get_wallet(db: DbSession, user: CurrentUser) -> WalletRead:
    return wallet_read(db, user.id)
