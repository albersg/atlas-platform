# Canonical Staging

Canonical `staging` is the repo's real pre-production path. It is GitOps-managed,
uses encrypted manifests, and expects registry images pinned by digest.

This is the environment you trust for release-like validation. It is intentionally
stricter than `staging-local`.

## What "canonical" means here

In these docs, canonical means "the version we treat as the real reference path,"
not "the version that is easiest to run locally." Canonical `staging` is where
the repo proves that reviewable Git state, trusted images, encrypted overlays,
and staged runtime checks all work together.

## Before you start

You should already understand:

- [GitOps bootstrap](gitops-bootstrap.md)
- [Staging-local](staging-local.md)
- [Release workflow](release-workflow.md)
- [Staging promotion](staging-promotion.md)
- the difference between local `:main` rehearsal and digest-based promotion

## Typical operator flow

```bash
mise run k8s-doctor
mise run k8s-validate-overlays
STAGING_LOCAL_IMAGES=0 ARGOCD_APP_REVISION=<remote-branch-or-commit> mise run gitops-deploy-staging
mise run k8s-status-staging
mise run k8s-access-staging
```

Read that sequence like this:

1. `k8s-doctor` checks whether your machine, credentials, helper tools, and
   cluster prerequisites are in place.
2. `k8s-validate-overlays` proves the rendered manifests, policies, trust rules,
   and mesh analysis still pass before deployment.
3. `STAGING_LOCAL_IMAGES=0` tells the shared deploy wrapper to use canonical
   staging behavior instead of the local-image rehearsal path.
4. `ARGOCD_APP_REVISION=<remote-branch-or-commit>` tells Argo CD which Git
   revision to test in the staged topology.
5. `gitops-deploy-staging` applies the staged GitOps workflow.
6. `k8s-status-staging` and `k8s-access-staging` help you verify what actually
   came up and how to reach it.

## What makes canonical staging different

- it uses `platform/k8s/overlays/staging`, not `staging-local`,
- it uses the staged platform-infra value files under `values-staging.yaml`,
- it does not reuse the `staging-local` NodePort or PodSecurity compromises,
- it expects registry-backed images,
- it relies on immutable digests for promotion,
- trusted-image verification is part of the deployment story,
- staging-only hardening rules apply here.

## What `gitops-deploy-staging` does differently here

When you set `STAGING_LOCAL_IMAGES=0`, `scripts/gitops/deploy/staging.sh`:

1. switches the workload app path to `platform/k8s/overlays/staging`,
2. switches infra app value selection to `staging`,
3. skips local image build/import,
4. runs `scripts/release/verify-trusted-images.sh` before trusting the deployment,
5. waits for the full staged infra app set,
6. waits for the workload app,
7. runs staged mesh-aware smoke checks.

That means canonical staging is not just "staging-local, but remote". It adds a
release-trust gate before runtime verification even starts.

## Why digest promotion matters here

In canonical `staging`, a tag such as `:main` is not enough. Tags can move.
Digests cannot.

The repo therefore uses this trust chain:

1. images are built from `main`,
2. Trivy scans them,
3. Syft generates SBOMs,
4. Cosign signs the digests,
5. promotion rewrites Git to those exact digests,
6. canonical staging verifies those signed digests again before deployment.

## What to verify after deployment

- Argo CD sync completed.
- The full infra add-on set, including Prometheus in `monitoring`, is synced and healthy before the Atlas workload app.
- The staged workload overlay still owns the `inventory-service` `ServiceMonitor` and `/metrics` scrape intent.
- Workloads are healthy.
- The migration job completed.
- Smoke checks pass.
- Hostnames are reachable.
- The Istio ingress gateway is serving the workload hostnames.
- Kyverno and `istioctl analyze` passed before rollout.

## Expected hostnames

- `staging.atlas.example.com`
- `api.staging.atlas.example.com`

## Useful variables and helpers

| Variable or command | Why it matters |
| --- | --- |
| `STAGING_LOCAL_IMAGES=0` | activates canonical staging behavior in the shared deploy wrapper |
| `ARGOCD_APP_REVISION` | validates a remote branch or commit in the staged topology |
| `ATLAS_STAGING_INGRESS_SCHEME` | controls helper URL scheme and staged smoke assumptions |
| `mise run gitops-render-staging` | proves the canonical workload overlay still renders |
| `mise run gitops-render-platform-infra-staging` | proves the staged infra wrapper charts still render |

## Istio and Prometheus status in this slice

Canonical `staging` now has pinned Helm value inputs, the same first-wave mesh
workload component as `staging-local`, and a deterministic render path for the
Istio plus Prometheus infrastructure bundle.

```bash
mise run gitops-render-platform-infra-staging >/dev/null
```

That keeps promotion aligned with the rehearsal environment: validate
`staging-local` first, then move the canonical overlay through the same topology
shape with digest-backed images.

## Read next

- If you are preparing the digest inputs for this environment, read [Release workflow](release-workflow.md) next.
- If you are updating canonical `staging` to specific digests, read [Staging promotion](staging-promotion.md) next.
- If you are operating the running environment, read [Monitoring](monitoring.md) next.
- If you need recovery operations after deployment, read [Backup and restore](backup-restore.md) next.
