import { http } from "../../../shared/api/http";
import type { CreateProductInput, Product } from "../types/inventory";

const BASE = "/api/v1/inventory";

export function listProducts(): Promise<Product[]> {
  return http<Product[]>(`${BASE}/products`);
}

export function createProduct(payload: CreateProductInput): Promise<Product> {
  return http<Product>(`${BASE}/products`, {
    method: "POST",
    body: JSON.stringify(payload)
  });
}
