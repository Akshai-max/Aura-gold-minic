import os

import httpx
import pytest

pytestmark = pytest.mark.smoke

SMOKE_ADMIN_EMAIL = os.getenv("SMOKE_ADMIN_EMAIL", "superadmin@agsgold.com")
SMOKE_ADMIN_PASSWORD = os.getenv("SMOKE_ADMIN_PASSWORD", "adminpassword")


def _login(smoke_client: httpx.Client) -> str:
    response = smoke_client.post(
        "/api/v1/auth/login",
        json={"email": SMOKE_ADMIN_EMAIL, "password": SMOKE_ADMIN_PASSWORD},
    )
    assert response.status_code == 200, response.text
    return response.json()["access_token"]


def test_smoke_profile_settings(smoke_client: httpx.Client):
    token = _login(smoke_client)
    headers = {"Authorization": f"Bearer {token}"}

    profile = smoke_client.get("/api/v1/profile/", headers=headers)
    assert profile.status_code == 200
    assert "has_avatar" in profile.json()

    settings = smoke_client.get("/api/v1/profile/settings", headers=headers)
    assert settings.status_code == 200


def test_smoke_notifications_unread_count(smoke_client: httpx.Client):
    token = _login(smoke_client)
    headers = {"Authorization": f"Bearer {token}"}

    response = smoke_client.get("/api/v1/notifications/unread-count", headers=headers)
    assert response.status_code == 200
    assert "unread_count" in response.json()


def test_smoke_dashboard_stats(smoke_client: httpx.Client):
    token = _login(smoke_client)
    headers = {"Authorization": f"Bearer {token}"}

    response = smoke_client.get("/api/v1/dashboard/stats", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert "activity_trend" in data
    assert "login_statistics" in data


def test_smoke_audit_export(smoke_client: httpx.Client):
    token = _login(smoke_client)
    headers = {"Authorization": f"Bearer {token}"}

    response = smoke_client.get("/api/v1/audit-logs/export", headers=headers)
    if response.status_code == 403:
        pytest.skip("Smoke admin lacks audit.view permission")
    assert response.status_code == 200
    assert "text/csv" in response.headers.get("content-type", "")
    assert response.headers.get("X-Export-Total") is not None
