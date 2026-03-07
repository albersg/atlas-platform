import { useEffect, useState } from "react";

import { createProduct, listProducts } from "../api/inventoryApi";
import type { CreateProductInput, Product } from "../types/inventory";

export function useInventory() {
  const [items, setItems] = useState<Product[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function refresh() {
    setIsLoading(true);
    setError(null);
    try {
      const data = await listProducts();
      setItems(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unknown error");
    } finally {
      setIsLoading(false);
    }
  }

  async function addProduct(input: CreateProductInput) {
    await createProduct(input);
    await refresh();
  }

  useEffect(() => {
    void refresh();
  }, []);

  return { items, isLoading, error, refresh, addProduct };
}
