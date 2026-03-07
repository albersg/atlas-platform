from dataclasses import dataclass
from decimal import Decimal
from uuid import UUID, uuid4


@dataclass
class Product:
    id: UUID
    name: str
    sku: str
    price: Decimal
    stock: int

    @classmethod
    def create(cls, name: str, sku: str, price: Decimal, stock: int) -> "Product":
        if not name.strip():
            raise ValueError("name cannot be empty")
        if not sku.strip():
            raise ValueError("sku cannot be empty")
        if price < Decimal("0"):
            raise ValueError("price cannot be negative")
        if stock < 0:
            raise ValueError("stock cannot be negative")

        return cls(id=uuid4(), name=name.strip(), sku=sku.strip(), price=price, stock=stock)
