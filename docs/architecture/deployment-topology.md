# Deployment Topology

## Local development

Local development still supports Docker Compose for a fast single-host loop:

- `postgres` for persistence,
- `inventory-service` as API,
- `web` as UI.

## Kubernetes environment model

The Kubernetes layout is now split by responsibility and non-production environment:

- `platform/k8s/base`: environment-neutral application manifests shared by every overlay.
- `platform/k8s/components/in-cluster-postgres`: reusable PostgreSQL StatefulSet component for non-production clusters.
- `platform/k8s/components/images/dev`: local image selection for `dev`.
- `platform/k8s/components/images/staging`: registry-backed image selection for `staging`, promoted by digest.
- `platform/k8s/overlays/dev`: local k3s environment with local images and in-cluster PostgreSQL.
- `platform/k8s/overlays/staging`: pre-production overlay reconciled through Argo CD and backed by registry images.

The current operational scope of this repository stops at `dev` and `staging`.

## Argo CD model

- `platform/argocd/core`: Argo CD installation and KSOPS/SOPS integration.
- `platform/argocd/apps`: staging GitOps bundle.

`dev` stays local-lab friendly. `staging` is the registry-backed GitOps environment.

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
- policy-as-code validation for `dev` and `staging` overlays.

## Future production path

When production becomes a real target, it should be introduced behind separate infrastructure rather than by stretching the local non-production model:

- a separate production cluster,
- immutable images promoted by digest,
- manual production syncs,
- external secret management,
- a managed production database or an operator-backed stateful database,
- admission policies that enforce the deployment contract.
