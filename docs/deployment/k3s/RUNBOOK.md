# k3s Deployment Runbook

Use this runbook when you need the full operator workflow for the repository's
local Kubernetes paths. This is the deep reference for `dev`, `staging-local`,
backup and restore, direct cluster inspection, and environment teardown.

If you are still learning the platform, read these pages first:

- [Operations overview](../../operations/overview.md)
- [k3s dev environment](../../operations/k3s-dev.md)
- [Staging-local](../../operations/staging-local.md)
- [Canonical staging](../../operations/canonical-staging.md)

## Choose the right environment first

| Environment | Use it when | Delivery model | Images |
| --- | --- | --- | --- |
| `dev` | You want fast local Kubernetes validation for active app work. | Helper scripts render and apply the overlay directly. | Local images built for each run. |
| `staging-local` | You want to rehearse the staging GitOps topology on your own k3s cluster. | Argo CD syncs a local wrapper overlay. | Local `:main` refs imported into k3s. |
| Canonical `staging` | You want the real pre-production behavior. | Argo CD syncs the canonical staging overlay. | Registry images pinned by digest. |

Do not treat `staging-local` as proof that canonical `staging` is correct. It is
the learning and rehearsal path, not the immutable release path.

## Repository topology behind these commands

- `platform/k8s/base` contains the shared application manifests.
- `platform/k8s/components/in-cluster-postgres` defines PostgreSQL as a
  `StatefulSet` with persistent storage.
- `platform/k8s/components/images/dev` injects locally built image refs for `dev`.
- `platform/k8s/components/images/staging` defines the canonical digest-pinned
  image refs for real `staging`.
- `platform/k8s/components/images/staging-local` keeps the local rehearsal path on
  mutable `:main` refs without weakening canonical `staging`.
- `platform/k8s/overlays/dev` targets namespace `atlas-platform-dev`.
- `platform/k8s/overlays/staging` targets namespace `atlas-platform-staging`.
- `platform/k8s/overlays/staging-local` wraps the staging topology for local Argo
  CD rehearsal.

## Prerequisites

Before you use this runbook, make sure you have:

- `mise`, `kubectl`, `docker`, and `k3s` installed.
- A reachable k3s cluster with the correct current `kubectl` context.
- An active ingress controller such as Traefik.
- `metrics-server` if you want the full HPA-related local behavior.
- For `staging-local` or canonical `staging`, the GitOps bootstrap completed from
  [the GitOps runbook](../gitops/ARGOCD_SOPS_RUNBOOK.md).
- For canonical `staging`, published GHCR images and the digest promotion path
  already prepared.

Run this first when you are unsure whether your workstation and cluster are ready:

```bash
mise run k8s-doctor
```

What it does conceptually: checks the local environment for the commands,
scripts, keys, and cluster access needed by the repository's hardened Kubernetes
flows.

Success looks like: the doctor finishes without reporting missing staging
dependencies. If you only want a lighter local check for `dev`, use:

```bash
ATLAS_DOCTOR_SCOPE=dev mise run k8s-doctor
```

## Path 1: Deploy `dev`

Use `dev` when you need Kubernetes-specific validation for current app code but
you do not need Argo CD to own the environment.

### Step 1: Prepare tools and local app assets

```bash
mise install
mise run bootstrap
mise run app-bootstrap
```

What these do conceptually:

- `mise install` installs the pinned tool versions used by the repo.
- `mise run bootstrap` prepares Python, Node, hooks, and shared local tooling.
- `mise run app-bootstrap` installs the app-level dependencies needed to build the
  backend and frontend.

Success looks like: dependencies install cleanly and no bootstrap step reports a
missing runtime.

### Step 2: Preflight the cluster

```bash
mise run k8s-preflight
```

What it does conceptually: confirms the current cluster can support the repo's
local Kubernetes workflow before you spend time building images.

Success looks like: the preflight completes without failing capability checks.

### Step 3: Build and import local images

```bash
mise run k8s-build-images
mise run k8s-import-images
```

What these do conceptually:

- `mise run k8s-build-images` builds unique local image tags for this run and
  writes them to `.gitops-local/k3s/dev-images.env`.
- `mise run k8s-import-images` imports those exact images into k3s containerd so
  the cluster uses the build you just produced instead of a stale local image.

Success looks like: `.gitops-local/k3s/dev-images.env` exists and the import step
finishes without image-not-found errors.

### Step 4: Deploy the `dev` overlay

```bash
mise run k8s-deploy-dev
```

What it does conceptually:

1. reruns preflight checks,
2. removes the previous migration job,
3. cleans up any legacy PostgreSQL deployment shape,
4. renders and applies the `dev` overlay with the active local image refs,
5. recreates PostgreSQL if the `StatefulSet` definition changed,
6. waits for PostgreSQL,
7. recreates and waits for the Alembic migration job,
8. waits for backend and frontend workloads,
9. runs smoke checks against the API, frontend, and ingress.

Success looks like: pods in `atlas-platform-dev` reach a healthy state, the
migration job completes, and smoke checks pass.

### Step 5: Inspect and access the environment

```bash
mise run k8s-status
mise run k8s-access
```

What these do conceptually:

- `mise run k8s-status` shows the major resources and whether they are healthy.
- `mise run k8s-access` prints the hostname and URL hints you need to reach the
  environment.

Expected hostnames:

- `atlas.local`
- `api.atlas.local`

What to do next: continue app testing, inspect logs, or move to `staging-local`
if you need to rehearse Argo CD ownership.

## Path 2: Rehearse `staging-local`

Use `staging-local` when you want the staging topology and GitOps control plane,
but still want a local k3s cluster to supply the images.

### Step 1: Confirm GitOps bootstrap is complete

```bash
mise run gitops-install-tools
mise run gitops-bootstrap-core
mise run gitops-install-age-key
mise run gitops-install-repo-credential
mise run gitops-apply-apps
```

What this does conceptually: installs Argo CD, gives it the age key and repo
credential it needs, and creates the staging application object it will manage.

Success looks like: `atlas-platform-staging` exists in Argo CD and the cluster can
render encrypted manifests.

### Step 2: Deploy through the staging-local wrapper

```bash
ARGOCD_APP_REVISION=<remote-branch-or-commit> mise run gitops-deploy-staging
```

What it does conceptually on local k3s:

1. builds local `ghcr.io/...:main` image refs,
2. imports them into k3s,
3. points the Argo CD application at `platform/k8s/overlays/staging-local`,
4. waits for reconciliation,
5. runs the staging smoke checks.

Why this wrapper exists: it preserves the Argo CD plus KSOPS flow while avoiding a
hard dependency on published GHCR tags during local learning.

Success looks like: Argo CD sync completes, workloads become healthy in
`atlas-platform-staging`, and staging smoke checks pass.

### Step 3: Inspect the result

```bash
mise run k8s-status-staging
mise run k8s-access-staging
mise run k8s-smoke-staging
```

Expected hostnames:

- `staging.atlas.example.com`
- `api.staging.atlas.example.com`

What to do next: if the goal is only local rehearsal, stop here. If you need the
real release contract, continue with canonical `staging`.

## Path 3: Reconcile canonical `staging`

Use this path when you need the real pre-production contract: Argo CD,
registry-backed images, digest pinning, and staging-only hardening.

### Step 1: Validate the environment and manifests

```bash
mise run k8s-doctor
mise run k8s-validate-overlays
```

What these do conceptually:

- the doctor confirms the hardened staging prerequisites are present,
- the overlay validator renders `dev`, `staging`, and `staging-local`, applies
  common policy checks, and applies immutable-image rules only to canonical
  `staging`.

Success looks like: both commands complete without policy, signature, or missing
dependency failures.

### Step 2: Reconcile the canonical staging overlay

```bash
STAGING_LOCAL_IMAGES=0 \
ARGOCD_APP_REVISION=<remote-branch-or-commit> \
mise run gitops-deploy-staging
```

What it does conceptually: tells the staging deploy helper to stop using the local
wrapper and sync the real `platform/k8s/overlays/staging` overlay instead.

Why `STAGING_LOCAL_IMAGES=0` matters: without it, a local k3s deployment defaults
to the `staging-local` rehearsal path.

Success looks like: Argo CD syncs the canonical overlay, the migration job and app
pods become healthy, and the smoke checks pass without falling back to local image
behavior.

### Step 3: Inspect the final state

```bash
mise run k8s-status-staging
mise run k8s-access-staging
```

What to do next: if this deployment came from a new digest promotion, continue to
[the image promotion runbook](../releases/IMAGE_PROMOTION.md) and record the
verification outcome.

## Backups and restore for staging PostgreSQL

Use these commands before risky data work, during recovery rehearsals, or when you
need to prove that the staging database can be restored.

### Create a backup

```bash
mise run k8s-backup-postgres-staging
```

What it does conceptually: runs a timestamped `pg_dump -Fc` workflow against the
staging PostgreSQL instance and stores the result under
`.gitops-local/backups/staging/`.

Success looks like: a new `.dump` file exists and the command prints the matching
restore command.

Safe rehearsal:

```bash
ATLAS_POSTGRES_DRY_RUN=1 mise run k8s-backup-postgres-staging
```

### Restore a backup

```bash
BACKUP_FILE=.gitops-local/backups/staging/<timestamp>.dump \
ATLAS_CONFIRM_POSTGRES_RESTORE=atlas-platform-staging \
mise run k8s-restore-postgres-staging
```

What it does conceptually:

1. checks that `BACKUP_FILE` exists,
2. requires the exact destructive-action confirmation token,
3. loads the dump through an ephemeral restore job,
4. reapplies the environment,
5. waits for migrations,
6. reruns smoke checks.

Success looks like: the restore completes, the migration job succeeds, and the
environment passes smoke validation.

Use dry-run mode first if you only want to inspect the guarded workflow:

```bash
ATLAS_POSTGRES_DRY_RUN=1 mise run k8s-restore-postgres-staging
```

## Smoke checks, status, and direct inspection

Use these when the helper commands say something failed or when you want direct
cluster evidence.

### Status and events

```bash
mise run k8s-status
mise run k8s-status-staging
kubectl -n atlas-platform-dev get events --sort-by=.lastTimestamp
kubectl -n atlas-platform-staging get events --sort-by=.lastTimestamp
```

### Smoke checks

```bash
mise run k8s-smoke
mise run k8s-smoke-staging
```

What smoke checks verify conceptually:

- backend readiness at `/readyz`,
- the inventory API route,
- frontend HTTP response,
- ingress reachability for the environment hostnames,
- migration job completion.

### Common log commands

```bash
kubectl -n atlas-platform-dev logs deploy/inventory-service --tail=200 -f
kubectl -n atlas-platform-dev logs deploy/web --tail=200 -f
kubectl -n atlas-platform-dev logs statefulset/postgres --tail=200 -f
kubectl -n atlas-platform-dev logs job/inventory-migration --tail=200
kubectl -n atlas-platform-staging logs deploy/inventory-service --tail=200 -f
kubectl -n atlas-platform-staging logs deploy/web --tail=200 -f
kubectl -n atlas-platform-staging logs statefulset/postgres --tail=200 -f
kubectl -n atlas-platform-staging logs job/inventory-migration --tail=200
```

### Re-run the migration job in `dev`

```bash
kubectl -n atlas-platform-dev delete job inventory-migration --ignore-not-found
./scripts/gitops/render-overlay.sh platform/k8s/overlays/dev | kubectl apply -f -
kubectl -n atlas-platform-dev wait --for=condition=complete job/inventory-migration --timeout=300s
```

What it does conceptually: deletes the old migration job, reapplies the `dev`
overlay, and waits for a fresh migration run to finish.

## Teardown

Use teardown only when you no longer need the environment.

### Delete `dev`

```bash
mise run k8s-delete-dev
```

Success looks like: the `atlas-platform-dev` resources are removed.

### Delete staging safely

```bash
ATLAS_CONFIRM_STAGING_DELETE=atlas-platform-staging mise run k8s-delete-staging
```

What it does conceptually:

1. removes the Argo CD application without cascading deletes first,
2. avoids Argo CD self-heal recreating resources mid-teardown,
3. preserves the namespace and PostgreSQL PVC by default.

If you truly want to remove the persistent storage too, set
`PRESERVE_POSTGRES_PVC=0` deliberately.

## Quick troubleshooting map

### PostgreSQL does not start

- inspect `kubectl -n <namespace> logs statefulset/postgres`,
- confirm PVC provisioning and volume permissions,
- confirm the `postgres-secret` exists.

### The migration job does not finish

- inspect `kubectl -n <namespace> logs job/inventory-migration`,
- confirm `INVENTORY_DATABASE_URL`,
- confirm connectivity to `postgres:5432`.

### Traffic does not reach the app

- inspect active `NetworkPolicy` resources,
- confirm DNS egress policy is present,
- confirm ingress routing and PostgreSQL allow rules.

### Argo CD never settles in staging paths

- switch to the [GitOps runbook](../gitops/ARGOCD_SOPS_RUNBOOK.md),
- confirm the age key, repo credential, and application revision,
- rerun `mise run gitops-wait-staging` once the root cause is fixed.

## What success looks like overall

You can:

- choose the correct environment for the task,
- run the right command sequence without mixing local and canonical staging flows,
- prove workload health with status, smoke, and log evidence,
- recover or tear down staging with the expected safety guardrails.

## Read next

- [GitOps runbook](../gitops/ARGOCD_SOPS_RUNBOOK.md)
- [Image promotion runbook](../releases/IMAGE_PROMOTION.md)
- [Troubleshooting](../../reference/troubleshooting.md)
