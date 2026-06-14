import uuid
from datetime import datetime, timezone
from typing import Optional

from app.core.exceptions import AuthenticationException
from app.core.logging import logger
from app.core import audit_actions
from app.core.security import (
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
    validate_token_version,
)
from app.models.user import User
from app.repositories.user import UserRepository
from app.repositories.token_blacklist import TokenBlacklistRepository
from app.schemas.auth import Token
from app.services.audit import AuditService


class AuthService:
    """Service class encapsulating authentication business logic."""

    def __init__(
        self,
        user_repo: UserRepository,
        token_blacklist_repo: TokenBlacklistRepository,
        audit_service: Optional[AuditService] = None,
    ):
        self.user_repo = user_repo
        self.token_blacklist_repo = token_blacklist_repo
        self.audit_service = audit_service

    async def authenticate_user(self, email: str, password: str) -> User:
        """Authenticate user credentials and return the active User object."""
        try:
            user = await self.user_repo.get_by_email(email)
            if not user:
                raise AuthenticationException("Incorrect email or password")

            if not verify_password(password, user.hashed_password):
                raise AuthenticationException("Incorrect email or password")

            if not user.is_active:
                raise AuthenticationException("Incorrect email or password")

            if self.audit_service:
                await self.audit_service.log_action(
                    user_id=user.id,
                    action=audit_actions.LOGIN_SUCCESS,
                    entity_type="User",
                    entity_id=str(user.id),
                    metadata={"email": email},
                )
            return user
        except AuthenticationException as e:
            if self.audit_service:
                await self.audit_service.log_action(
                    user_id=None,
                    action=audit_actions.LOGIN_FAILURE,
                    entity_type="User",
                    metadata={"email": email, "reason": e.message},
                )
            raise e

    async def refresh_tokens(self, refresh_token_str: str) -> Token:
        """Perform refresh token rotation (RTR) and return a new token pair."""
        payload = decode_token(refresh_token_str)

        if payload.get("type") != "refresh":
            raise AuthenticationException("Invalid token type")

        jti = payload.get("jti")
        sub = payload.get("sub")
        exp = payload.get("exp")

        if not jti or not sub or not exp:
            raise AuthenticationException("Invalid token payload")

        if await self.token_blacklist_repo.is_blacklisted(jti):
            logger.warning(
                "security_compromise_attempt",
                message="Re-use of revoked refresh token detected. Potential token theft!",
                jti=jti,
                user_id=sub,
            )
            raise AuthenticationException("Invalid or revoked refresh token")

        try:
            user_id = uuid.UUID(sub)
        except ValueError:
            raise AuthenticationException("Invalid user identifier in token")

        user = await self.user_repo.get(user_id)
        if not user or user.is_deleted or not user.is_active:
            raise AuthenticationException("User account is inactive or not found")

        validate_token_version(payload, user.token_version or 0)

        expires_at = datetime.fromtimestamp(exp, tz=timezone.utc)
        await self.token_blacklist_repo.blacklist_token(jti, expires_at)

        new_jti = str(uuid.uuid4())
        token_version = user.token_version or 0
        new_access_token = create_access_token(
            subject=user.id, token_version=token_version
        )
        new_refresh_token = create_refresh_token(
            subject=user.id, jti=new_jti, token_version=token_version
        )

        return Token(
            access_token=new_access_token,
            refresh_token=new_refresh_token,
        )

    async def logout_user(self, refresh_token_str: str) -> None:
        """Revoke a refresh token by blacklisting its JTI."""
        try:
            payload = decode_token(refresh_token_str)
        except AuthenticationException as e:
            raise e

        if payload.get("type") != "refresh":
            raise AuthenticationException("Invalid token type")

        jti = payload.get("jti")
        exp = payload.get("exp")
        sub = payload.get("sub")

        if not jti or not exp:
            raise AuthenticationException("Invalid token payload")

        if not await self.token_blacklist_repo.is_blacklisted(jti):
            expires_at = datetime.fromtimestamp(exp, tz=timezone.utc)
            await self.token_blacklist_repo.blacklist_token(jti, expires_at)

            if self.audit_service and sub:
                try:
                    user_id = uuid.UUID(sub)
                    await self.audit_service.log_action(
                        user_id=user_id,
                        action=audit_actions.LOGOUT,
                        entity_type="User",
                        entity_id=str(user_id),
                    )
                except ValueError:
                    pass

    async def get_user_by_id(self, user_id: uuid.UUID) -> User:
        """Fetch and return an active user by ID, raising if invalid."""
        user = await self.user_repo.get(user_id)
        if not user or user.is_deleted or not user.is_active:
            raise AuthenticationException("User account is inactive or not found")
        return user
