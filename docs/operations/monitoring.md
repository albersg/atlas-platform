# Monitoring

This page explains how monitoring works in the final Atlas Platform architecture.

## What monitoring means here

Atlas Platform uses Prometheus as the first observability slice for staged
environments.

- Prometheus is deployed as a platform-infra add-on.
- The first workload monitoring target is `inventory-service`.
- Workloads expose metrics endpoints such as `/metrics`.
- Workload-owned `ServiceMonitor` objects tell Prometheus what to scrape.

## Plain-language definitions

| Term | What it means in this repo |
| --- | --- |
| Prometheus | The monitoring system that scrapes and stores metrics |
| metrics | Numeric measurements such as request counts, latency, or process health |
| scrape | Prometheus visiting an HTTP endpoint to collect metrics |
| `ServiceMonitor` | A Kubernetes object that tells Prometheus which service and port to scrape |
| `monitoring` namespace | The namespace where the staged Prometheus stack runs |

## Ownership model

- Helm owns the Prometheus add-on packaging under `platform/helm/prometheus/`.
- Kustomize overlays own environment-specific wiring.
- The workload layer owns the `inventory-service` `ServiceMonitor` because scrape
  intent belongs to the workload.

This split is important. Prometheus is shared infra, but the decision to expose a
workload metric endpoint belongs to the workload itself.

## Environment differences

| Environment | Monitoring story |
| --- | --- |
| Local | Usually logs and direct app checks only |
| `dev` | Useful for app smoke checks, but not the full staged Prometheus path |
| `staging-local` | Runs a reduced Prometheus footprint in `monitoring` on local k3s |
| `staging` | Runs the canonical staged monitoring path |

## What to verify

After a staged deployment, verify these things in order:

1. the `atlas-platform-prometheus` Argo CD app synced,
2. the Prometheus operator and StatefulSet are healthy in `monitoring`,
3. the target workload is healthy,
4. the workload `ServiceMonitor` exists with the expected labels,
5. the workload exposes `/metrics`.

## Helpful commands

```bash
mise run k8s-doctor
mise run k8s-status-staging
mise run gitops-render-platform-infra-staging >/dev/null
mise run gitops-render-platform-infra-staging-local >/dev/null
```

- `mise run k8s-doctor`: checks whether the staged GitOps and monitoring pieces are
  present before you trust the environment.
- `mise run k8s-status-staging`: shows workload, mesh, and monitoring status.
- The render commands prove the Prometheus chart inputs still render cleanly.

## Common beginner confusion

- Prometheus is not the same thing as a `ServiceMonitor`.
- A `ServiceMonitor` does not collect metrics by itself; it only tells Prometheus
  what to scrape.
- Prometheus being healthy does not prove your workload metrics are wired.
- `staging-local` monitoring is a rehearsal path, not proof of canonical release.

## Read next

1. [Staging-local](staging-local.md)
2. [Canonical staging](canonical-staging.md)
3. [Troubleshooting](../reference/troubleshooting.md)
