# Troubleshooting

Start with the smallest failing layer. Do not jump straight to k3s or GitOps if
the problem already appears in local validation.

## First triage questions

1. Is the problem local app code, local tooling, rendered manifests, or live cluster state?
2. Which environment are you really working in: local, `dev`, `staging-local`, or `staging`?
3. Which tool owns the failing layer: Compose, Kustomize, Helm, Argo CD, Istio, Prometheus, or release trust tooling?
4. Did the failure happen before render, during validation, during sync, or only at runtime?

Those questions matter because Atlas Platform is intentionally layered. The right
owner changes as you move up the ladder.

## Quick tool-to-layer map

| Symptom | Usually owned by |
| --- | --- |
| dependency install or hook problems | `mise`, `pre-commit`, `uv`, `npm` |
| app starts but behavior is wrong | backend or frontend app code |
| Compose health or wiring problem | Docker Compose and runtime env vars |
| manifest render failure | Kustomize, Helm, KSOPS, or SOPS |
| policy or schema failure | Kyverno, kubeconform, trusted-image checks |
| app never converges in staging | Argo CD or bad rendered input |
| traffic works in `dev` but not staged envs | Istio |
| Prometheus healthy but no workload metrics | `ServiceMonitor`, workload labels, or `/metrics` exposure |
| canonical staging rejects images | release or Cosign trust verification |

## Setup and tooling

### `mise` is not available

- Confirm `mise` is installed and activated in your shell.
- Restart the shell.
- Rerun `mise install`.
- If command definitions look wrong, run `mise run doctor`.

### Git hooks seem broken

- Rerun `mise run bootstrap`.
- Then rerun `mise run lint`.
- If a specific hook is failing repeatedly, inspect `.pre-commit-config.yaml` before assuming the repo is broken.

### GitOps helper binaries are missing

- Run `mise run gitops-install-tools`.
- Confirm `.gitops-local/bin` now contains `kustomize`, `ksops`, `kyverno`, `helm`, `cosign`, and `istioctl`.
- If only staged validation is failing, this is often the real root cause.

## Validation failures

### `fmt-check` fails

- Run `mise run fmt`.
- Inspect the resulting diff.
- Rerun `mise run fmt-check` or `mise run ci`.

### `docs-build` fails

- Check for broken links.
- Check that new files were added to `mkdocs.yml`.
- Check for renamed files that old pages still reference.

### `lint` keeps failing after auto-fixes

- Inspect the failing hook rather than rerunning blindly.
- Use `MISE_LINT_MAX_TRIES` only when hooks are making legitimate sequential edits.
- If Markdown or YAML hooks fail, treat that as documentation or manifest quality drift, not as a backend problem.

### `k8s-validate-overlays` fails

- Decide which stage failed:
  - render,
  - policy,
  - trusted-image verification,
  - schema validation,
  - `istioctl analyze`.
- Rerun the matching render command first:
  - `mise run gitops-render-staging`,
  - `mise run gitops-render-platform-infra-staging`,
  - `mise run gitops-render-platform-infra-staging-local`.
- Treat signature or secret errors as trust or SOPS problems, not as random YAML issues.
- Use `ATLAS_VALIDATE_PREFLIGHT=1` when you only want to prove render and policy-bundle assembly first.

## Backend and database

### Backend cannot connect to PostgreSQL

- Confirm `INVENTORY_DATABASE_URL`.
- Confirm PostgreSQL is actually running.
- If using Compose, check `mise run compose-logs`.
- If using k3s, confirm the target PostgreSQL statefulset is ready before blaming the backend.

### Alembic migration fails

- Confirm the database is reachable.
- Confirm the migration files are present.
- Rerun `mise run backend-migrate` after fixing the root cause.
- In staged environments, remember the migration job uses the same `INVENTORY_DATABASE_URL` contract as the app workload.

## Compose

### The stack starts but one service stays unhealthy

- Run `mise run compose-logs`.
- Confirm PostgreSQL became healthy first.
- Then inspect backend readiness and frontend logs.
- Check `docker-compose.yml` before changing app code; the issue may be wiring, not implementation.

## k3s and GitOps

### k3s seems to reuse old images in `dev`

- Rerun `mise run k8s-build-images`.
- Rerun `mise run k8s-import-images`.
- Redeploy with `mise run k8s-deploy-dev`.

### `staging-local` or `staging` does not reconcile

- Run `mise run k8s-doctor`.
- Confirm Argo CD, the repo credential, and the age key are installed.
- If infra apps are missing, inspect `mise run gitops-apply-apps` behavior rather than only waiting on the workload app.
- Rerun `mise run gitops-wait-staging` only after the dependency gap is fixed.

### The wrong staged environment seems to be running

- Check whether `STAGING_LOCAL_IMAGES` is set.
- Remember local k3s usually defaults to the `staging-local` wrapper.
- Set `STAGING_LOCAL_IMAGES=0` only when you intentionally want canonical staging behavior.
- If Argo CD app source path looks wrong, verify `ARGOCD_APP_PATH` and `ARGOCD_APP_REVISION` assumptions.

### Staged deploy waits forever or times out

- Check `ARGOCD_WAIT_TIMEOUT_SECONDS` if the cluster is simply slow.
- Use `kubectl -n argocd get application <name> -o yaml` for the failing app.
- Confirm infra apps reached healthy state before blaming the workload app.

## Mesh and traffic

### Mesh traffic behaves differently from `dev`

- Remember `dev` uses Traefik while staged environments use Istio.
- Inspect the Istio gateway and sidecar-enabled workloads before blaming the app.
- Rerun `mise run k8s-smoke-staging` after fixing routing or sidecar issues.
- If URLs look wrong, verify `ATLAS_STAGING_INGRESS_SCHEME`, `ATLAS_STAGING_LOCAL_INGRESS_SCHEME`, and the local NodePort settings.

### `k8s-access-staging` shows unexpected URLs or ports

- Check whether the Istio ingress service currently exposes NodePorts.
- Remember `staging-local` may route through NodePort while canonical `staging` uses the staged gateway model.
- Confirm the helper did not fall back from detected NodePort values to default variables.

## Monitoring and observability

### Monitoring looks healthy but the app is missing metrics

- Confirm Prometheus is healthy in the `monitoring` namespace.
- Confirm the workload exposes `/metrics`.
- Confirm the workload `ServiceMonitor` exists and has the expected labels.
- Then inspect the service and port name the `ServiceMonitor` targets.

### The `atlas-platform-prometheus` app is healthy but monitoring still feels broken

- Separate infra health from workload scrape health.
- A healthy Prometheus operator does not prove `inventory-service` was selected as a scrape target.
- Render the staged surfaces locally and confirm the `ServiceMonitor` still appears in output.

## Release and promotion

### Canonical staging rejects trusted-image verification

- Inspect `scripts/release/verify-trusted-images.sh` assumptions.
- Confirm the digests actually exist in GHCR.
- Confirm the images were signed by `.github/workflows/release-images.yml` from `main`.
- If needed, use `ATLAS_TRUST_VERIFY_DRY_RUN=1` to inspect the exact Cosign verification command first.

### Promotion workflow fails during overlay validation

- Confirm `SOPS_AGE_KEY` was materialized correctly.
- Confirm the canonical overlay and staged infra renders still pass locally.
- Remember promotion is not only a digest rewrite; it also re-runs staging-grade validation.

## Backup, restore, and destructive operations

### Restore or staging delete refuses to run

- Read the required confirmation variable carefully.
- Export the exact required token.
- Retry only after verifying you really intend the destructive action.

### Backup or restore helper jobs fail

- Inspect `ATLAS_POSTGRES_TRANSPORT`, timeout variables, and whether the target PostgreSQL pod is ready.
- Set `ATLAS_POSTGRES_KEEP_JOBS=1` if you need the job to remain for inspection.
- Use `ATLAS_POSTGRES_DRY_RUN=1` to understand what the helper would do before changing live state.

## When to switch to a deeper runbook

- Use the [k3s runbook](../deployment/k3s/RUNBOOK.md) for cluster-level operation.
- Use the [GitOps runbook](../deployment/gitops/ARGOCD_SOPS_RUNBOOK.md) for Argo CD and SOPS issues.
- Use the [Image promotion runbook](../deployment/releases/IMAGE_PROMOTION.md) for digest-promotion issues.

## Read next

- If the failing step is a specific `mise run ...` task, read [Command reference](commands.md) next.
- If the failing step depends on env vars or script inputs, read [Configuration and environment variables](configuration.md) next.
- If the failing step is GitOps bootstrap or staged deploy, read [GitOps bootstrap](../operations/gitops-bootstrap.md), [Staging-local](../operations/staging-local.md), or [Canonical staging](../operations/canonical-staging.md) next.
- If the failing step is release trust or digest promotion, read [Release workflow](../operations/release-workflow.md) and [Staging promotion](../operations/staging-promotion.md) next.
