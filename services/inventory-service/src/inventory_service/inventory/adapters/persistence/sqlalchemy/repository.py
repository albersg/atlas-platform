from uuid import UUID

from inventory_service.inventory.adapters.persistence.sqlalchemy.models import ProductModel
from inventory_service.inventory.domain.entities import Product
from sqlalchemy import select
from sqlalchemy.orm import Session


class SqlAlchemyProductRepository:
    def __init__(self, session: Session) -> None:
        self._session = session

    def add(self, product: Product) -> None:
        row = ProductModel(
            id=product.id,
            name=product.name,
            sku=product.sku,
            price=product.price,
            stock=product.stock,
        )
        self._session.add(row)

    def list(self) -> list[Product]:
        rows = self._session.scalars(select(ProductModel)).all()
        return [self._to_domain(row) for row in rows]

    def get(self, product_id: UUID) -> Product | None:
        row = self._session.get(ProductModel, product_id)
        return self._to_domain(row) if row else None

    @staticmethod
    def _to_domain(row: ProductModel) -> Product:
        return Product(
            id=row.id,
            name=row.name,
            sku=row.sku,
            price=row.price,
            stock=row.stock,
        )
