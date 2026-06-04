from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, desc
from app.api.v1.deps import DbSession, current_user
from app.models.user import User
from app.models.trading import Order
from app.schemas.trading import OrderRead

router = APIRouter()


@router.get("", response_model=list[OrderRead])
def list_orders(
    db: DbSession,
    user: User = Depends(current_user),
    skip: int = 0,
    limit: int = 50,
    order_type: str | None = None,
    status: str | None = None,
) -> list[OrderRead]:
    query = select(Order).where(Order.user_id == user.id)
    if order_type:
        query = query.where(Order.order_type == order_type.upper())
    if status:
        query = query.where(Order.status == status.upper())
    query = query.order_by(desc(Order.created_at)).offset(skip).limit(limit)
    return list(db.scalars(query))


@router.get("/{order_id}", response_model=OrderRead)
def get_order(
    order_id: int,
    db: DbSession,
    user: User = Depends(current_user),
) -> OrderRead:
    order = db.get(Order, order_id)
    if order is None or order.user_id != user.id:
        raise HTTPException(status_code=404, detail="Order not found")
    return order
