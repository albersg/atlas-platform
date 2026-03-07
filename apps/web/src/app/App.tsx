import { InventoryPage } from "../features/inventory/components/InventoryPage";

export function App() {
  return (
    <main style={{ maxWidth: 980, margin: "2rem auto", fontFamily: "ui-sans-serif, system-ui" }}>
      <header style={{ marginBottom: "1.5rem" }}>
        <h1>Atlas Platform</h1>
        <p>Inventory UI powered by the inventory microservice.</p>
      </header>
      <InventoryPage />
    </main>
  );
}
