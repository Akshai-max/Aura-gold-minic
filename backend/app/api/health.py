from fastapi import APIRouter, status
from app.schemas.base import HealthResponse

router = APIRouter()


@router.get("/health", response_model=HealthResponse, status_code=status.HTTP_200_OK)
async def health_check() -> HealthResponse:
    """Health check endpoint to verify the API is running."""
    return HealthResponse(status="healthy", service="ags-gold-api")
