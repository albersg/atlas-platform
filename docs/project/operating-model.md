# Operating Model

This page summarizes the current project scope, the default daily workflow, and
the scaling rules behind the repo.

## Current state

Atlas Platform currently provides:

- a working backend and frontend,
- Alembic-backed database migrations,
- one quality and security story across local work and CI,
- `dev` on k3s with reproducible local images,
- `staging-local` as a GitOps rehearsal environment,
- canonical `staging` with digest-based promotion.

## Current operational scope

This repository intentionally covers:

- `local` for day-to-day development,
- `dev` as the local Kubernetes lab,
- `staging-local` as the local GitOps rehearsal path,
- canonical `staging` as the real pre-production contract.

`prod` is intentionally deferred until separate production infrastructure exists.

## Recommended daily workflow

```bash
git status
mise run fmt
mise run lint
mise run test
mise run docs-build
mise run check
```

Before a pull request:

```bash
mise run ci
```

## Code scaling rules

- keep bounded contexts clear by service,
- avoid coupling business logic directly to infrastructure details,
- extract new services only when real autonomy pressure exists.

Signals that a new service might be justified:

- clearly separate team ownership,
- very different release cadences,
- low cross-service change overlap,
- a real need to scale one piece independently.

## Platform scaling rules

- move from simple local loops to environment-specific delivery only when needed,
- replace inline-sensitive values with stronger secret management over time,
- keep tightening quotas, requests, limits, and network policy as the platform matures,
- increase policy-as-code strictness as the deployment contract stabilizes,
- separate observability concerns further as more services appear.

## Repository scaling rules

- current strategy: modular monorepo,
- future strategy: consider multirepo only when an ADR-backed reason exists.

## Quick troubleshooting reminders

- `mise` is missing: verify shell activation and rerun `mise install`.
- `fmt-check` fails: run `mise run fmt`, inspect the diff, and rerun validation.
- Alembic connection errors: confirm `INVENTORY_DATABASE_URL` and PostgreSQL reachability.
- k3s reuses old images in `dev`: rerun `mise run k8s-build-images` and `mise run k8s-import-images`.
