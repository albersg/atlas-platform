# End-to-End Developer Workflow

This guide defines the standard day-to-day workflow for feature delivery in this repository.

## 1) Bootstrap (first time)

```bash
mise install
mise run bootstrap
mise run app-bootstrap
```

What this gives you:

- pinned local tooling,
- git hooks,
- backend and frontend dependencies.

## 2) Local development

Backend only:

```bash
mise run backend-dev
```

Frontend only:

```bash
mise run frontend-dev
```

Full stack with containers:

```bash
mise run compose-up
```

## 3) Feature implementation

Recommended sequence:

1. add/modify domain and application code,
2. implement adapters and API changes,
3. add migrations when persistence changes,
4. add or update tests for behavior and edge cases,
5. update docs if behavior/contracts changed.

## 4) Quality gates before PR

```bash
mise run fmt
mise run lint
mise run typecheck
mise run test
mise run docs-build
mise run check
mise run ci
```

Notes:

- `mise run test` enforces backend coverage threshold.
- `mise run ci` mirrors CI validation path.

## 5) k3s deployment flow (dev)

```bash
mise run k8s-preflight
mise run k8s-build-images
mise run k8s-import-images
mise run k8s-deploy-dev
mise run k8s-status
mise run k8s-access
```

Delete dev deployment:

```bash
mise run k8s-delete-dev
```

## 6) Observability and runtime configuration

Backend Sentry (optional):

- `INVENTORY_SENTRY_DSN`
- `INVENTORY_SENTRY_TRACES_SAMPLE_RATE`

Frontend Sentry (optional):

- `VITE_SENTRY_DSN`
- `VITE_SENTRY_ENVIRONMENT`
- `VITE_SENTRY_TRACES_SAMPLE_RATE`

## 7) PR readiness checklist

- Architecture boundaries preserved (domain/application/ports/adapters).
- No secrets or private material committed.
- Validation commands pass locally.
- Rollback path documented if the change is risky.
- Docs updated (`README`, runbooks, ADRs if needed).

## 8) Release baseline

For production-like promotion:

1. build immutable images with version tags,
2. update overlays to versioned images,
3. apply manifests,
4. verify health checks and key paths,
5. monitor logs/errors/metrics and rollback quickly if needed.
