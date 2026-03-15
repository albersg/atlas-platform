# Service Mesh

Atlas Platform now has a separate platform-infra path for Istio plus a first
workload onboarding slice for staging overlays.

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

## Current boundary

- `dev` stays on the existing non-mesh application path.
- `staging-local` is the first target for both Istio infrastructure inputs and workload mesh onboarding.
- canonical `staging` now mirrors the same workload component so promotion can reuse the rehearsal shape once `staging-local` is healthy.
- the existing `atlas-platform` Argo CD project remains the owner of Atlas workloads and only gains permission for mesh runtime resources that workloads will own later.

## First-wave traffic shape

- `dev` still serves `atlas.local` and `api.atlas.local` through Traefik.
- `staging-local` and `staging` move Atlas traffic to the Istio ingress gateway on HTTP first, keeping the initial wave simple while hostnames stay stable.
- frontend traffic on `staging.atlas.example.com` routes `/` to `web` and `/api` to `inventory-service`.
- API traffic on `api.staging.atlas.example.com` routes directly to `inventory-service`.
- readiness probes are explicitly rewritten on sidecar-enabled deployments so health checks survive the first mesh cutover.

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

- live proof that the full `staging-local` rollout converges end to end on a real cluster,
- any post-onboarding hardening beyond the current permissive first wave.

## Rollback for this slice

If the first mesh wave needs to be backed out, remove `../../components/mesh/istio` from the staging overlays, resync the Atlas workload app, and keep using the Traefik-backed `dev` flow while leaving the Helm-managed Istio infra apps available for further rehearsal.
