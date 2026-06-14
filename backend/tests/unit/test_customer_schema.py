import pytest
from pydantic import ValidationError

from app.schemas.customer import CustomerCreate, CustomerUpdate


def test_customer_create_validates_email():
    customer = CustomerCreate(
        customer_type="individual",
        full_name="John Doe",
        mobile_number="+919876543210",
        email="john@example.com",
        address="123 Main Street",
    )
    assert customer.email == "john@example.com"


def test_customer_create_rejects_invalid_email():
    with pytest.raises(ValidationError):
        CustomerCreate(
            customer_type="individual",
            full_name="John Doe",
            mobile_number="+919876543210",
            email="not-an-email",
            address="123 Main Street",
        )


def test_customer_create_validates_gst():
    customer = CustomerCreate(
        customer_type="business",
        full_name="Gold Corp",
        mobile_number="+919876543210",
        email="corp@example.com",
        address="456 Market Road",
        gst_number="27AAAAA0000A1Z5",
    )
    assert customer.gst_number == "27AAAAA0000A1Z5"


def test_customer_create_rejects_invalid_gst():
    with pytest.raises(ValidationError):
        CustomerCreate(
            customer_type="business",
            full_name="Gold Corp",
            mobile_number="+919876543210",
            email="corp@example.com",
            address="456 Market Road",
            gst_number="INVALID",
        )


def test_customer_update_partial_fields():
    update = CustomerUpdate(full_name="Jane Doe", status="inactive")
    data = update.model_dump(exclude_unset=True)
    assert data == {"full_name": "Jane Doe", "status": "inactive"}
