# Local Development

This guide explains the normal local loops for coding, testing, and validating a change.

## Choose the right loop

| If you need... | Use this |
| --- | --- |
| Backend only | `mise run backend-dev` |
| Frontend only | `mise run frontend-dev` |
| Full app with PostgreSQL | `mise run compose-up` |
| Full local validation | `mise run check` and `mise run docs-build` |

## Backend-only loop

```bash
mise run backend-dev
```

- Purpose: run `inventory-service` with auto-reload.
- Prerequisites: backend dependencies installed; PostgreSQL reachable through `INVENTORY_DATABASE_URL` if your change needs the database.
- Under the hood: runs `uvicorn inventory_service.main:app --reload` inside `services/inventory-service`.
- Expected output: a local API server on port `8000`.
- Run next: `mise run backend-test`, `mise run backend-migrate`, or `mise run test`.

## Frontend-only loop

```bash
mise run frontend-dev
```

- Purpose: run the Vite dev server for the web app.
- Prerequisites: frontend dependencies installed.
- Under the hood: runs `npm run dev` inside `apps/web`.
- Expected output: a local Vite server and hot reload.
- Run next: `mise run frontend-build` or `mise run typecheck`.

## Full local validation loop

```bash
mise run fmt
mise run lint
mise run typecheck
mise run test
mise run docs-build
```

Use this before you consider a change locally complete.

## When to switch to Compose

Use Compose when you want:

- PostgreSQL without manual setup,
- backend and frontend together,
- a closer approximation of the app running as a small stack.

Read [Local Compose](../operations/local-compose.md) for details.

## When to switch to k3s

Use k3s when the change depends on:

- Kubernetes manifests,
- Ingress or service behavior,
- migration jobs in-cluster,
- staging or GitOps learning.

Read [k3s dev environment](../operations/k3s-dev.md).

## Common next commands

- `mise run check`: grouped local validation.
- `mise run ci`: CI-equivalent validation path.
- `mise run compose-up`: full local stack.
- `mise run docs-build`: verify docs after documentation changes.

## If something fails

Start with [Troubleshooting](../reference/troubleshooting.md).
