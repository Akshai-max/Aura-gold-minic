import uuid
from typing import Optional

from fastapi import APIRouter, Depends, Query, status

from app.api.dependencies import get_current_user, get_transaction_service
from app.core.authorization import require_permission
from app.models.user import User
from app.schemas.pagination import PaginatedResponse
from app.schemas.transaction import (
    PaymentStatus,
    SortOrder,
    TransactionCancelRequest,
    TransactionCreate,
    TransactionDetailResponse,
    TransactionDocumentResponse,
    TransactionMetricsResponse,
    TransactionSortField,
    TransactionStatus,
    TransactionType,
    TransactionUpdate,
)
from app.services.transaction import TransactionService

router = APIRouter()


@router.post(
    "/",
    response_model=TransactionDetailResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a transaction",
)
@require_permission("transaction.create")
async def create_transaction(
    txn_in: TransactionCreate,
    transaction_service: TransactionService = Depends(get_transaction_service),
    current_user: User = Depends(get_current_user),
) -> TransactionDetailResponse:
    return await transaction_service.create_transaction(
        txn_in, performing_user_id=current_user.id
    )


@router.get(
    "/",
    response_model=PaginatedResponse[TransactionDetailResponse],
    status_code=status.HTTP_200_OK,
    summary="List transactions",
)
@require_permission("transaction.view")
async def list_transactions(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100),
    search: Optional[str] = Query(None),
    transaction_type: Optional[TransactionType] = Query(None),
    payment_status: Optional[PaymentStatus] = Query(None),
    status: Optional[TransactionStatus] = Query(None),
    customer_id: Optional[uuid.UUID] = Query(None),
    sort_by: TransactionSortField = Query("created_at"),
    sort_order: SortOrder = Query("desc"),
    transaction_service: TransactionService = Depends(get_transaction_service),
    current_user: User = Depends(get_current_user),
) -> PaginatedResponse[TransactionDetailResponse]:
    items, total = await transaction_service.list_transactions(
        skip=skip,
        limit=limit,
        search=search,
        transaction_type=transaction_type,
        payment_status=payment_status,
        status=status,
        customer_id=customer_id,
        sort_by=sort_by,
        sort_order=sort_order,
    )
    return PaginatedResponse(items=items, total=total, skip=skip, limit=limit)


@router.get(
    "/metrics",
    response_model=TransactionMetricsResponse,
    status_code=status.HTTP_200_OK,
    summary="Transaction revenue metrics",
)
@require_permission("transaction.view")
async def get_transaction_metrics(
    transaction_service: TransactionService = Depends(get_transaction_service),
    current_user: User = Depends(get_current_user),
) -> TransactionMetricsResponse:
    return await transaction_service.get_metrics()


@router.get(
    "/{id}",
    response_model=TransactionDetailResponse,
    status_code=status.HTTP_200_OK,
    summary="Get transaction details",
)
@require_permission("transaction.view")
async def get_transaction(
    id: uuid.UUID,
    transaction_service: TransactionService = Depends(get_transaction_service),
    current_user: User = Depends(get_current_user),
) -> TransactionDetailResponse:
    return await transaction_service.get_transaction_by_id(id)


@router.put(
    "/{id}",
    response_model=TransactionDetailResponse,
    status_code=status.HTTP_200_OK,
    summary="Update a transaction",
)
@require_permission("transaction.update")
async def update_transaction(
    id: uuid.UUID,
    txn_in: TransactionUpdate,
    transaction_service: TransactionService = Depends(get_transaction_service),
    current_user: User = Depends(get_current_user),
) -> TransactionDetailResponse:
    return await transaction_service.update_transaction(
        id, txn_in, performing_user_id=current_user.id
    )


@router.post(
    "/{id}/cancel",
    response_model=TransactionDetailResponse,
    status_code=status.HTTP_200_OK,
    summary="Cancel a transaction",
)
@require_permission("transaction.update")
async def cancel_transaction(
    id: uuid.UUID,
    cancel_in: TransactionCancelRequest,
    transaction_service: TransactionService = Depends(get_transaction_service),
    current_user: User = Depends(get_current_user),
) -> TransactionDetailResponse:
    return await transaction_service.cancel_transaction(
        id, cancel_in, performing_user_id=current_user.id
    )


@router.get(
    "/{id}/invoice",
    response_model=TransactionDocumentResponse,
    status_code=status.HTTP_200_OK,
    summary="Generate invoice for a transaction",
)
@require_permission("transaction.view")
async def generate_invoice(
    id: uuid.UUID,
    transaction_service: TransactionService = Depends(get_transaction_service),
    current_user: User = Depends(get_current_user),
) -> TransactionDocumentResponse:
    return await transaction_service.generate_invoice(id)


@router.get(
    "/{id}/receipt",
    response_model=TransactionDocumentResponse,
    status_code=status.HTTP_200_OK,
    summary="Generate receipt for a paid transaction",
)
@require_permission("transaction.view")
async def generate_receipt(
    id: uuid.UUID,
    transaction_service: TransactionService = Depends(get_transaction_service),
    current_user: User = Depends(get_current_user),
) -> TransactionDocumentResponse:
    return await transaction_service.generate_receipt(id)
