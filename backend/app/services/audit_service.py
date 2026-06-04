from sqlalchemy.orm import Session

from app.models.audit import AuditLog


def record_audit(
    db: Session,
    *,
    action: str,
    entity: str,
    actor_id: int | None = None,
    entity_id: str | None = None,
    metadata: dict | None = None,
) -> None:
    db.add(
        AuditLog(
            actor_id=actor_id,
            action=action,
            entity=entity,
            entity_id=entity_id,
            audit_metadata=metadata or {},
        )
    )
