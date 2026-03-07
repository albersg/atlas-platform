from collections.abc import Callable
from uuid import UUID

from fastapi import APIRouter, HTTPException, status
from inventory_service.inventory.adapters.api.http.schemas import (
    CreateProductRequest,
    ProductResponse,
)
from inventory_service.inventory.application.commands import CreateProductCommand
from inventory_service.inventory.application.use_cases import InventoryUseCases
from inventory_service.inventory.ports.uow import InventoryUnitOfWork


def build_inventory_router(uow_factory: Callable[[], InventoryUnitOfWork]) -> APIRouter:
    router = APIRouter(prefix="/api/v1/inventory", tags=["inventory"])
    use_cases = InventoryUseCases(uow_factory=uow_factory)

    @router.get("/products", response_model=list[ProductResponse])
    def list_products() -> list[ProductResponse]:
        products = use_cases.list_products()
        return [ProductResponse(**product.__dict__) for product in products]

    @router.post("/products", response_model=ProductResponse, status_code=status.HTTP_201_CREATED)
    def create_product(payload: CreateProductRequest) -> ProductResponse:
        created = use_cases.create_product(
            CreateProductCommand(
                name=payload.name,
                sku=payload.sku,
                price=payload.price,
                stock=payload.stock,
            )
        )
        return ProductResponse(**created.__dict__)

    @router.get("/products/{product_id}", response_model=ProductResponse)
    def get_product(product_id: UUID) -> ProductResponse:
        product = use_cases.get_product(product_id)
        if not product:
            raise HTTPException(status_code=404, detail="Product not found")
        return ProductResponse(**product.__dict__)

    return router
