from typing import Protocol
from uuid import UUID

from inventory_service.inventory.domain.entities import Product


class ProductRepository(Protocol):
    def add(self, product: Product) -> None: ...

    def list(self) -> list[Product]: ...

    def get(self, product_id: UUID) -> Product | None: ...
