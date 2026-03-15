# Staging-Local

`staging-local` is the local rehearsal path for the staging topology. It keeps
the Argo CD and KSOPS flow, but uses local `:main` images on k3s so you can
learn and validate without requiring published GHCR digests.

In the current Istio slice, `staging-local` is also the default target for the
new platform-infra applications under `platform/helm/istio/` and the first
mesh-enabled workload overlay under `platform/k8s/components/mesh/istio/`.

## Main command

```bash
ARGOCD_APP_REVISION=<remote-branch-or-commit> mise run gitops-deploy-staging
```

## What it does

- builds local staging image refs by default,
- imports them into the local k3s runtime,
- keeps the Istio infra applications pointed at `values-staging-local.yaml`,
- patches the Argo CD application to use `platform/k8s/overlays/staging-local`,
- exposes the Istio ingress gateway through fixed local NodePorts instead of competing with k3s Traefik for host ports `80/443`,
- routes hostname traffic through the Istio ingress gateway instead of the dev Traefik component,
- injects sidecars only into `web`, `inventory-service`, and `inventory-migration`,
- waits for synchronization,
- waits for the three Istio infra applications before the workload application,
- runs smoke checks.

## Why this environment exists

- to practice the GitOps workflow locally,
- to prove the new Helm-managed Istio render path before canonical staging promotion,
- to validate Argo CD reconciliation and encrypted overlay rendering,
- to verify the first-wave mesh behavior without pulling PostgreSQL into the mesh,
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
- `mise run gitops-render-platform-infra-staging-local`
- `mise run k8s-doctor`

## Current mesh notes

- hostnames stay `staging.atlas.example.com` and `api.staging.atlas.example.com`, but `staging-local` reaches them through the Istio gateway NodePort (`32080` for HTTP, `32443` reserved for a later HTTPS cutover) rather than host ports `80/443`,
- `platform/helm/istio/gateway/values-staging-local.yaml` is intentionally local-only; canonical `staging` keeps the LoadBalancer-facing model,
- the `atlas-platform-staging` namespace relaxes PodSecurity admission only in `staging-local` because Istio CNI is not installed in the local k3s rehearsal cluster,
- `web` and `inventory-service` now pin `istio.io/rev=default` plus bounded sidecar resources so injection and quota usage converge from Git,
- readiness and liveness probes on `web` and `inventory-service` are rewritten for sidecar injection,
- smoke checks now confirm the Istio ingress deployment plus workload sidecars before hostname probes,
- PostgreSQL, backup jobs, and restore jobs stay outside the mesh.

## Read next

- [Canonical staging](canonical-staging.md)
- [Staging promotion](staging-promotion.md)
