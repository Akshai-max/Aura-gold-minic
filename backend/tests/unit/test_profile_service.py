import uuid
import pytest
from unittest.mock import AsyncMock, MagicMock

from app.services.profile import ProfileService
from app.schemas.profile import ProfileUpdate, ChangePasswordRequest
from app.core.security import get_password_hash
from app.models.user import User
from datetime import datetime, timezone


@pytest.fixture
def mock_user_repo():
    return MagicMock()


@pytest.fixture
def mock_settings_repo():
    return MagicMock()


@pytest.fixture
def profile_service(mock_user_repo, mock_settings_repo):
    return ProfileService(mock_user_repo, mock_settings_repo, audit_service=None)


@pytest.mark.asyncio
async def test_update_profile(profile_service, mock_user_repo):
    now = datetime.now(timezone.utc)
    user = User(
        id=uuid.uuid4(),
        email="old@example.com",
        hashed_password=get_password_hash("pass"),
        is_active=True,
        is_deleted=False,
        roles=[],
        created_at=now,
        updated_at=now,
    )
    mock_user_repo.get_with_roles_and_permissions = AsyncMock(return_value=user)
    mock_user_repo.get_by_email = AsyncMock(return_value=None)
    mock_user_repo.db.commit = AsyncMock()

    result = await profile_service.update_profile(
        user.id, ProfileUpdate(first_name="New")
    )
    assert result.first_name == "New"


@pytest.mark.asyncio
async def test_change_password_wrong_current(profile_service, mock_user_repo):
    now = datetime.now(timezone.utc)
    user = User(
        id=uuid.uuid4(),
        email="user@example.com",
        hashed_password=get_password_hash("correct"),
        is_active=True,
        is_deleted=False,
        roles=[],
        created_at=now,
        updated_at=now,
    )
    mock_user_repo.get = AsyncMock(return_value=user)

    with pytest.raises(Exception):
        await profile_service.change_password(
            user.id,
            ChangePasswordRequest(
                current_password="wrong", new_password="newpassword1"
            ),
        )
