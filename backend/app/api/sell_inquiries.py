from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Query, status

from app.api.dependencies import get_current_user, get_gold_sell_inquiry_service
from app.core.authorization import PermissionChecker
from app.models.user import User
from app.schemas.gold_sell_inquiry import (
    GoldSellInquiryCreate,
    GoldSellInquiryListResponse,
    GoldSellInquiryRespond,
    GoldSellInquiryResponse,
)
from app.services.gold_sell_inquiry import GoldSellInquiryService

router = APIRouter()


@router.post(
    "",
    response_model=GoldSellInquiryResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Submit a gold sell inquiry",
)
async def create_sell_inquiry(
    body: GoldSellInquiryCreate,
    current_user: User = Depends(get_current_user),
    service: GoldSellInquiryService = Depends(get_gold_sell_inquiry_service),
) -> GoldSellInquiryResponse:
    return await service.create_inquiry(current_user, body)


@router.get(
    "/mine",
    response_model=GoldSellInquiryListResponse,
    summary="List current user's sell inquiries",
)
async def list_my_sell_inquiries(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    service: GoldSellInquiryService = Depends(get_gold_sell_inquiry_service),
) -> GoldSellInquiryListResponse:
    return await service.list_my_inquiries(current_user, skip=skip, limit=limit)


@router.get(
    "",
    response_model=GoldSellInquiryListResponse,
    summary="List all sell inquiries (admin)",
)
async def list_sell_inquiries(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    status: Optional[str] = Query(None, pattern=r"^(pending|responded|closed)$"),
    current_user: User = Depends(PermissionChecker("transaction.view")),
    service: GoldSellInquiryService = Depends(get_gold_sell_inquiry_service),
) -> GoldSellInquiryListResponse:
    return await service.list_inquiries(skip=skip, limit=limit, status=status)


@router.patch(
    "/{inquiry_id}/respond",
    response_model=GoldSellInquiryResponse,
    summary="Respond to a sell inquiry (admin)",
)
async def respond_to_sell_inquiry(
    inquiry_id: UUID,
    body: GoldSellInquiryRespond,
    current_user: User = Depends(PermissionChecker("transaction.view")),
    service: GoldSellInquiryService = Depends(get_gold_sell_inquiry_service),
) -> GoldSellInquiryResponse:
    return await service.respond_to_inquiry(inquiry_id, current_user, body)
