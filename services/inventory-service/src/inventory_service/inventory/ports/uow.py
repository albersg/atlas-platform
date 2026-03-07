from typing import Protocol

from inventory_service.inventory.ports.repository import ProductRepository


class InventoryUnitOfWork(Protocol):
    products: ProductRepository

    def __enter__(self) -> "InventoryUnitOfWork": ...

    def __exit__(self, exc_type, exc_val, exc_tb) -> None: ...

    def commit(self) -> None: ...

    def rollback(self) -> None: ...
