from datetime import datetime

from fastapi import APIRouter
from sqlalchemy import select

from app.api.v1.deps import CurrentUser, DbSession
from app.models.gold import LedgerTransaction
from app.schemas.gold import TransactionRead, TransactionStatus, TransactionType

router = APIRouter()


@router.get("", response_model=list[TransactionRead])
def list_transactions(
    db: DbSession,
    user: CurrentUser,
    date: datetime | None = None,
    type: TransactionType | None = None,
    status: TransactionStatus | None = None,
) -> list[TransactionRead]:
    statement = select(LedgerTransaction).where(LedgerTransaction.user_id == user.id)
    if type is not None:
        statement = statement.where(LedgerTransaction.transaction_type == type.value)
    if status is not None:
        statement = statement.where(LedgerTransaction.status == status.value)
    if date is not None:
        statement = statement.where(LedgerTransaction.created_at >= date.date())
    rows = db.scalars(statement.order_by(LedgerTransaction.created_at.desc())).all()
    return [
        TransactionRead(
            transaction_id=row.id,
            user_id=row.user_id,
            transaction_type=TransactionType(row.transaction_type),
            gold_amount=row.gold_amount,
            gold_price=row.gold_price,
            amount=row.amount,
            status=TransactionStatus(row.status),
            created_at=row.created_at,
        )
        for row in rows
    ]
