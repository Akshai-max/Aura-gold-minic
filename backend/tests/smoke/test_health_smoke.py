import os

import httpx
import pytest

pytestmark = pytest.mark.smoke

SMOKE_ADMIN_EMAIL = os.getenv("SMOKE_ADMIN_EMAIL", "superadmin@agsgold.com")
SMOKE_ADMIN_PASSWORD = os.getenv("SMOKE_ADMIN_PASSWORD", "adminpassword")


def test_smoke_health_endpoint(smoke_client: httpx.Client):
    """Verify the API health endpoint responds with healthy status."""
    response = smoke_client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["service"] == "ags-gold-api"


def test_smoke_openapi_available(smoke_client: httpx.Client):
    """Verify OpenAPI schema is served."""
    response = smoke_client.get("/api/v1/openapi.json")
    assert response.status_code == 200
    schema = response.json()
    assert "openapi" in schema
    assert "paths" in schema


def test_smoke_login_and_me(smoke_client: httpx.Client):
    """Verify admin can log in and fetch profile (post-deploy smoke)."""
    login_response = smoke_client.post(
        "/api/v1/auth/login",
        json={"email": SMOKE_ADMIN_EMAIL, "password": SMOKE_ADMIN_PASSWORD},
    )
    assert login_response.status_code == 200, login_response.text
    tokens = login_response.json()
    assert "access_token" in tokens

    me_response = smoke_client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {tokens['access_token']}"},
    )
    assert me_response.status_code == 200
    assert me_response.json()["email"] == SMOKE_ADMIN_EMAIL
