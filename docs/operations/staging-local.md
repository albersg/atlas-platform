# Staging-Local

`staging-local` is the local rehearsal path for the staging topology. It keeps
the Argo CD and KSOPS flow, but uses local `:main` images on k3s so you can
learn and validate without requiring published GHCR digests.

In the current staged slice, `staging-local` is also the default target for the
platform-infra applications under `platform/helm/istio/` and
`platform/helm/prometheus/`, plus the first mesh-enabled workload overlay under
`platform/k8s/components/mesh/istio/`.

## Main command

```bash
ARGOCD_APP_REVISION=<remote-branch-or-commit> mise run gitops-deploy-staging
```

## What it does

- builds local staging image refs by default,
- imports them into the local k3s runtime,
- keeps the infra applications pointed at `values-staging-local.yaml`,
- patches the Argo CD application to use `platform/k8s/overlays/staging-local`,
- exposes the Istio ingress gateway through fixed local NodePorts instead of competing with k3s Traefik for host ports `80/443`,
- routes hostname traffic through the Istio ingress gateway instead of the dev Traefik component,
- deploys Prometheus into the dedicated `monitoring` namespace with a reduced local footprint,
- injects sidecars only into `web`, `inventory-service`, and `inventory-migration`,
- waits for synchronization,
- waits for the full infra app set before the workload application,
- runs smoke checks.

## Why this environment exists

- to practice the GitOps workflow locally,
- to prove the new Helm-managed Istio render path before canonical staging promotion,
- to prove the first Prometheus infra add-on can ride the same Helm-plus-Argo-CD contract without pulling in the full observability stack,
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

## Prometheus notes

- `platform/helm/prometheus/kube-prometheus-stack/values-staging-local.yaml` keeps Prometheus on conservative storage and memory settings for local k3s,
- the first slice enables the Prometheus control plane only; Grafana and Alertmanager stay disabled,
- `platform/k8s/components/observability/prometheus/inventory-service-monitor.yaml` keeps the first workload scrape contract in the workload layer, not the infra chart,
- `inventory-service` now exposes `/metrics`, and the staged overlays compose a workload-owned `ServiceMonitor` labeled for the `atlas-platform-prometheus` release,
- `mise run k8s-status-staging` now shows the `monitoring` namespace alongside the mesh runtime,
- `mise run k8s-doctor` checks that the Prometheus Argo CD app, operator deployment, Prometheus StatefulSet, and service exist before you trust the environment.

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
