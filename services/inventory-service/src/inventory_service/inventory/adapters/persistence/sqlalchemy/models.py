from decimal import Decimal
from uuid import UUID

from inventory_service.shared.db import Base
from sqlalchemy import Numeric, String
from sqlalchemy.orm import Mapped, mapped_column


class ProductModel(Base):
    __tablename__ = "products"

    id: Mapped[UUID] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    sku: Mapped[str] = mapped_column(String(64), nullable=False, unique=True)
    price: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    stock: Mapped[int] = mapped_column(nullable=False)
