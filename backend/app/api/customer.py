import uuid
from typing import Optional

from fastapi import APIRouter, Depends, Query, status

from app.api.dependencies import get_current_user, get_customer_service
from app.core.authorization import require_permission
from app.models.user import User
from app.schemas.base import MessageResponse
from app.schemas.customer import (
    CustomerCreate,
    CustomerDetailResponse,
    CustomerSortField,
    CustomerStatus,
    CustomerType,
    CustomerUpdate,
    SortOrder,
)
from app.schemas.pagination import PaginatedResponse
from app.services.customer import CustomerService

router = APIRouter()


@router.post(
    "/",
    response_model=CustomerDetailResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new customer",
)
@require_permission("customer.create")
async def create_customer(
    customer_in: CustomerCreate,
    customer_service: CustomerService = Depends(get_customer_service),
    current_user: User = Depends(get_current_user),
) -> CustomerDetailResponse:
    """Create a new customer. Requires 'customer.create' permission."""
    return await customer_service.create_customer(
        customer_in, performing_user_id=current_user.id
    )


@router.get(
    "/",
    response_model=PaginatedResponse[CustomerDetailResponse],
    status_code=status.HTTP_200_OK,
    summary="List customers with search, pagination, sorting and filtering",
)
@require_permission("customer.view")
async def list_customers(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100),
    search: Optional[str] = Query(
        None,
        description="Search across name, email, mobile, address, and GST number",
    ),
    customer_type: Optional[CustomerType] = Query(
        None, description="Filter by customer type"
    ),
    status: Optional[CustomerStatus] = Query(
        None, description="Filter by customer status"
    ),
    sort_by: CustomerSortField = Query(
        "created_at", description="Field to sort results by"
    ),
    sort_order: SortOrder = Query("desc", description="Sort direction"),
    customer_service: CustomerService = Depends(get_customer_service),
    current_user: User = Depends(get_current_user),
) -> PaginatedResponse[CustomerDetailResponse]:
    """Retrieve customers matching parameters. Requires 'customer.view' permission."""
    items, total = await customer_service.list_customers(
        skip=skip,
        limit=limit,
        search=search,
        customer_type=customer_type,
        status=status,
        sort_by=sort_by,
        sort_order=sort_order,
    )
    return PaginatedResponse(
        items=items,
        total=total,
        skip=skip,
        limit=limit,
    )


@router.get(
    "/{id}",
    response_model=CustomerDetailResponse,
    status_code=status.HTTP_200_OK,
    summary="Get customer details by ID",
)
@require_permission("customer.view")
async def get_customer(
    id: uuid.UUID,
    customer_service: CustomerService = Depends(get_customer_service),
    current_user: User = Depends(get_current_user),
) -> CustomerDetailResponse:
    """Retrieve details of a specific customer. Requires 'customer.view' permission."""
    return await customer_service.get_customer_by_id(id)


@router.put(
    "/{id}",
    response_model=CustomerDetailResponse,
    status_code=status.HTTP_200_OK,
    summary="Update customer attributes",
)
@require_permission("customer.update")
async def update_customer(
    id: uuid.UUID,
    customer_in: CustomerUpdate,
    customer_service: CustomerService = Depends(get_customer_service),
    current_user: User = Depends(get_current_user),
) -> CustomerDetailResponse:
    """Update customer attributes. Requires 'customer.update' permission."""
    return await customer_service.update_customer(
        id, customer_in, performing_user_id=current_user.id
    )


@router.delete(
    "/{id}",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Delete customer (soft delete)",
)
@require_permission("customer.delete")
async def delete_customer(
    id: uuid.UUID,
    customer_service: CustomerService = Depends(get_customer_service),
    current_user: User = Depends(get_current_user),
) -> MessageResponse:
    """Soft delete a customer. Requires 'customer.delete' permission."""
    await customer_service.delete_customer(id, performing_user_id=current_user.id)
    return MessageResponse(message="Customer deleted successfully")
