from fastapi import APIRouter, Depends
from sqlalchemy import select

from app.api.v1.deps import DbSession, require_permission
from app.models.setting import PlatformSetting
from app.models.user import User
from app.schemas.setting import SettingRead, SettingUpdate
from app.services.audit_service import record_audit

router = APIRouter()


@router.get("", response_model=SettingRead)
def get_settings(
    db: DbSession, _=Depends(require_permission("settings.manage"))
) -> PlatformSetting:
    return _settings(db)


@router.put("", response_model=SettingRead)
def update_settings(
    payload: SettingUpdate,
    db: DbSession,
    actor: User = Depends(require_permission("settings.manage")),
) -> PlatformSetting:
    settings = _settings(db)
    for key, value in payload.model_dump().items():
        setattr(settings, key, value)
    record_audit(db, action="Settings Changes", entity="settings", actor_id=actor.id)
    db.commit()
    db.refresh(settings)
    return settings


def _settings(db: DbSession) -> PlatformSetting:
    settings = db.scalar(select(PlatformSetting))
    if settings is None:
        settings = PlatformSetting()
        db.add(settings)
        db.commit()
        db.refresh(settings)
    return settings
