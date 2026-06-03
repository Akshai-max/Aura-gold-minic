from fastapi import APIRouter

from app.api.v1 import audit, auth, permissions, roles, settings, users

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(roles.router, prefix="/roles", tags=["roles"])
api_router.include_router(permissions.router, prefix="/permissions", tags=["permissions"])
api_router.include_router(settings.router, prefix="/settings", tags=["settings"])
api_router.include_router(audit.router, prefix="/audit", tags=["audit"])

