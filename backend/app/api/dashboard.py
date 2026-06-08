from fastapi import APIRouter, Depends, status

from app.api.dependencies import get_current_user, get_dashboard_service
from app.models.user import User
from app.schemas.dashboard import DashboardStatsResponse
from app.services.dashboard import DashboardService

router = APIRouter()


@router.get(
    "/stats",
    response_model=DashboardStatsResponse,
    status_code=status.HTTP_200_OK,
    summary="Get dashboard statistics and widget data",
)
async def get_dashboard_stats(
    current_user: User = Depends(get_current_user),
    dashboard_service: DashboardService = Depends(get_dashboard_service),
) -> DashboardStatsResponse:
    stats = await dashboard_service.get_stats(current_user)
    return DashboardStatsResponse(**stats)
