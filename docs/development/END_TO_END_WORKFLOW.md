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

`mise run k8s-build-images` writes the current dev image tags to
`.gitops-local/k3s/dev-images.env`; `k8s-import-images` and `k8s-deploy-dev` reuse
that state so the cluster rolls forward to the exact images that were just built.

Delete dev deployment:

```bash
mise run k8s-delete-dev
```

## 6) GitOps + registry flow (staging)

Prerequisites:

- the target images exist in GHCR,
- Argo CD is installed in the cluster,
- the repo credential is installed in `argocd`,
- the SOPS age key is installed in `argocd`.

Typical flow:

```bash
ARGOCD_APP_REVISION=<remote-branch-or-commit> mise run gitops-deploy-staging
mise run k8s-status-staging
mise run k8s-access-staging
```

## 7) Observability and runtime configuration

Backend Sentry (optional):

- `INVENTORY_SENTRY_DSN`
- `INVENTORY_SENTRY_TRACES_SAMPLE_RATE`

Frontend Sentry (optional):

- `VITE_SENTRY_DSN`
- `VITE_SENTRY_ENVIRONMENT`
- `VITE_SENTRY_TRACES_SAMPLE_RATE`

## 8) PR readiness checklist

- Architecture boundaries preserved (domain/application/ports/adapters).
- No secrets or private material committed.
- Validation commands pass locally.
- Rollback path documented if the change is risky.
- Docs updated (`README`, runbooks, ADRs if needed).

## 9) Release baseline

For the current non-production release flow:

1. build immutable images and publish them to the registry,
2. capture the published digests,
3. promote `staging` by digest through a pull request,
4. verify health checks and key paths,
5. monitor logs/errors/metrics and rollback quickly if needed.

Production rollout is intentionally deferred until there is separate production infrastructure.
