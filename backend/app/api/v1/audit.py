from fastapi import APIRouter, Depends
from sqlalchemy import select

from app.api.v1.deps import DbSession, require_permission
from app.models.audit import AuditLog
from app.schemas.audit import AuditRead

router = APIRouter()


@router.get("", response_model=list[AuditRead])
def list_audit_logs(
    db: DbSession,
    _=Depends(require_permission("audit.read")),
) -> list[AuditRead]:
    rows = db.scalars(select(AuditLog).order_by(AuditLog.created_at.desc()).limit(200)).all()
    return [
        AuditRead(
            id=row.id,
            actor_id=row.actor_id,
            action=row.action,
            entity=row.entity,
            entity_id=row.entity_id,
            metadata=row.audit_metadata,
            created_at=row.created_at,
        )
        for row in rows
    ]

