from fastapi import APIRouter, Depends

from app.api.v1.deps import DbSession, current_user, require_role
from app.models.user import User
from app.schemas.gold import TreasuryRead, TreasuryUpdate
from app.services.treasury_service import TreasuryService

router = APIRouter()


@router.get("", response_model=TreasuryRead)
def get_treasury(db: DbSession, _: User = Depends(current_user)) -> TreasuryRead:
    return TreasuryService(db).read()


@router.put("", response_model=TreasuryRead)
def update_treasury(
    payload: TreasuryUpdate,
    db: DbSession,
    admin: User = Depends(require_role("ADMIN")),
) -> TreasuryRead:
    return TreasuryService(db).update(payload, admin_id=admin.id)
