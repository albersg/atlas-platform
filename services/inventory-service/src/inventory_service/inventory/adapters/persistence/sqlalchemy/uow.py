from collections.abc import Callable

from inventory_service.inventory.adapters.persistence.sqlalchemy.repository import (
    SqlAlchemyProductRepository,
)
from inventory_service.inventory.ports.repository import ProductRepository
from sqlalchemy.orm import Session


class SqlAlchemyInventoryUnitOfWork:
    def __init__(self, session_factory: Callable[[], Session]) -> None:
        self._session_factory = session_factory
        self._session: Session | None = None
        self.products: ProductRepository

    def __enter__(self) -> "SqlAlchemyInventoryUnitOfWork":
        self._session = self._session_factory()
        self.products = SqlAlchemyProductRepository(self._session)
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        if not self._session:
            return
        if exc_type:
            self._session.rollback()
        self._session.close()

    def commit(self) -> None:
        if not self._session:
            raise RuntimeError("Session not initialized")
        self._session.commit()

    def rollback(self) -> None:
        if self._session:
            self._session.rollback()
