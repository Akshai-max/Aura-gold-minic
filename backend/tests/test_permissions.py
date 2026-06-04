from app.api.v1.permissions import DEFAULT_PERMISSIONS


def test_admin_permissions_are_seeded() -> None:
    assert "user.create" in DEFAULT_PERMISSIONS
    assert "settings.manage" in DEFAULT_PERMISSIONS
    assert "audit.read" in DEFAULT_PERMISSIONS
