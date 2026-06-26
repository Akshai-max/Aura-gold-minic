from decimal import Decimal

from fastapi import APIRouter, Depends, status

from app.api.dependencies import get_current_user, get_gold_scheme_service
from app.models.user import User
from app.schemas.gold_scheme import GoldSchemeResponse, SelectGoldSchemeRequest
from app.services.gold_scheme import GoldSchemeService

router = APIRouter()


@router.get(
    "",
    response_model=GoldSchemeResponse,
    status_code=status.HTTP_200_OK,
    summary="Get current gold savings scheme",
)
async def get_gold_scheme(
    current_user: User = Depends(get_current_user),
    scheme_service: GoldSchemeService = Depends(get_gold_scheme_service),
) -> GoldSchemeResponse:
    return scheme_service.build_response(current_user)


@router.post(
    "/select",
    response_model=GoldSchemeResponse,
    status_code=status.HTTP_200_OK,
    summary="Choose a 1 g, 5 g, or 10 g gold savings scheme",
)
async def select_gold_scheme(
    body: SelectGoldSchemeRequest,
    current_user: User = Depends(get_current_user),
    scheme_service: GoldSchemeService = Depends(get_gold_scheme_service),
) -> GoldSchemeResponse:
    return await scheme_service.select_scheme(
        current_user,
        target_grams=Decimal(str(body.target_grams)),
    )
