from decimal import Decimal
from typing import Any
from uuid import uuid4

import pytest
from inventory_service.inventory.adapters.api.http.schemas import (
    CreateProductRequest,
    ProductResponse,
)
from pydantic import ValidationError


def test_create_product_request_accepts_valid_payload() -> None:
    payload = CreateProductRequest(
        name="Headset",
        sku="HS-001",
        price=Decimal("89.90"),
        stock=12,
    )

    assert payload.name == "Headset"
    assert payload.sku == "HS-001"
    assert payload.price == Decimal("89.90")
    assert payload.stock == 12


@pytest.mark.parametrize(
    "kwargs",
    [
        {"name": "", "sku": "HS-001", "price": Decimal("1.00"), "stock": 1},
        {"name": "Headset", "sku": "", "price": Decimal("1.00"), "stock": 1},
        {"name": "Headset", "sku": "HS-001", "price": Decimal("-1"), "stock": 1},
        {"name": "Headset", "sku": "HS-001", "price": Decimal("1.00"), "stock": -1},
    ],
)
def test_create_product_request_rejects_invalid_payload(kwargs: dict[str, Any]) -> None:
    with pytest.raises(ValidationError):
        CreateProductRequest.model_validate(kwargs)


def test_product_response_schema_roundtrip() -> None:
    product_id = uuid4()
    response = ProductResponse(
        id=product_id,
        name="Keyboard",
        sku="KB-200",
        price=Decimal("120.00"),
        stock=5,
    )

    assert response.id == product_id
    assert response.model_dump()["sku"] == "KB-200"
