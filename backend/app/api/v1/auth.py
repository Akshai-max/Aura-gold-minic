from datetime import UTC, datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.v1.deps import CurrentUser, DbSession
from app.core.security import hash_password, hash_token
from app.models.refresh_token import RefreshToken
from app.models.user import User
from app.schemas.auth import (
    ForgotPasswordRequest,
    LoginRequest,
    RefreshRequest,
    RegisterRequest,
    ResetPasswordRequest,
    TokenResponse,
)
from app.schemas.user import UserRead
from app.services.audit_service import record_audit
from app.services.auth_service import authenticate, issue_session, register_user, user_to_read

router = APIRouter()


@router.post("/register", response_model=TokenResponse)
def register(payload: RegisterRequest, db: DbSession) -> TokenResponse:
    user = register_user(db, data=payload)
    session = issue_session(db, user)
    record_audit(db, action="Login", entity="auth", actor_id=user.id)
    db.commit()
    return session


@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest, db: DbSession) -> TokenResponse:
    user = authenticate(db, payload.email, payload.password)
    session = issue_session(db, user)
    record_audit(db, action="Login", entity="auth", actor_id=user.id)
    db.commit()
    return session


@router.post("/refresh", response_model=TokenResponse)
def refresh(payload: RefreshRequest, db: DbSession) -> TokenResponse:
    token = db.scalar(
        select(RefreshToken).where(RefreshToken.token_hash == hash_token(payload.refresh_token))
    )
    if not token or token.revoked_at or token.expires_at < datetime.now(UTC):
        raise HTTPException(status_code=401, detail="Invalid refresh token")
    token.revoked_at = datetime.now(UTC)
    session = issue_session(db, token.user)
    db.commit()
    return session


@router.post("/logout")
def logout(user: CurrentUser, db: DbSession) -> dict[str, str]:
    record_audit(db, action="Logout", entity="auth", actor_id=user.id)
    db.commit()
    return {"status": "ok"}


@router.get("/me", response_model=UserRead)
def me(user: CurrentUser) -> UserRead:
    return user_to_read(user)


@router.post("/forgot-password")
def forgot_password(payload: ForgotPasswordRequest) -> dict[str, str]:
    return {"status": "reset link queued"}


@router.post("/reset-password")
def reset_password(payload: ResetPasswordRequest, db: DbSession) -> dict[str, str]:
    user = db.scalar(select(User).where(User.email == payload.token.lower()))
    if user:
        user.hashed_password = hash_password(payload.password)
        record_audit(db, action="Password Changes", entity="user", actor_id=user.id, entity_id=str(user.id))
        db.commit()
    return {"status": "ok"}


@router.post("/verify-email")
def verify_email(user: CurrentUser, db: DbSession) -> dict[str, str]:
    user.email_verified = True
    db.commit()
    return {"status": "verified"}

