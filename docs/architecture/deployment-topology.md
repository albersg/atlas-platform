# Deployment Topology

## Local development

Local development is the simplest path:

- Docker Compose can run `postgres`, `inventory-service`, and `web` together.
- You can also run backend and frontend separately for faster single-surface work.
- No GitOps controller or service mesh is involved here.

## Kubernetes environment model

The Kubernetes layout is split by responsibility and environment:

- `platform/helm/charts/atlas-platform`: reusable Atlas workload base.
- `platform/k8s/base`: environment-neutral application manifests shared by every overlay.
- `platform/k8s/components/in-cluster-postgres`: reusable PostgreSQL StatefulSet component for non-production clusters.
- `platform/k8s/components/images/dev`: local image selection for `dev`.
- `platform/k8s/components/images/staging`: registry-backed image selection for `staging`, promoted by digest.
- `platform/k8s/components/images/staging-local`: local `:main` image selection for `staging-local`.
- `platform/k8s/components/mesh/istio`: staged workload mesh resources.
- `platform/k8s/components/observability/prometheus`: workload-owned monitoring resources.
- `platform/k8s/overlays/dev`: local k3s environment with local images and in-cluster PostgreSQL.
- `platform/k8s/overlays/staging-local`: local rehearsal wrapper for the staging topology.
- `platform/k8s/overlays/staging`: pre-production overlay reconciled through Argo CD and backed by registry images.

The current operational scope of this repository stops at local work plus `dev`,
`staging-local`, and canonical `staging`.

## Argo CD model

- `platform/argocd/core`: Argo CD installation and KSOPS/SOPS integration.
- `platform/argocd/apps`: workload and infra GitOps applications.

`dev` stays local-lab friendly. `staging-local` rehearses the real topology on k3s.
Canonical `staging` is the registry-backed GitOps environment.

## Release model

The target release path is:

1. build and publish OCI images once from `main`,
2. scan and sign those images,
3. promote `staging` by digest through a pull request,
4. let Argo CD deploy the approved manifests.

See `docs/deployment/releases/IMAGE_PROMOTION.md` for the concrete promotion flow.

## Security posture

Current manifests already include:

- explicit NetworkPolicies,
- resource requests and limits,
- namespace `LimitRange` and `ResourceQuota` guardrails,
- probes for long-running workloads,
- PDBs and HPAs for app tiers,
- SOPS-encrypted secrets for GitOps rendering,
- policy-as-code validation for `dev`, `staging-local`, and `staging` overlays,
- staged Istio routing and sidecar policies,
- staged Prometheus monitoring through a dedicated `monitoring` namespace.

## Future production path

When production becomes a real target, it should be introduced behind separate infrastructure rather than by stretching the local non-production model:

- a separate production cluster,
- immutable images promoted by digest,
- manual production syncs,
- external secret management,
- a managed production database or an operator-backed stateful database,
- admission policies that enforce the deployment contract.
