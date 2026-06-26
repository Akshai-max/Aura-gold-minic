from fastapi import APIRouter, Depends, status

from app.api.dependencies import get_current_user, get_referral_service
from app.models.user import User
from app.schemas.referral import ReferralSummaryResponse
from app.services.referral import ReferralService

router = APIRouter()


@router.get(
    "/me",
    response_model=ReferralSummaryResponse,
    status_code=status.HTTP_200_OK,
    summary="Refer-and-earn summary and wallet balance",
)
async def get_referral_summary(
    current_user: User = Depends(get_current_user),
    referral_service: ReferralService = Depends(get_referral_service),
) -> ReferralSummaryResponse:
    return await referral_service.get_summary(current_user)
