"""E2E flow: login, profile read, notifications list."""

import pytest
from httpx import AsyncClient

from tests.e2e.conftest import bearer_headers, login

pytestmark = pytest.mark.e2e


@pytest.mark.asyncio
async def test_profile_and_notifications_flow(
    db_client: AsyncClient, admin_actor: tuple
):
    """Authenticated user can read profile and notifications."""
    user, password = admin_actor
    tokens = await login(db_client, user.email, password)
    headers = bearer_headers(tokens["access_token"])

    profile_resp = await db_client.get("/api/v1/profile/", headers=headers)
    assert profile_resp.status_code == 200
    profile = profile_resp.json()
    assert "email" in profile
    assert "roles" in profile

    settings_resp = await db_client.get("/api/v1/profile/settings", headers=headers)
    assert settings_resp.status_code == 200

    notif_resp = await db_client.get("/api/v1/notifications/", headers=headers)
    assert notif_resp.status_code == 200
    notif_data = notif_resp.json()
    assert "items" in notif_data
    assert "unread_count" in notif_data

    dashboard_resp = await db_client.get("/api/v1/dashboard/stats", headers=headers)
    assert dashboard_resp.status_code == 200
