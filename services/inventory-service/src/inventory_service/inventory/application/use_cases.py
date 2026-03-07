from collections.abc import Callable
from uuid import UUID

from inventory_service.inventory.application.commands import CreateProductCommand
from inventory_service.inventory.domain.entities import Product
from inventory_service.inventory.ports.uow import InventoryUnitOfWork


class InventoryUseCases:
    def __init__(self, uow_factory: Callable[[], InventoryUnitOfWork]) -> None:
        self._uow_factory = uow_factory

    def create_product(self, command: CreateProductCommand) -> Product:
        product = Product.create(
            name=command.name,
            sku=command.sku,
            price=command.price,
            stock=command.stock,
        )
        with self._uow_factory() as uow:
            uow.products.add(product)
            uow.commit()
        return product

    def list_products(self) -> list[Product]:
        with self._uow_factory() as uow:
            return uow.products.list()

    def get_product(self, product_id: UUID) -> Product | None:
        with self._uow_factory() as uow:
            return uow.products.get(product_id)
