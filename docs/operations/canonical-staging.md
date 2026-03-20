# Canonical Staging

Canonical `staging` is the repo's real pre-production path. It is GitOps-managed,
uses encrypted manifests, and expects registry images pinned by digest.

## Before you start

You should already understand:

- [GitOps bootstrap](gitops-bootstrap.md)
- [Staging-local](staging-local.md)
- the difference between local `:main` rehearsal and digest-based promotion

## Typical operator flow

```bash
mise run k8s-doctor
mise run k8s-validate-overlays
STAGING_LOCAL_IMAGES=0 ARGOCD_APP_REVISION=<remote-branch-or-commit> mise run gitops-deploy-staging
mise run k8s-status-staging
mise run k8s-access-staging
```

## What makes canonical staging different

- it uses `platform/k8s/overlays/staging`, not `staging-local`,
- it has parallel `platform/helm/istio/*/values-staging.yaml` and `platform/helm/prometheus/*/values-staging.yaml` render surfaces plus the same mesh workload component shape as `staging-local`,
- it does not reuse the `staging-local` NodePort exposure model or local PodSecurity relaxation,
- it expects registry-backed images,
- it relies on immutable digests for promotion,
- staging-only hardening rules apply here,
- trusted-image verification matters here.

## What to verify after deployment

- Argo CD sync completed,
- the full infra add-on set, including Prometheus in `monitoring`, is synced and healthy before the Atlas workload app,
- the staged workload overlay still owns the `inventory-service` `ServiceMonitor` and `/metrics` scrape intent,
- workloads are healthy,
- migration job completed,
- smoke checks pass,
- hostnames are reachable,
- the Istio ingress gateway is serving the workload hostnames,
- `istioctl analyze` and Kyverno validation both passed before rollout.

## Expected hostnames

- `staging.atlas.example.com`
- `api.staging.atlas.example.com`

## Istio status in this slice

Canonical `staging` now has pinned Helm value inputs, the same first-wave mesh
workload component as `staging-local`, and a deterministic render path for the
Istio plus Prometheus infrastructure bundle:

```bash
mise run gitops-render-platform-infra-staging >/dev/null
```

That keeps promotion aligned with the rehearsal environment: validate
`staging-local` first, then move the canonical overlay through the same mesh
shape with digest-backed images.

## Read next

- [Backup and restore](backup-restore.md)
- [Release workflow](release-workflow.md)
- [Staging promotion](staging-promotion.md)
