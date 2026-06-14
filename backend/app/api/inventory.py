import uuid
from typing import Optional

from fastapi import APIRouter, Depends, Query, status

from app.api.dependencies import get_current_user, get_inventory_service
from app.core.authorization import require_permission
from app.models.user import User
from app.schemas.base import MessageResponse
from app.schemas.inventory import (
    InventoryCategory,
    InventoryItemCreate,
    InventoryItemResponse,
    InventoryItemUpdate,
    InventoryMetricsResponse,
    InventorySortField,
    InventoryStatus,
    MovementType,
    SortOrder,
    StockAdjustRequest,
    StockInRequest,
    StockMovementResponse,
    StockOutRequest,
)
from app.schemas.pagination import PaginatedResponse
from app.services.inventory import InventoryService

router = APIRouter()


@router.post(
    "/",
    response_model=InventoryItemResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create inventory item",
)
@require_permission("inventory.create")
async def create_inventory_item(
    item_in: InventoryItemCreate,
    inventory_service: InventoryService = Depends(get_inventory_service),
    current_user: User = Depends(get_current_user),
) -> InventoryItemResponse:
    item = await inventory_service.create_item(
        item_in, performing_user_id=current_user.id
    )
    return InventoryItemResponse.from_model(item)


@router.get(
    "/",
    response_model=PaginatedResponse[InventoryItemResponse],
    status_code=status.HTTP_200_OK,
    summary="List inventory items",
)
@require_permission("inventory.view")
async def list_inventory_items(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100),
    search: Optional[str] = Query(None),
    item_category: Optional[InventoryCategory] = Query(None),
    status: Optional[InventoryStatus] = Query(None),
    supplier_id: Optional[uuid.UUID] = Query(None),
    low_stock_only: bool = Query(False),
    sort_by: InventorySortField = Query("created_at"),
    sort_order: SortOrder = Query("desc"),
    inventory_service: InventoryService = Depends(get_inventory_service),
    current_user: User = Depends(get_current_user),
) -> PaginatedResponse[InventoryItemResponse]:
    items, total = await inventory_service.list_items(
        skip=skip,
        limit=limit,
        search=search,
        item_category=item_category,
        status=status,
        supplier_id=str(supplier_id) if supplier_id else None,
        low_stock_only=low_stock_only,
        sort_by=sort_by,
        sort_order=sort_order,
    )
    return PaginatedResponse(
        items=[InventoryItemResponse.from_model(i) for i in items],
        total=total,
        skip=skip,
        limit=limit,
    )


@router.get(
    "/metrics",
    response_model=InventoryMetricsResponse,
    status_code=status.HTTP_200_OK,
    summary="Inventory dashboard metrics",
)
@require_permission("inventory.view")
async def get_inventory_metrics(
    inventory_service: InventoryService = Depends(get_inventory_service),
    current_user: User = Depends(get_current_user),
) -> InventoryMetricsResponse:
    return await inventory_service.get_metrics()


@router.get(
    "/low-stock",
    response_model=PaginatedResponse[InventoryItemResponse],
    status_code=status.HTTP_200_OK,
    summary="List low stock items",
)
@require_permission("inventory.view")
async def list_low_stock_items(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    inventory_service: InventoryService = Depends(get_inventory_service),
    current_user: User = Depends(get_current_user),
) -> PaginatedResponse[InventoryItemResponse]:
    items, total = await inventory_service.list_low_stock(skip=skip, limit=limit)
    return PaginatedResponse(
        items=[InventoryItemResponse.from_model(i) for i in items],
        total=total,
        skip=skip,
        limit=limit,
    )


@router.get(
    "/movements",
    response_model=PaginatedResponse[StockMovementResponse],
    status_code=status.HTTP_200_OK,
    summary="List all stock movements",
)
@require_permission("inventory.view")
async def list_all_movements(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    inventory_item_id: Optional[uuid.UUID] = Query(None),
    movement_type: Optional[MovementType] = Query(None),
    inventory_service: InventoryService = Depends(get_inventory_service),
    current_user: User = Depends(get_current_user),
) -> PaginatedResponse[StockMovementResponse]:
    items, total = await inventory_service.list_movements(
        skip=skip,
        limit=limit,
        inventory_item_id=inventory_item_id,
        movement_type=movement_type,
    )
    return PaginatedResponse(
        items=[StockMovementResponse.from_model(m) for m in items],
        total=total,
        skip=skip,
        limit=limit,
    )


@router.get(
    "/{item_id}",
    response_model=InventoryItemResponse,
    status_code=status.HTTP_200_OK,
    summary="Get inventory item by ID",
)
@require_permission("inventory.view")
async def get_inventory_item(
    item_id: uuid.UUID,
    inventory_service: InventoryService = Depends(get_inventory_service),
    current_user: User = Depends(get_current_user),
) -> InventoryItemResponse:
    item = await inventory_service.get_item_by_id(item_id)
    return InventoryItemResponse.from_model(item)


@router.put(
    "/{item_id}",
    response_model=InventoryItemResponse,
    status_code=status.HTTP_200_OK,
    summary="Update inventory item",
)
@require_permission("inventory.update")
async def update_inventory_item(
    item_id: uuid.UUID,
    item_in: InventoryItemUpdate,
    inventory_service: InventoryService = Depends(get_inventory_service),
    current_user: User = Depends(get_current_user),
) -> InventoryItemResponse:
    item = await inventory_service.update_item(
        item_id, item_in, performing_user_id=current_user.id
    )
    return InventoryItemResponse.from_model(item)


@router.delete(
    "/{item_id}",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Delete inventory item",
)
@require_permission("inventory.delete")
async def delete_inventory_item(
    item_id: uuid.UUID,
    inventory_service: InventoryService = Depends(get_inventory_service),
    current_user: User = Depends(get_current_user),
) -> MessageResponse:
    await inventory_service.delete_item(item_id, performing_user_id=current_user.id)
    return MessageResponse(message="Inventory item deleted successfully")


@router.post(
    "/{item_id}/stock-in",
    response_model=InventoryItemResponse,
    status_code=status.HTTP_200_OK,
    summary="Record stock in",
)
@require_permission("inventory.update")
async def stock_in(
    item_id: uuid.UUID,
    request: StockInRequest,
    inventory_service: InventoryService = Depends(get_inventory_service),
    current_user: User = Depends(get_current_user),
) -> InventoryItemResponse:
    item = await inventory_service.stock_in(
        item_id, request, performing_user_id=current_user.id
    )
    return InventoryItemResponse.from_model(item)


@router.post(
    "/{item_id}/stock-out",
    response_model=InventoryItemResponse,
    status_code=status.HTTP_200_OK,
    summary="Record stock out",
)
@require_permission("inventory.update")
async def stock_out(
    item_id: uuid.UUID,
    request: StockOutRequest,
    inventory_service: InventoryService = Depends(get_inventory_service),
    current_user: User = Depends(get_current_user),
) -> InventoryItemResponse:
    item = await inventory_service.stock_out(
        item_id, request, performing_user_id=current_user.id
    )
    return InventoryItemResponse.from_model(item)


@router.post(
    "/{item_id}/stock-adjust",
    response_model=InventoryItemResponse,
    status_code=status.HTTP_200_OK,
    summary="Adjust stock quantity",
)
@require_permission("inventory.update")
async def stock_adjust(
    item_id: uuid.UUID,
    request: StockAdjustRequest,
    inventory_service: InventoryService = Depends(get_inventory_service),
    current_user: User = Depends(get_current_user),
) -> InventoryItemResponse:
    item = await inventory_service.stock_adjust(
        item_id, request, performing_user_id=current_user.id
    )
    return InventoryItemResponse.from_model(item)


@router.get(
    "/{item_id}/movements",
    response_model=PaginatedResponse[StockMovementResponse],
    status_code=status.HTTP_200_OK,
    summary="List stock movements for an item",
)
@require_permission("inventory.view")
async def list_item_movements(
    item_id: uuid.UUID,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    inventory_service: InventoryService = Depends(get_inventory_service),
    current_user: User = Depends(get_current_user),
) -> PaginatedResponse[StockMovementResponse]:
    items, total = await inventory_service.list_movements_for_item(
        item_id, skip=skip, limit=limit
    )
    return PaginatedResponse(
        items=[StockMovementResponse.from_model(m) for m in items],
        total=total,
        skip=skip,
        limit=limit,
    )
