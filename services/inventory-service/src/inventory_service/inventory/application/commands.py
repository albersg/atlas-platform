from dataclasses import dataclass
from decimal import Decimal


@dataclass(frozen=True)
class CreateProductCommand:
    name: str
    sku: str
    price: Decimal
    stock: int
