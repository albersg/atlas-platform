# Troubleshooting

Start with the smallest failing layer. Do not jump straight to k3s or GitOps if
the problem already appears in local validation.

When in doubt, ask these questions in order:

1. Is the problem local app code, local tooling, or cluster state?
2. Which environment am I actually working in: local, `dev`, `staging-local`, or `staging`?
3. Which tool owns the failing layer: Docker, Kustomize, Helm, Argo CD, Istio, or Prometheus?

## Setup and tooling

### `mise` is not available

- confirm `mise` is installed and activated in your shell,
- restart the shell,
- rerun `mise install`.

### Git hooks seem broken

- rerun `mise run bootstrap`,
- then rerun `mise run lint`.

## Validation failures

### `fmt-check` fails

- run `mise run fmt`,
- inspect the resulting diff,
- rerun `mise run fmt-check` or `mise run ci`.

### `docs-build` fails

- check for broken links,
- check that new files were added to `mkdocs.yml`,
- check for renamed files that old pages still reference.

### `k8s-validate-overlays` fails

- decide whether the failure is in the workload overlay, the Helm-rendered infra output, or Kyverno policy,
- rerun the matching render command first,
- treat signature or secret errors as trust or SOPS problems, not as random YAML issues.

### `lint` keeps failing after auto-fixes

- inspect the failing hook rather than rerunning blindly,
- use `MISE_LINT_MAX_TRIES` only when you know hooks are making legitimate sequential edits.

## Backend and database

### Backend cannot connect to PostgreSQL

- confirm `INVENTORY_DATABASE_URL`,
- confirm PostgreSQL is actually running,
- if using Compose, check `mise run compose-logs`.

### Alembic migration fails

- confirm the database is reachable,
- confirm the migration files are present,
- rerun `mise run backend-migrate` after fixing the root cause.

## Compose

### The stack starts but one service stays unhealthy

- run `mise run compose-logs`,
- inspect whether PostgreSQL became healthy first,
- then inspect backend readiness and frontend logs.

## k3s and GitOps

### k3s seems to reuse old images in `dev`

- rerun `mise run k8s-build-images`,
- rerun `mise run k8s-import-images`,
- redeploy with `mise run k8s-deploy-dev`.

### Staging or staging-local does not reconcile

- run `mise run k8s-doctor`,
- confirm Argo CD, the repo credential, and the age key are installed,
- rerun `mise run gitops-wait-staging` after fixing the missing dependency.

### The wrong staging environment seems to be running

- check whether `STAGING_LOCAL_IMAGES` is set,
- remember that local k3s usually defaults to the `staging-local` wrapper,
- set `STAGING_LOCAL_IMAGES=0` only when you intentionally want canonical staging behavior.

### Monitoring looks healthy but the app is missing metrics

- confirm Prometheus is healthy in the `monitoring` namespace,
- confirm the workload exposes `/metrics`,
- confirm the workload `ServiceMonitor` exists and has the expected labels,
- then inspect the service and port name the `ServiceMonitor` targets.

### Mesh traffic behaves differently from `dev`

- remember that `dev` uses Traefik while staged environments use Istio,
- inspect the Istio gateway and sidecar-enabled workloads before blaming the app,
- rerun `mise run k8s-smoke-staging` after fixing routing or sidecar issues.

### Restore or staging delete refuses to run

- read the required confirmation variable carefully,
- export the exact required token,
- retry only after verifying you really intend the destructive action.

## When to switch to a deeper runbook

- use the [k3s runbook](../deployment/k3s/RUNBOOK.md) for cluster-level operation,
- use the [GitOps runbook](../deployment/gitops/ARGOCD_SOPS_RUNBOOK.md) for Argo CD and SOPS issues,
- use the [Image promotion runbook](../deployment/releases/IMAGE_PROMOTION.md) for digest-promotion issues.
