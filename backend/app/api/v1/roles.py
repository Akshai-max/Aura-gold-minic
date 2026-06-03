from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select

from app.api.v1.deps import DbSession, require_permission
from app.models.role import Role
from app.schemas.role import RoleRead, RoleUpdate

router = APIRouter()


@router.get("", response_model=list[RoleRead])
def list_roles(db: DbSession, _=Depends(require_permission("role.manage"))) -> list[Role]:
    return list(db.scalars(select(Role).order_by(Role.name)).all())


@router.put("/{role_id}", response_model=RoleRead)
def update_role(
    role_id: int,
    payload: RoleUpdate,
    db: DbSession,
    _=Depends(require_permission("role.manage")),
) -> Role:
    role = db.get(Role, role_id)
    if role is None:
        raise HTTPException(status_code=404, detail="Role not found")
    role.permissions = payload.permissions
    db.commit()
    db.refresh(role)
    return role
