from decimal import Decimal
from uuid import UUID

from fastapi import FastAPI
from fastapi.testclient import TestClient
from inventory_service.inventory.adapters.api.http.router import build_inventory_router
from inventory_service.inventory.domain.entities import Product
from inventory_service.inventory.ports.repository import ProductRepository
from inventory_service.inventory.ports.uow import InventoryUnitOfWork


class InMemoryRepository(ProductRepository):
    def __init__(self) -> None:
        self._items: dict[str, Product] = {}

    def add(self, product: Product) -> None:
        self._items[str(product.id)] = product

    def list(self) -> list[Product]:
        return list(self._items.values())

    def get(self, product_id: UUID):
        return self._items.get(str(product_id))


class InMemoryUoW(InventoryUnitOfWork):
    def __init__(self, repository: InMemoryRepository) -> None:
        self.products: ProductRepository = repository

    def __enter__(self) -> "InMemoryUoW":
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        return None

    def commit(self) -> None:
        return None

    def rollback(self) -> None:
        return None


def _build_client() -> TestClient:
    repository = InMemoryRepository()

    def uow_factory() -> InMemoryUoW:
        return InMemoryUoW(repository)

    app = FastAPI()
    app.include_router(build_inventory_router(uow_factory=uow_factory))
    return TestClient(app)


def test_router_create_list_and_get_product() -> None:
    client = _build_client()

    create_response = client.post(
        "/api/v1/inventory/products",
        json={"name": "Monitor", "sku": "MN-001", "price": "299.99", "stock": 4},
    )
    assert create_response.status_code == 201
    payload = create_response.json()
    assert payload["sku"] == "MN-001"
    assert Decimal(payload["price"]) == Decimal("299.99")

    list_response = client.get("/api/v1/inventory/products")
    assert list_response.status_code == 200
    assert len(list_response.json()) == 1

    get_response = client.get(f"/api/v1/inventory/products/{payload['id']}")
    assert get_response.status_code == 200
    assert get_response.json()["name"] == "Monitor"


def test_router_returns_not_found_and_validates_payload() -> None:
    client = _build_client()

    missing_response = client.get("/api/v1/inventory/products/9eeb1039-7f4e-47be-a1df-11f7f0a7a8c1")
    assert missing_response.status_code == 404
    assert missing_response.json()["detail"] == "Product not found"

    invalid_response = client.post(
        "/api/v1/inventory/products",
        json={"name": "", "sku": "", "price": -1, "stock": -1},
    )
    assert invalid_response.status_code == 422
