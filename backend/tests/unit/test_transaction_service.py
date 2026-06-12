import uuid
from datetime import datetime, timezone
from decimal import Decimal
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.core.exceptions import NotFoundException, ValidationException
from app.models.transaction import Transaction, TransactionLine
from app.repositories.customer import CustomerRepository
from app.repositories.inventory_item import InventoryItemRepository
from app.repositories.transaction import TransactionRepository
from app.schemas.transaction import (
    TransactionCancelRequest,
    TransactionCreate,
    TransactionLineCreate,
    TransactionUpdate,
)
from app.services.audit import AuditService
from app.services.customer import CustomerService
from app.services.inventory import InventoryService
from app.services.transaction import TransactionService


@pytest.fixture
def mock_transaction_repo():
    repo = MagicMock(spec=TransactionRepository)
    repo.db = MagicMock()
    repo.db.add = MagicMock()
    repo.db.flush = AsyncMock()
    repo.db.commit = AsyncMock()
    repo.db.refresh = AsyncMock()
    repo.db.rollback = AsyncMock()
    return repo


@pytest.fixture
def mock_customer_repo():
    return MagicMock(spec=CustomerRepository)


@pytest.fixture
def mock_inventory_repo():
    return MagicMock(spec=InventoryItemRepository)


@pytest.fixture
def mock_customer_service():
    service = MagicMock(spec=CustomerService)
    service.record_transaction_metrics = AsyncMock()
    return service


@pytest.fixture
def mock_inventory_service():
    service = MagicMock(spec=InventoryService)
    service.apply_transaction_stock_line = AsyncMock()
    return service


@pytest.fixture
def mock_audit_service():
    service = MagicMock(spec=AuditService)
    service.log_action = AsyncMock()
    return service


@pytest.fixture
def transaction_service(
    mock_transaction_repo,
    mock_customer_repo,
    mock_inventory_repo,
    mock_customer_service,
    mock_inventory_service,
    mock_audit_service,
):
    return TransactionService(
        mock_transaction_repo,
        mock_customer_repo,
        mock_inventory_repo,
        mock_customer_service,
        mock_inventory_service,
        mock_audit_service,
    )


def _sample_item(item_id=None):
    item = MagicMock()
    item.id = item_id or uuid.uuid4()
    item.item_name = "Gold Bar"
    item.status = "active"
    item.current_value = Decimal("1000.00")
    return item


def _sample_customer(customer_id=None):
    customer = MagicMock()
    customer.id = customer_id or uuid.uuid4()
    customer.status = "active"
    return customer


@pytest.mark.asyncio
async def test_get_transaction_not_found(transaction_service, mock_transaction_repo):
    mock_transaction_repo.get_with_details = AsyncMock(return_value=None)
    with pytest.raises(NotFoundException):
        await transaction_service.get_transaction_by_id(uuid.uuid4())


@pytest.mark.asyncio
async def test_create_paid_sale_applies_stock_and_metrics(
    transaction_service,
    mock_transaction_repo,
    mock_customer_repo,
    mock_inventory_repo,
    mock_inventory_service,
    mock_customer_service,
):
    customer_id = uuid.uuid4()
    item_id = uuid.uuid4()
    mock_customer_repo.get_active = AsyncMock(return_value=_sample_customer(customer_id))
    mock_inventory_repo.get_active = AsyncMock(return_value=_sample_item(item_id))
    mock_transaction_repo.next_document_number = AsyncMock(return_value="TXN-20260608-0001")

    created_txn = Transaction(
        id=uuid.uuid4(),
        transaction_number="TXN-20260608-0001",
        transaction_type="sale",
        customer_id=customer_id,
        status="active",
        payment_status="paid",
        subtotal=Decimal("1000.00"),
        tax_amount=Decimal("0"),
        total_amount=Decimal("1000.00"),
        stock_applied=True,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    created_txn.lines = [
        TransactionLine(
            id=uuid.uuid4(),
            transaction_id=created_txn.id,
            inventory_item_id=item_id,
            item_name="Gold Bar",
            quantity=1,
            unit_price=Decimal("1000.00"),
            line_total=Decimal("1000.00"),
            stock_direction="out",
        )
    ]
    mock_transaction_repo.get_with_details = AsyncMock(return_value=created_txn)

    txn_in = TransactionCreate(
        transaction_type="sale",
        customer_id=customer_id,
        payment_status="paid",
        lines=[
            TransactionLineCreate(
                inventory_item_id=item_id,
                quantity=1,
                unit_price=Decimal("1000.00"),
            )
        ],
    )

    result = await transaction_service.create_transaction(
        txn_in, performing_user_id=uuid.uuid4()
    )

    assert result.transaction_number.startswith("TXN-")
    mock_inventory_service.apply_transaction_stock_line.assert_called_once()
    mock_customer_service.record_transaction_metrics.assert_called_once()
    mock_transaction_repo.db.commit.assert_called_once()


@pytest.mark.asyncio
async def test_cancel_transaction_reverses_stock(
    transaction_service,
    mock_transaction_repo,
    mock_inventory_service,
):
    txn = Transaction(
        id=uuid.uuid4(),
        transaction_number="TXN-20260608-0002",
        transaction_type="sale",
        customer_id=uuid.uuid4(),
        status="active",
        payment_status="paid",
        subtotal=Decimal("500.00"),
        tax_amount=Decimal("0"),
        total_amount=Decimal("500.00"),
        stock_applied=True,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    txn.lines = [
        TransactionLine(
            id=uuid.uuid4(),
            transaction_id=txn.id,
            inventory_item_id=uuid.uuid4(),
            item_name="Coin",
            quantity=1,
            unit_price=Decimal("500.00"),
            line_total=Decimal("500.00"),
            stock_direction="out",
        )
    ]
    mock_transaction_repo.get_with_details = AsyncMock(return_value=txn)
    mock_transaction_repo.db.commit = AsyncMock()

    await transaction_service.cancel_transaction(
        txn.id,
        TransactionCancelRequest(reason="Duplicate entry"),
        performing_user_id=uuid.uuid4(),
    )

    mock_inventory_service.apply_transaction_stock_line.assert_called_once()
    assert mock_inventory_service.apply_transaction_stock_line.call_args.kwargs["reverse"] is True


@pytest.mark.asyncio
async def test_update_cancelled_transaction_raises(
    transaction_service, mock_transaction_repo
):
    txn = MagicMock()
    txn.status = "cancelled"
    mock_transaction_repo.get_with_details = AsyncMock(return_value=txn)

    with pytest.raises(ValidationException, match="Cancelled"):
        await transaction_service.update_transaction(
            uuid.uuid4(),
            TransactionUpdate(notes="Nope"),
        )
