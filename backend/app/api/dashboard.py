from fastapi import APIRouter, Depends, Query, status

from app.api.dependencies import (
    get_current_user,
    get_dashboard_service,
    get_executive_dashboard_service,
    get_metal_price_service,
    get_personal_dashboard_service,
)
from app.core.authorization import require_permission
from app.models.user import User
from app.schemas.dashboard import (
    DashboardStatsResponse,
    ExecutiveDashboardResponse,
    MetalPricesResponse,
    MetalHistoryResponse,
    PersonalDashboardResponse,
)
from app.services.dashboard import DashboardService
from app.services.executive_dashboard import ExecutiveDashboardService
from app.services.metal_prices import MetalPriceService
from app.services.personal_dashboard import PersonalDashboardService

router = APIRouter()


@router.get(
    "/personal",
    response_model=PersonalDashboardResponse,
    status_code=status.HTTP_200_OK,
    summary="Get personal user dashboard",
)
async def get_personal_dashboard(
    current_user: User = Depends(get_current_user),
    personal_service: PersonalDashboardService = Depends(
        get_personal_dashboard_service
    ),
) -> PersonalDashboardResponse:
    return await personal_service.get_dashboard(current_user)


@router.get(
    "/metal-prices",
    response_model=MetalPricesResponse,
    status_code=status.HTTP_200_OK,
    summary="Get live gold and silver spot prices",
)
async def get_metal_prices(
    current_user: User = Depends(get_current_user),
    metal_service: MetalPriceService = Depends(get_metal_price_service),
) -> MetalPricesResponse:
    return await metal_service.get_prices()


@router.get(
    "/metal-prices/history",
    response_model=MetalHistoryResponse,
    status_code=status.HTTP_200_OK,
    summary="Get historical gold or silver price chart data",
)
async def get_metal_price_history(
    metal: str = Query("gold", pattern="^(gold|silver)$"),
    range_key: str = Query("1Y", alias="range", pattern="^(1M|3M|6M|1Y|3Y)$"),
    current_user: User = Depends(get_current_user),
    metal_service: MetalPriceService = Depends(get_metal_price_service),
) -> MetalHistoryResponse:
    return await metal_service.get_history(metal, range_key)  # type: ignore[arg-type]


@router.get(
    "/stats",
    response_model=DashboardStatsResponse,
    status_code=status.HTTP_200_OK,
    summary="Get dashboard statistics and widget data",
)
@require_permission("dashboard.view")
async def get_dashboard_stats(
    current_user: User = Depends(get_current_user),
    dashboard_service: DashboardService = Depends(get_dashboard_service),
) -> DashboardStatsResponse:
    stats = await dashboard_service.get_stats(current_user)
    return DashboardStatsResponse(**stats)


@router.get(
    "/executive",
    response_model=ExecutiveDashboardResponse,
    status_code=status.HTTP_200_OK,
    summary="Get role-based executive dashboard",
)
@require_permission("dashboard.view")
async def get_executive_dashboard(
    current_user: User = Depends(get_current_user),
    executive_service: ExecutiveDashboardService = Depends(
        get_executive_dashboard_service
    ),
) -> ExecutiveDashboardResponse:
    return await executive_service.get_dashboard(current_user)
