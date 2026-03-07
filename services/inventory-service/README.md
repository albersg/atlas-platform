# Inventory Service

Hexagonal + screaming architecture service for inventory management.

## Local run

```bash
cd services/inventory-service
python -m venv .venv
source .venv/bin/activate
pip install -e .[dev]
uvicorn inventory_service.main:app --reload
```

## Endpoints

- `GET /healthz`
- `GET /api/v1/inventory/products`
- `POST /api/v1/inventory/products`
- `GET /api/v1/inventory/products/{product_id}`

## Type checking and tests

```bash
cd services/inventory-service
uv run --extra dev pyright
uv run --extra dev pytest tests
```

## Optional Sentry setup

Set these environment variables to enable error reporting:

- `INVENTORY_SENTRY_DSN`
- `INVENTORY_SENTRY_TRACES_SAMPLE_RATE` (default `0.0`)
