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
- it expects registry-backed images,
- it relies on immutable digests for promotion,
- staging-only hardening rules apply here,
- trusted-image verification matters here.

## What to verify after deployment

- Argo CD sync completed,
- workloads are healthy,
- migration job completed,
- smoke checks pass,
- hostnames are reachable.

## Expected hostnames

- `staging.atlas.example.com`
- `api.staging.atlas.example.com`

## Read next

- [Backup and restore](backup-restore.md)
- [Release workflow](release-workflow.md)
- [Staging promotion](staging-promotion.md)
