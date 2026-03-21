# Monorepo Component Map

This page is the quick reference for what exists in the monorepo and which layer
owns which responsibility.

## Application surfaces

### `apps/web`

- React + Vite + TypeScript frontend,
- runs with `mise run frontend-dev`,
- participates in Compose, image release, and staged deployments.

### `services/inventory-service`

- active backend service,
- uses FastAPI, SQLAlchemy, and Alembic,
- exposes health checks, API routes, and metrics,
- owns backend tests and type checks.

Reference: `services/inventory-service/README.md`

### `services/billing-service`

- scaffold for a future bounded context,
- keeps the same hexagonal and screaming architecture style.

Reference: `services/billing-service/README.md`

## Platform surfaces

### `platform/helm`

- reusable Helm packaging layer,
- wrapper charts for Istio and Prometheus,
- shared Atlas workload base inputs.

### `platform/k8s`

- `base/`: environment-neutral app manifests,
- `components/`: reusable workload-side building blocks,
- `overlays/dev`: local Kubernetes lab,
- `overlays/staging-local`: local rehearsal of the staging topology,
- `overlays/staging`: canonical pre-production overlay.

### `platform/argocd`

- `core/`: Argo CD plus KSOPS bootstrap,
- `apps/`: workload and infra application definitions.

Reference: `platform/argocd/README.md`

### `platform/policy`

- Kyverno policy bundles,
- rules that validate workload and infra renders before rollout.

## Automation surfaces

### `scripts/k3s`

- `cluster/`: readiness, status, and access helpers,
- `images/`: image build and import helpers,
- `deploy/`: local Kubernetes deployment flows,
- `verify/`: smoke checks.

Reference: `scripts/k3s/README.md`

### `scripts/gitops`

- Argo CD bootstrap helpers,
- local render helpers for overlays and infra charts,
- deployment and wait helpers,
- overlay and policy validation.

### `scripts/release`

- digest promotion helpers,
- trusted-image verification helpers.

## Root documents worth knowing

- `README.md`: the repo landing page.
- `AGENTS.md`: operating contract for agent sessions.
- `CONTRIBUTING.md`: contributor workflow and PR expectations.
- `SECURITY.md`: security reporting and secure-development rules.
- `mise.toml`: source of truth for tools and canonical tasks.
