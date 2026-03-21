# Monitoring

This page explains how monitoring works in the final Atlas Platform architecture.
The short version is: Prometheus is platform infrastructure, but deciding that a
workload should be scraped is still a workload responsibility.

## What monitoring means here

Atlas Platform uses Prometheus as the first observability slice for staged
environments.

- Prometheus is deployed as a platform-infra add-on.
- The first workload monitoring target is `inventory-service`.
- Workloads expose metrics endpoints such as `/metrics`.
- Workload-owned `ServiceMonitor` objects tell Prometheus what to scrape.

## Ownership model

| Concern | Owner in this repo | Main files |
| --- | --- | --- |
| Prometheus platform add-on | Helm platform-infra layer | `platform/helm/prometheus/kube-prometheus-stack/**` |
| staged environment selection | Argo CD app patching plus staged deploy flow | `platform/argocd/apps/atlas-platform-prometheus.yaml`, `scripts/gitops/bootstrap/apply-apps.sh` |
| workload scrape intent | Kustomize workload observability layer | `platform/k8s/components/observability/prometheus/inventory-service-monitor.yaml` |
| health inspection | cluster helpers | `scripts/k3s/cluster/doctor.sh`, `scripts/k3s/cluster/status.sh`, `scripts/k3s/verify/smoke.sh` |

This split is important. Prometheus is shared infra, but the decision to expose a
workload metric endpoint belongs to the workload itself.

## Plain-language definitions

| Term | What it means in this repo |
| --- | --- |
| Prometheus | the monitoring system that scrapes and stores metrics |
| metrics | numeric measurements such as request counts, latency, or process health |
| scrape | Prometheus visiting an HTTP endpoint to collect metrics |
| `ServiceMonitor` | a Kubernetes object that tells Prometheus which service and port to scrape |
| `monitoring` namespace | the namespace where the staged Prometheus stack runs |

## How monitoring composes with the rest of the platform

1. Helm wrapper charts package the Prometheus stack for staged environments.
2. Argo CD reconciles that Prometheus application alongside the Istio infra apps and workload app.
3. Kustomize overlays include the workload-owned `ServiceMonitor`.
4. `inventory-service` exposes `/metrics`.
5. `mise run k8s-validate-overlays` asserts that staged renders still include the `ServiceMonitor` and `/metrics` path.
6. `mise run k8s-doctor`, `mise run k8s-status-staging`, and smoke checks inspect the live result.

That is why monitoring is both an infra concern and a workload concern.

## Environment differences

| Environment | Monitoring story |
| --- | --- |
| Local | usually logs and direct app checks only |
| `dev` | useful for app smoke checks, but not the full staged Prometheus path |
| `staging-local` | runs a reduced Prometheus footprint in `monitoring` on local k3s |
| `staging` | runs the canonical staged monitoring path |

## What to verify after a staged deployment

1. the `atlas-platform-prometheus` Argo CD app synced,
2. the Prometheus operator deployment is healthy in `monitoring`,
3. the Prometheus StatefulSet is healthy in `monitoring`,
4. the target workload is healthy,
5. the workload `ServiceMonitor` exists with the expected labels,
6. the workload exposes `/metrics`.

## Helpful commands

```bash
mise run k8s-doctor
mise run k8s-status-staging
mise run k8s-smoke-staging
mise run gitops-render-platform-infra-staging >/dev/null
mise run gitops-render-platform-infra-staging-local >/dev/null
```

- `mise run k8s-doctor`: checks whether the staged GitOps and monitoring pieces are present before you trust the environment.
- `mise run k8s-status-staging`: shows workload, mesh, and monitoring status.
- `mise run k8s-smoke-staging`: verifies the app still exposes `/metrics` as part of staged smoke.
- The render commands prove the Prometheus chart inputs still render cleanly.

## Important beginner confusions to avoid

- Prometheus is not the same thing as a `ServiceMonitor`.
- A `ServiceMonitor` does not collect metrics by itself; it only tells Prometheus what to scrape.
- Prometheus being healthy does not prove your workload metrics are wired.
- `staging-local` monitoring is a rehearsal path, not proof of canonical release trust.

## Read next

1. [Service mesh](service-mesh.md)
2. [Staging-local](staging-local.md)
3. [Canonical staging](canonical-staging.md)
4. [Troubleshooting](../reference/troubleshooting.md)
