import { FormEvent, useState } from "react";

import { useInventory } from "../hooks/useInventory";

export function InventoryPage() {
  const { items, isLoading, error, addProduct } = useInventory();
  const [name, setName] = useState("");
  const [sku, setSku] = useState("");
  const [price, setPrice] = useState("0.00");
  const [stock, setStock] = useState("0");
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setIsSubmitting(true);
    try {
      await addProduct({
        name,
        sku,
        price: Number(price),
        stock: Number(stock)
      });
      setName("");
      setSku("");
      setPrice("0.00");
      setStock("0");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <section style={{ display: "grid", gap: "1.5rem" }}>
      <form onSubmit={onSubmit} style={{ display: "grid", gap: "0.75rem", maxWidth: 520 }}>
        <h2>Create product</h2>
        <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Name" required />
        <input value={sku} onChange={(e) => setSku(e.target.value)} placeholder="SKU" required />
        <input value={price} onChange={(e) => setPrice(e.target.value)} placeholder="Price" type="number" step="0.01" min="0" required />
        <input value={stock} onChange={(e) => setStock(e.target.value)} placeholder="Stock" type="number" min="0" required />
        <button type="submit" disabled={isSubmitting}>{isSubmitting ? "Saving..." : "Save"}</button>
      </form>

      <section>
        <h2>Products</h2>
        {isLoading && <p>Loading...</p>}
        {error && <p style={{ color: "crimson" }}>{error}</p>}
        {!isLoading && !items.length && <p>No products yet.</p>}
        <ul>
          {items.map((item) => (
            <li key={item.id}>
              <strong>{item.name}</strong> ({item.sku}) - ${item.price} | stock: {item.stock}
            </li>
          ))}
        </ul>
      </section>
    </section>
  );
}
