from datetime import datetime

from pydantic import BaseModel, ConfigDict


class AuditRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    actor_id: int | None
    action: str
    entity: str
    entity_id: str | None
    metadata: dict
    created_at: datetime
