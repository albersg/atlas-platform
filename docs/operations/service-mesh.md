# Service Mesh

Atlas Platform uses Istio as the staged service-mesh layer for `staging-local` and
canonical `staging`. This page explains what that means without assuming prior mesh
knowledge.

## What a service mesh means here

A service mesh is an extra networking layer around services. In this repo, Istio is
used to control staged ingress, workload-to-workload traffic behavior, and sidecar
injection for the staged environments.

If you are brand new to the topic, remember this:

- `dev` does not use the staged mesh path.
- `staging-local` and `staging` do.
- That is why traffic behavior differs between environments.

## What landed in this slice

- Argo CD now has an `atlas-platform-infra` project for upstream platform add-ons.
- Istio base, control plane, and ingress are defined as local wrapper charts under `platform/helm/istio/`.
- `./scripts/gitops/render-platform-infra.sh` renders deterministic Istio manifests for `staging-local` and `staging` before any cluster sync.
- `mise run k8s-validate-overlays` now schema-checks both workload overlays and the Helm-rendered platform-infra output.
- `mise run k8s-validate-overlays` now also runs `istioctl analyze` against the combined staging workload-plus-infra renders.
- `dev` keeps the Traefik ingress path through `platform/k8s/components/ingress/traefik/`.
- `staging-local` and `staging` now compose `platform/k8s/components/mesh/istio/` for `Gateway`, `VirtualService`, `DestinationRule`, permissive `PeerAuthentication`, and first-wave workload sidecar injection.
- Only `web`, `inventory-service`, and the `inventory-migration` job join the first mesh wave; PostgreSQL and postgres admin jobs remain outside it.

## Tool ownership

| Tool | Responsibility |
| --- | --- |
| Kustomize | first-party Atlas workloads under `platform/k8s` |
| Helm | upstream platform add-ons under `platform/helm` |
| Istio | staged non-production service-mesh infrastructure |
| Kyverno | repository policy checks across rendered outputs |

## Why Istio exists in this repo

- to make the staged path closer to a real platform topology,
- to separate the simple `dev` ingress path from the richer staged ingress path,
- to validate mesh onboarding incrementally instead of all at once,
- to keep staged routing explicit in Git.

## Current boundary

- `dev` stays on the existing non-mesh application path.
- `staging-local` is the first target for both Istio infrastructure inputs and workload mesh onboarding.
- canonical `staging` now mirrors the same workload component so promotion can reuse the rehearsal shape once `staging-local` is healthy.
- the existing `atlas-platform` Argo CD project remains the owner of Atlas workloads and only gains permission for mesh runtime resources that workloads will own later.

## First-wave traffic shape

- `dev` still serves `atlas.local` and `api.atlas.local` through Traefik.
- `staging-local` uses a local-only Istio NodePort exposure model so k3s Traefik can keep host ports `80/443` while Atlas traffic still enters through the mesh.
- canonical `staging` keeps the LoadBalancer-oriented gateway model and does not inherit the local NodePort compromise.
- `staging-local` and `staging` move Atlas traffic to the Istio ingress gateway on HTTP first, keeping the initial wave simple while hostnames stay stable.
- frontend traffic on `staging.atlas.example.com` routes `/` to `web` and `/api` to `inventory-service`.
- API traffic on `api.staging.atlas.example.com` routes directly to `inventory-service`.
- readiness probes are explicitly rewritten on sidecar-enabled deployments so health checks survive the first mesh cutover.
- first-wave workloads now carry `istio.io/rev=default`, and the app deployments bound proxy requests/limits to stay inside the namespace quota.

## Render commands

```bash
mise run gitops-render-platform-infra-staging-local >/dev/null
mise run gitops-render-platform-infra-staging >/dev/null
mise run k8s-validate-overlays
```

Use those commands to prove the wrapper charts, pinned versions, environment value files, and workload overlays still render cleanly.

## Validation contract

- `mise run k8s-validate-overlays` renders `dev`, `staging`, `staging-local`, and both Istio infra targets.
- Kyverno now blocks mesh runtime resources in `dev`, requires the first-wave staging sidecar annotations, and requires core Istio ingress/control-plane resources in rendered infra output.
- canonical `staging` adds mesh-routing assertions on top of the existing digest enforcement.
- `istioctl analyze` runs against the combined staging and staging-local render surfaces before rollout.

## What is still pending

- later hardening beyond the current permissive first wave.

## Rollback for this slice

If the first mesh wave needs to be backed out, remove `../../components/mesh/istio` from the staging overlays, resync the Atlas workload app, and keep using the Traefik-backed `dev` flow while leaving the Helm-managed Istio infra apps available for further rehearsal.

## Read next

- [Monitoring](monitoring.md)
- [Staging-local](staging-local.md)
- [Canonical staging](canonical-staging.md)
