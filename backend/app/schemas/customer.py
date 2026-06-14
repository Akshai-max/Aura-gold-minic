import re
import uuid
from datetime import datetime
from decimal import Decimal
from typing import Literal, Optional

from pydantic import BaseModel, Field, field_validator

EMAIL_REGEX = re.compile(r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$")
MOBILE_REGEX = re.compile(r"^\+?[0-9]{7,15}$")
GST_REGEX = re.compile(r"^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$")

CustomerType = Literal["individual", "business"]
CustomerStatus = Literal["active", "inactive", "blacklisted"]
CustomerSortField = Literal[
    "full_name",
    "created_at",
    "total_revenue",
    "total_purchases",
    "last_transaction_date",
    "status",
    "customer_type",
]
SortOrder = Literal["asc", "desc"]


class CustomerCreate(BaseModel):
    """Schema for creating a new customer."""

    customer_type: CustomerType
    full_name: str = Field(..., min_length=1, max_length=200)
    mobile_number: str = Field(..., min_length=7, max_length=20)
    email: str
    address: str = Field(..., min_length=1)
    gst_number: Optional[str] = Field(None, max_length=15)
    status: CustomerStatus = "active"

    @field_validator("email")
    @classmethod
    def validate_email(cls, v: str) -> str:
        if not EMAIL_REGEX.match(v):
            raise ValueError("Invalid email format")
        return v.lower()

    @field_validator("mobile_number")
    @classmethod
    def validate_mobile(cls, v: str) -> str:
        cleaned = v.replace(" ", "").replace("-", "")
        if not MOBILE_REGEX.match(cleaned):
            raise ValueError("Invalid mobile number format")
        return cleaned

    @field_validator("gst_number")
    @classmethod
    def validate_gst(cls, v: Optional[str]) -> Optional[str]:
        if v is None or v == "":
            return None
        normalized = v.upper().strip()
        if not GST_REGEX.match(normalized):
            raise ValueError("Invalid GST number format")
        return normalized


class CustomerUpdate(BaseModel):
    """Schema for updating an existing customer."""

    customer_type: Optional[CustomerType] = None
    full_name: Optional[str] = Field(None, min_length=1, max_length=200)
    mobile_number: Optional[str] = Field(None, min_length=7, max_length=20)
    email: Optional[str] = None
    address: Optional[str] = Field(None, min_length=1)
    gst_number: Optional[str] = Field(None, max_length=15)
    status: Optional[CustomerStatus] = None

    @field_validator("email")
    @classmethod
    def validate_email(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        if not EMAIL_REGEX.match(v):
            raise ValueError("Invalid email format")
        return v.lower()

    @field_validator("mobile_number")
    @classmethod
    def validate_mobile(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        cleaned = v.replace(" ", "").replace("-", "")
        if not MOBILE_REGEX.match(cleaned):
            raise ValueError("Invalid mobile number format")
        return cleaned

    @field_validator("gst_number")
    @classmethod
    def validate_gst(cls, v: Optional[str]) -> Optional[str]:
        if v is None or v == "":
            return None
        normalized = v.upper().strip()
        if not GST_REGEX.match(normalized):
            raise ValueError("Invalid GST number format")
        return normalized


class CustomerDetailResponse(BaseModel):
    """Detailed customer schema returned by the APIs."""

    id: uuid.UUID
    customer_type: str
    full_name: str
    mobile_number: str
    email: str
    address: str
    gst_number: Optional[str] = None
    status: str
    total_purchases: int
    total_revenue: Decimal
    last_transaction_date: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
