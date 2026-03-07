from decimal import Decimal
from uuid import UUID

from inventory_service.inventory.application.commands import CreateProductCommand
from inventory_service.inventory.application.use_cases import InventoryUseCases
from inventory_service.inventory.domain.entities import Product
from inventory_service.inventory.ports.repository import ProductRepository
from inventory_service.inventory.ports.uow import InventoryUnitOfWork


class FakeProductRepository(ProductRepository):
    def __init__(self) -> None:
        self._items: dict[UUID, Product] = {}

    def add(self, product: Product) -> None:
        self._items[product.id] = product

    def list(self) -> list[Product]:
        return list(self._items.values())

    def get(self, product_id: UUID) -> Product | None:
        return self._items.get(product_id)


class FakeUnitOfWork(InventoryUnitOfWork):
    def __init__(self) -> None:
        self.products = FakeProductRepository()
        self.commits = 0
        self.rollbacks = 0

    def __enter__(self) -> "FakeUnitOfWork":
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        pass

    def commit(self) -> None:
        self.commits += 1

    def rollback(self) -> None:
        self.rollbacks += 1


def test_create_and_list_products() -> None:
    uow = FakeUnitOfWork()

    def uow_factory() -> InventoryUnitOfWork:
        return uow

    use_cases = InventoryUseCases(uow_factory=uow_factory)

    created = use_cases.create_product(
        CreateProductCommand(
            name="Mechanical Keyboard", sku="KB-001", price=Decimal("129.90"), stock=10
        )
    )

    assert created.sku == "KB-001"
    assert uow.commits == 1

    listed = use_cases.list_products()
    assert len(listed) == 1
    assert listed[0].name == "Mechanical Keyboard"

    fetched = use_cases.get_product(created.id)
    assert fetched is not None
    assert fetched.id == created.id

    missing = use_cases.get_product(UUID("f35295c0-b4d4-4ef4-acf6-4f9dd25066dd"))
    assert missing is None
