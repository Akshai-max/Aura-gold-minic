from pydantic import BaseModel, ConfigDict, EmailStr


class SettingRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    platform_name: str
    support_email: EmailStr
    contact_number: str
    maintenance_mode: bool
    app_version: str


class SettingUpdate(BaseModel):
    platform_name: str
    support_email: EmailStr
    contact_number: str
    maintenance_mode: bool
    app_version: str
