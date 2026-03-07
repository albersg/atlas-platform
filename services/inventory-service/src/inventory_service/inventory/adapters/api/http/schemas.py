from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, Field


class CreateProductRequest(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    sku: str = Field(min_length=1, max_length=64)
    price: Decimal = Field(ge=0)
    stock: int = Field(ge=0)


class ProductResponse(BaseModel):
    id: UUID
    name: str
    sku: str
    price: Decimal
    stock: int
