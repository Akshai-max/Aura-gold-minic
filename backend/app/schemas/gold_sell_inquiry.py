from datetime import datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, Field, field_validator

from app.schemas.auth import _normalize_mobile_input


class GoldSellInquiryCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=200)
    mobile_number: str = Field(..., min_length=10, max_length=15)
    message: str = Field(..., min_length=10, max_length=2000)

    @field_validator("name")
    @classmethod
    def strip_name(cls, value: str) -> str:
        return " ".join(value.strip().split())

    @field_validator("mobile_number")
    @classmethod
    def validate_mobile(cls, value: str) -> str:
        digits = _normalize_mobile_input(value)
        if len(digits) < 10:
            raise ValueError("Invalid mobile number")
        return digits

    @field_validator("message")
    @classmethod
    def strip_message(cls, value: str) -> str:
        return value.strip()


class GoldSellInquiryRespond(BaseModel):
    admin_response: str = Field(..., min_length=5, max_length=2000)
    status: str = Field(default="responded", pattern=r"^(responded|closed)$")

    @field_validator("admin_response")
    @classmethod
    def strip_response(cls, value: str) -> str:
        return value.strip()


class GoldSellInquiryResponse(BaseModel):
    id: UUID
    user_id: UUID
    name: str
    mobile_number: str
    message: str
    status: str
    admin_response: Optional[str] = None
    responded_by_user_id: Optional[UUID] = None
    responded_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
    user_email: Optional[str] = None

    model_config = {"from_attributes": True}


class GoldSellInquiryListResponse(BaseModel):
    items: List[GoldSellInquiryResponse]
    total: int
    skip: int
    limit: int
