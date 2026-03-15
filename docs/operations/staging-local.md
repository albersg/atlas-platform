# Staging-Local

`staging-local` is the local rehearsal path for the staging topology. It keeps
the Argo CD and KSOPS flow, but uses local `:main` images on k3s so you can
learn and validate without requiring published GHCR digests.

## Main command

```bash
ARGOCD_APP_REVISION=<remote-branch-or-commit> mise run gitops-deploy-staging
```

## What it does

- builds local staging image refs by default,
- imports them into the local k3s runtime,
- patches the Argo CD application to use `platform/k8s/overlays/staging-local`,
- waits for synchronization,
- runs smoke checks.

## Why this environment exists

- to practice the GitOps workflow locally,
- to validate Argo CD reconciliation and encrypted overlay rendering,
- to avoid weakening the canonical `staging` contract.

## What it is not

- It is not the canonical `staging` environment.
- It is not the digest-promotion path.
- It is not a replacement for release verification.

## Supporting commands

- `mise run gitops-wait-staging`
- `mise run k8s-status-staging`
- `mise run k8s-access-staging`
- `mise run k8s-smoke-staging`

## Read next

- [Canonical staging](canonical-staging.md)
- [Staging promotion](staging-promotion.md)
