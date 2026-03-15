# Backend Development

The active backend service is `services/inventory-service`. It uses FastAPI,
SQLAlchemy, Alembic, and a hexagonal plus screaming architecture structure.

## Tooling explained

- FastAPI defines the HTTP API surface and interactive docs.
- `uv` installs and runs the backend's Python tooling without a manually managed virtualenv workflow.
- PostgreSQL is the main relational database behind persistence features.
- `pytest` runs backend tests.
- `pyright` catches Python type issues before runtime.

## What you usually change here

- API routes and request handling
- domain logic
- persistence adapters and models
- migrations
- backend tests

## Primary commands

```bash
mise run backend-dev
mise run backend-test
mise run backend-migrate
mise run backend-typecheck
mise run backend-test-cov
```

## Run the backend locally

```bash
mise run backend-dev
```

- Purpose: starts the FastAPI app with reload.
- Prerequisites: `mise run app-bootstrap`; database access if your work touches persistence.
- Under the hood: runs `uv run uvicorn inventory_service.main:app --reload --host 0.0.0.0 --port 8000`.
- Expected output: the API is reachable on `http://localhost:8000`.
- Useful endpoints: `/healthz`, `/readyz`, `/api/v1/inventory/products`.

## Run backend tests

```bash
mise run backend-test
```

- Purpose: quick backend-specific test run.
- Under the hood: runs `pytest -q` inside `services/inventory-service`.
- Run next: `mise run backend-test-cov` if you want the broader suite or coverage-oriented output.

## Run backend type checking

```bash
mise run backend-typecheck
```

- Purpose: catch type errors before they become runtime issues.
- Under the hood: runs `pyright` in the backend project.

## Architecture expectations

- Keep domain and application logic separate from infrastructure.
- Keep adapters and API layers dependent on inward-facing abstractions.
- Add migrations when persistent models change.
- Update docs when the API contract or workflow changes.

## Read next

- [Database and migrations](database-migrations.md)
- [Quality and CI](quality-and-ci.md)
- `services/inventory-service/README.md`
