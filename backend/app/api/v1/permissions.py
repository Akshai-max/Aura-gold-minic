from fastapi import APIRouter, Depends

from app.api.v1.deps import require_permission

router = APIRouter()

DEFAULT_PERMISSIONS = [
    "user.create",
    "user.read",
    "user.update",
    "user.delete",
    "role.manage",
    "settings.manage",
    "audit.read",
    "dashboard.read",
    "profile.manage",
    "report.read",
    "analytics.read",
]


@router.get("", response_model=list[str])
def list_permissions(_=Depends(require_permission("role.manage"))) -> list[str]:
    return DEFAULT_PERMISSIONS
