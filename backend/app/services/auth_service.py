from datetime import UTC, datetime, timedelta

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import (
    create_access_token,
    hash_password,
    hash_token,
    new_refresh_token,
    verify_password,
)
from app.models.refresh_token import RefreshToken
from app.models.role import Role
from app.models.user import User
from app.schemas.auth import TokenResponse
from app.schemas.user import UserRead
from app.services.audit_service import record_audit


def user_to_read(user: User) -> UserRead:
    return UserRead(
        id=user.id,
        first_name=user.first_name,
        last_name=user.last_name,
        email=user.email,
        mobile_number=user.mobile_number,
        role=user.role.name,
        is_active=user.is_active,
        email_verified=user.email_verified,
    )


def issue_session(db: Session, user: User) -> TokenResponse:
    permissions = list(user.role.permissions)
    access = create_access_token(str(user.id), permissions, user.role.name)
    refresh = new_refresh_token()
    db.add(
        RefreshToken(
            token_hash=hash_token(refresh),
            user_id=user.id,
            expires_at=datetime.now(UTC) + timedelta(days=settings.refresh_token_days),
        )
    )
    return TokenResponse(
        access_token=access,
        refresh_token=refresh,
        user=user_to_read(user),
        permissions=permissions,
    )


def authenticate(db: Session, email: str, password: str) -> User:
    user = db.scalar(select(User).where(User.email == email.lower()))
    if not user or not verify_password(password, user.hashed_password) or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    return user


def register_user(db: Session, *, data, role_name: str = "USER") -> User:
    if db.scalar(select(User).where(User.email == data.email.lower())):
        raise HTTPException(status_code=409, detail="Email already exists")
    role = db.scalar(select(Role).where(Role.name == role_name))
    if not role:
        raise HTTPException(status_code=400, detail="Invalid role")
    user = User(
        first_name=data.first_name,
        last_name=data.last_name,
        email=data.email.lower(),
        mobile_number=data.mobile_number,
        hashed_password=hash_password(data.password),
        role=role,
    )
    db.add(user)
    db.flush()
    record_audit(db, action="User Creation", entity="user", entity_id=str(user.id))
    return user
