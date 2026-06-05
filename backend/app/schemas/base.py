from typing import Optional
from pydantic import BaseModel

class MessageResponse(BaseModel):
    """Standard generic success message schema."""
    message: str

class ErrorDetail(BaseModel):
    """Schema detailing an API failure."""
    message: str
    type: str
    status_code: int

class ErrorResponse(BaseModel):
    """Envelope standardizing error responses."""
    error: ErrorDetail

class HealthResponse(BaseModel):
    """Schema defining the health check endpoint response."""
    status: str
    service: str
