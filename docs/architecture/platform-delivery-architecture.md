# Platform Delivery Architecture

This page explains how the final platform architecture fits together and why the
repo uses several tools instead of one giant deployment mechanism.

## The architecture in one flow

1. Developers change app code, docs, or platform assets in Git.
2. `mise run ...` commands validate code, docs, overlays, and policy locally.
3. Helm renders reusable workload and infra bases.
4. Kustomize composes environment overlays and encrypted secrets.
5. Kyverno validates the rendered output.
6. Argo CD reconciles approved Git state into `staging-local` or canonical
   `staging`.
7. Istio handles staged ingress and service-mesh traffic.
8. Prometheus scrapes metrics from infra and workloads.

## Ownership by layer

| Layer | Main owner | What it is responsible for | What it should not own |
| --- | --- | --- | --- |
| Reusable workload base | Helm | Shared chart defaults and base packaging | Environment-specific overrides that differ per overlay |
| Platform add-ons | Helm | Istio and Prometheus wrapper charts with pinned versions | Workload-specific routing patches |
| Environment overlays | Kustomize | `dev`, `staging-local`, and `staging` differences | Reusable add-on packaging |
| Encrypted secrets | SOPS + age + KSOPS | Secret files stored encrypted in Git and decrypted at render time | Plain-text secrets in the repo |
| GitOps reconciliation | Argo CD | Applying Git-defined desired state continuously | Local one-off development loops |
| Policy enforcement | Kyverno | Blocking invalid rendered manifests | Replacing render or deployment tools |
| Traffic control | Istio | Gateways, virtual services, destination rules, sidecars | Local `dev` ingress |
| Monitoring | Prometheus | Scraping metrics from infra and workloads | Owning workload business logic |

## Why Helm and Kustomize both exist

This is the most important architecture rule in the repo.

- Use Helm when you need a reusable package or an upstream-chart wrapper.
- Use Kustomize when you need to adapt shared manifests to a specific environment.

Examples:

- Istio and Prometheus live as Helm-managed add-ons because they are reusable
  platform packages.
- `dev`, `staging-local`, and `staging` are Kustomize overlays because they are
  environment-specific shapes.
- The workload `ServiceMonitor` stays in the workload layer because monitoring intent
  for `inventory-service` belongs to the workload, not to the infra chart.

## Argo CD boundary model

Atlas Platform uses separate GitOps boundaries so infrastructure and workloads can
be reasoned about independently.

- The infra boundary contains Istio and Prometheus applications.
- The workload boundary contains the Atlas staging application.
- Argo CD waits for the infra stack first, then the Atlas workload app.

This matters because `staging` depends on mesh and monitoring infrastructure being
healthy before workload verification means anything.

## Environment ladder

| Environment | Delivery style | Image source | Traffic layer | Monitoring expectation |
| --- | --- | --- | --- | --- |
| Local | Docker Compose or direct processes | Local source build | No mesh | Basic local logs and app checks |
| `dev` | Direct helper-driven Kubernetes apply | Local images built per run | Traefik | Not the full staged monitoring path |
| `staging-local` | Argo CD reconciles a local staging wrapper | Local `:main` refs imported into k3s | Istio NodePort gateway | Prometheus in `monitoring` with reduced footprint |
| `staging` | Argo CD reconciles the canonical overlay | GHCR images pinned by digest | Istio staged gateway | Prometheus plus workload `ServiceMonitor` |

## Secret and trust model

- SOPS keeps secrets encrypted in Git.
- age provides the encryption keys.
- KSOPS decrypts during render.
- Trivy scans published images.
- Syft generates SBOMs.
- Cosign signs released images.
- Canonical `staging` trusts immutable digests, not mutable tags.

## Monitoring model

- Prometheus runs as a platform-infra add-on.
- Workloads expose metrics endpoints such as `/metrics`.
- Workload-owned `ServiceMonitor` objects tell Prometheus what to scrape.
- The first slice focuses on Prometheus itself plus `inventory-service` metrics.

Read [Monitoring](../operations/monitoring.md) for the operator view.

## Read next

1. [Deployment topology](deployment-topology.md)
2. [Operations overview](../operations/overview.md)
3. [GitOps bootstrap](../operations/gitops-bootstrap.md)
