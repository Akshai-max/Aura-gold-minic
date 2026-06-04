from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select

from app.api.v1.deps import DbSession, require_permission
from app.core.security import hash_password
from app.models.role import Role
from app.models.user import User
from app.schemas.user import UserCreate, UserRead, UserUpdate
from app.services.audit_service import record_audit
from app.services.auth_service import user_to_read

router = APIRouter()


@router.get("", response_model=list[UserRead])
def list_users(
    db: DbSession,
    actor: User = Depends(require_permission("user.read")),
) -> list[UserRead]:
    users = db.scalars(select(User).order_by(User.created_at.desc())).all()
    return [user_to_read(user) for user in users]


@router.post("", response_model=UserRead)
def create_user(
    payload: UserCreate,
    db: DbSession,
    actor: User = Depends(require_permission("user.create")),
) -> UserRead:
    role = db.scalar(select(Role).where(Role.name == payload.role))
    if role is None:
        raise HTTPException(status_code=400, detail="Invalid role")
    user = User(
        first_name=payload.first_name,
        last_name=payload.last_name,
        email=payload.email.lower(),
        mobile_number=payload.mobile_number,
        hashed_password=hash_password(payload.password),
        role=role,
    )
    db.add(user)
    db.flush()
    record_audit(
        db, action="User Creation", entity="user", actor_id=actor.id, entity_id=str(user.id)
    )
    db.commit()
    return user_to_read(user)


@router.put("/{user_id}", response_model=UserRead)
def update_user(
    user_id: int,
    payload: UserUpdate,
    db: DbSession,
    actor: User = Depends(require_permission("user.update")),
) -> UserRead:
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    if payload.first_name is not None:
        user.first_name = payload.first_name
    if payload.last_name is not None:
        user.last_name = payload.last_name
    if payload.mobile_number is not None:
        user.mobile_number = payload.mobile_number
    if payload.is_active is not None:
        user.is_active = payload.is_active
    if payload.role is not None:
        role = db.scalar(select(Role).where(Role.name == payload.role))
        if role is None:
            raise HTTPException(status_code=400, detail="Invalid role")
        user.role = role
        record_audit(
            db, action="Role Assignment", entity="user", actor_id=actor.id, entity_id=str(user.id)
        )
    record_audit(
        db, action="User Updates", entity="user", actor_id=actor.id, entity_id=str(user.id)
    )
    db.commit()
    return user_to_read(user)


@router.post("/{user_id}/reset-password")
def reset_user_password(
    user_id: int,
    db: DbSession,
    actor: User = Depends(require_permission("user.update")),
) -> dict[str, str]:
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    user.hashed_password = hash_password("Temp@12345")
    record_audit(
        db, action="Password Changes", entity="user", actor_id=actor.id, entity_id=str(user.id)
    )
    db.commit()
    return {"temporary_password": "Temp@12345"}
