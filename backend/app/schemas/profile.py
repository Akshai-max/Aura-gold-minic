import uuid
from datetime import datetime
from typing import List, Optional
import re
from pydantic import BaseModel, Field, field_validator
from app.schemas.rbac import RoleResponse
from app.schemas.audit_log import AuditLogResponse

EMAIL_REGEX = re.compile(r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$")


class ProfileUpdate(BaseModel):
    first_name: Optional[str] = Field(None, max_length=100)
    last_name: Optional[str] = Field(None, max_length=100)
    email: Optional[str] = None
    current_password: Optional[str] = Field(
        None, description="Required when changing email"
    )

    @field_validator("email")
    @classmethod
    def validate_email(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        if not EMAIL_REGEX.match(v):
            raise ValueError("Invalid email format")
        return v.lower()


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str = Field(..., min_length=8)


class AvatarUploadRequest(BaseModel):
    avatar_base64: str
    content_type: str = Field(..., pattern=r"^image/(jpeg|png|gif|webp)$")


class UserSettingsResponse(BaseModel):
    locale: str
    notification_email_enabled: bool
    notification_push_enabled: bool
    notification_security_alerts: bool
    notification_system_updates: bool

    model_config = {"from_attributes": True}


class UserSettingsUpdate(BaseModel):
    locale: Optional[str] = Field(None, max_length=10)
    notification_email_enabled: Optional[bool] = None
    notification_push_enabled: Optional[bool] = None
    notification_security_alerts: Optional[bool] = None
    notification_system_updates: Optional[bool] = None


class ProfileResponse(BaseModel):
    id: uuid.UUID
    email: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    is_active: bool
    is_superuser: bool
    roles: List[RoleResponse] = []
    has_avatar: bool = False
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class ProfileActivityResponse(BaseModel):
    items: List[AuditLogResponse]
    total: int
