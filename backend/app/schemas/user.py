from pydantic import BaseModel, ConfigDict, EmailStr, Field


class UserRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    first_name: str
    last_name: str
    email: EmailStr
    mobile_number: str
    role: str
    is_active: bool
    email_verified: bool


class UserCreate(BaseModel):
    first_name: str = Field(min_length=1)
    last_name: str = Field(min_length=1)
    email: EmailStr
    mobile_number: str
    password: str = Field(min_length=8)
    role: str = "USER"


class UserUpdate(BaseModel):
    first_name: str | None = None
    last_name: str | None = None
    mobile_number: str | None = None
    role: str | None = None
    is_active: bool | None = None
