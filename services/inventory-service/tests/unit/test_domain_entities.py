from decimal import Decimal
from uuid import UUID

import pytest
from inventory_service.inventory.domain.entities import Product


def test_product_create_trims_values_and_generates_uuid() -> None:
    product = Product.create(
        name="  Mechanical Keyboard  ",
        sku="  KB-001  ",
        price=Decimal("129.90"),
        stock=10,
    )

    assert product.name == "Mechanical Keyboard"
    assert product.sku == "KB-001"
    assert product.price == Decimal("129.90")
    assert product.stock == 10
    assert isinstance(product.id, UUID)


@pytest.mark.parametrize(
    ("kwargs", "message"),
    [
        ({"name": "   "}, "name cannot be empty"),
        ({"sku": "   "}, "sku cannot be empty"),
        ({"price": Decimal("-0.01")}, "price cannot be negative"),
        ({"stock": -1}, "stock cannot be negative"),
    ],
)
def test_product_create_validates_invariants(kwargs: dict[str, object], message: str) -> None:
    payload = {
        "name": "Mouse",
        "sku": "MS-001",
        "price": Decimal("49.99"),
        "stock": 4,
    }
    payload.update(kwargs)

    with pytest.raises(ValueError, match=message):
        Product.create(**payload)
