from decimal import Decimal
from pathlib import Path

import pytest
from inventory_service.inventory.adapters.persistence.sqlalchemy.models import ProductModel
from inventory_service.inventory.adapters.persistence.sqlalchemy.repository import (
    SqlAlchemyProductRepository,
)
from inventory_service.inventory.adapters.persistence.sqlalchemy.uow import (
    SqlAlchemyInventoryUnitOfWork,
)
from inventory_service.inventory.domain.entities import Product
from inventory_service.shared.db import Base, create_session_factory


def _build_sqlite_url(tmp_path: Path) -> str:
    return f"sqlite+pysqlite:///{tmp_path / 'inventory-test.db'}"


def test_create_session_factory_and_repository_roundtrip(tmp_path: Path) -> None:
    session_factory = create_session_factory(_build_sqlite_url(tmp_path))
    with session_factory() as session:
        Base.metadata.create_all(bind=session.get_bind())

    product = Product.create(
        name="Docking Station",
        sku="DK-001",
        price=Decimal("199.99"),
        stock=3,
    )

    with session_factory() as session:
        repo = SqlAlchemyProductRepository(session)
        repo.add(product)
        session.commit()

    with session_factory() as session:
        repo = SqlAlchemyProductRepository(session)
        listed = repo.list()
        fetched = repo.get(product.id)

    assert len(listed) == 1
    assert listed[0].sku == "DK-001"
    assert fetched is not None
    assert fetched.id == product.id
    assert repo.get(Product.create("Other", "XX-1", Decimal("1.00"), 1).id) is None


def test_product_model_table_metadata() -> None:
    assert ProductModel.__tablename__ == "products"
    assert ProductModel.__table__.c.sku.unique is True
    assert str(ProductModel.__table__.c.price.type) == "NUMERIC(10, 2)"


def test_uow_commit_and_rollback_behaviors(tmp_path: Path) -> None:
    session_factory = create_session_factory(_build_sqlite_url(tmp_path))
    with session_factory() as session:
        Base.metadata.create_all(bind=session.get_bind())

    uow = SqlAlchemyInventoryUnitOfWork(session_factory)

    with uow as active_uow:
        product = Product.create("USB-C Hub", "HB-001", Decimal("59.90"), 7)
        active_uow.products.add(product)
        active_uow.commit()

    with session_factory() as session:
        rows = session.query(ProductModel).all()
    assert len(rows) == 1

    with SqlAlchemyInventoryUnitOfWork(session_factory) as rollback_uow:
        rollback_uow.products.add(Product.create("Webcam", "WC-001", Decimal("79.90"), 2))
        rollback_uow.rollback()

    with session_factory() as session:
        rows_after_manual_rollback = session.query(ProductModel).all()
    assert len(rows_after_manual_rollback) == 1


def test_uow_rolls_back_on_exception_and_commit_requires_enter(tmp_path: Path) -> None:
    session_factory = create_session_factory(_build_sqlite_url(tmp_path))
    with session_factory() as session:
        Base.metadata.create_all(bind=session.get_bind())

    uow = SqlAlchemyInventoryUnitOfWork(session_factory)
    try:
        with uow as active_uow:
            active_uow.products.add(Product.create("Microphone", "MC-001", Decimal("149.00"), 1))
            raise RuntimeError("boom")
    except RuntimeError:
        pass

    with session_factory() as session:
        rows = session.query(ProductModel).all()
    assert rows == []

    detached_uow = SqlAlchemyInventoryUnitOfWork(session_factory)
    with pytest.raises(RuntimeError, match="Session not initialized"):
        detached_uow.commit()

    detached_uow.rollback()
    detached_uow.__exit__(None, None, None)
