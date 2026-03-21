# Staging-Local

`staging-local` is the local rehearsal path for the staging topology. It keeps
the Argo CD and KSOPS flow, but uses local `:main` images on k3s so you can learn
and validate the real architecture without requiring published GHCR digests.

If you remember one sentence, remember this one: `staging-local` teaches the real
architecture locally, but it does not replace canonical digest-driven `staging`.

## What owns this environment

| Layer | Owner in this repo | Main files |
| --- | --- | --- |
| workload overlay | Kustomize workload layer | `platform/k8s/overlays/staging-local/**` |
| platform-infra apps | Helm wrapper chart layer | `platform/helm/istio/**`, `platform/helm/prometheus/**` |
| GitOps app definitions | Argo CD app layer | `platform/argocd/apps/**` |
| deploy orchestration | staged deploy script | `scripts/gitops/deploy/staging.sh` |
| smoke verification | staged smoke helper | `scripts/k3s/verify/smoke.sh` |

In the current staged slice, `staging-local` is also the default target for the
platform-infra applications under `platform/helm/istio/` and
`platform/helm/prometheus/`, plus the first mesh-enabled workload overlay under
`platform/k8s/components/mesh/istio/`.

## Main command

```bash
ARGOCD_APP_REVISION=<remote-branch-or-commit> mise run gitops-deploy-staging
```

## What happens under the hood

When `STAGING_LOCAL_IMAGES` stays at its default `1`, `scripts/gitops/deploy/staging.sh`:

1. sets `ARGOCD_APP_PATH=platform/k8s/overlays/staging-local`,
2. sets `ARGOCD_ENVIRONMENT=staging-local`,
3. builds local staging image refs with `scripts/k3s/images/build-staging.sh`,
4. imports those refs into k3s with `scripts/k3s/images/import-staging.sh`,
5. runs `ATLAS_DOCTOR_SCOPE=staging` doctor checks,
6. ensures Argo CD, the age key, and the repo credential exist,
7. applies the Argo CD app bundle,
8. waits for the platform-infra apps in order,
9. waits for the workload app,
10. restarts `inventory-service` and `web` so mutable local images are actually reloaded,
11. prints staging status,
12. runs mesh-aware smoke checks.

## What this environment does

- keeps infra applications pointed at `values-staging-local.yaml`,
- patches the Argo CD workload app to use `platform/k8s/overlays/staging-local`,
- exposes the Istio ingress gateway through fixed local NodePorts instead of competing with k3s Traefik for host ports `80/443`,
- routes hostname traffic through the Istio ingress gateway instead of the `dev` Traefik path,
- deploys Prometheus into the dedicated `monitoring` namespace with a reduced local footprint,
- injects sidecars only into the first-wave workloads,
- uses local mutable images while preserving the same GitOps, mesh, and monitoring architecture as canonical staging.

Expected outcome: your local k3s cluster now behaves like a rehearsal version of
the real staging topology.

## Why this environment exists

- to practice the GitOps workflow locally,
- to validate the Helm-managed Istio and Prometheus render path before canonical promotion,
- to prove that workload overlays and platform-infra apps compose cleanly,
- to verify staged mesh behavior before trusting canonical staging,
- to avoid weakening the stricter canonical staging contract.

## What it is not

- It is not canonical `staging`.
- It is not the digest-promotion path.
- It is not proof that release artifacts were built, scanned, signed, and promoted correctly.

## How it differs from `dev` and canonical `staging`

| Environment | Main goal | Image source | Traffic layer | Deployment model |
| --- | --- | --- | --- | --- |
| `dev` | fast Kubernetes validation | local unique dev image builds | Traefik | direct local overlay deployment |
| `staging-local` | rehearse the real GitOps topology locally | local `:main` refs | Istio NodePort gateway | Argo CD + staged infra apps |
| `staging` | real pre-production verification | GHCR digests | Istio staged gateway | Argo CD + digest promotion |

## Supporting commands

- `mise run k8s-doctor`
- `mise run gitops-wait-staging`
- `mise run k8s-status-staging`
- `mise run k8s-access-staging`
- `mise run k8s-smoke-staging`
- `mise run gitops-render-platform-infra-staging-local`

## Important environment variables

| Variable | Why you care |
| --- | --- |
| `ARGOCD_APP_REVISION` | test a pushed branch or commit without changing committed app manifests |
| `STAGING_LOCAL_IMAGES` | leaving it at `1` keeps the rehearsal path; setting `0` switches to canonical staging behavior |
| `ATLAS_STAGING_LOCAL_INGRESS_SCHEME` | changes the helper URLs and smoke behavior for the local gateway |
| `ATLAS_STAGING_LOCAL_HTTP_PORT` | default local HTTP NodePort for the Istio gateway |
| `ATLAS_STAGING_LOCAL_HTTPS_PORT` | reserved local HTTPS NodePort for a later TLS cutover |
| `ARGOCD_WAIT_TIMEOUT_SECONDS` | lengthens or shortens staged app wait timeouts |

## Prometheus notes

- `platform/helm/prometheus/kube-prometheus-stack/values-staging-local.yaml` keeps Prometheus on conservative storage and memory settings for local k3s.
- The first slice enables the Prometheus control plane only; Grafana and Alertmanager stay disabled.
- `platform/k8s/components/observability/prometheus/inventory-service-monitor.yaml` keeps workload scrape intent in the workload layer, not the infra chart.
- `inventory-service` exposes `/metrics`, and staged overlays compose a workload-owned `ServiceMonitor` labeled for the `atlas-platform-prometheus` release.
- `mise run k8s-status-staging` shows the `monitoring` namespace alongside the mesh runtime.
- `mise run k8s-doctor` checks the Prometheus Argo CD app and core monitoring runtime before you trust the environment.

If Prometheus is healthy but the workload is missing from scrape targets, inspect
the workload `ServiceMonitor` next.

## Current mesh notes

- Hostnames stay `staging.atlas.example.com` and `api.staging.atlas.example.com`, but `staging-local` reaches them through the Istio gateway NodePort model.
- `platform/helm/istio/gateway/values-staging-local.yaml` is intentionally local-only; canonical staging keeps the LoadBalancer-facing model.
- The staging namespace relaxes PodSecurity admission only in `staging-local` because Istio CNI is not installed in the local rehearsal cluster.
- `web`, `inventory-service`, and the migration job are the current first-wave mesh workloads.
- Readiness and liveness probes are rewritten for sidecar injection.
- PostgreSQL and postgres admin jobs stay outside the mesh.

## Read next

- If you have not bootstrapped Argo CD, age, and repo credentials yet, go back to [GitOps bootstrap](gitops-bootstrap.md).
- If you are here to understand staged traffic behavior, read [Service mesh](service-mesh.md) next.
- If you are here to understand staged metrics and Prometheus ownership, read [Monitoring](monitoring.md) next.
- If you are ready to compare rehearsal with the real pre-production contract, read [Canonical staging](canonical-staging.md) next.
- If you are actually preparing digest-based rollout, skip to [Staging promotion](staging-promotion.md).
