# Operations Overview

This section explains how Atlas Platform moves from local development into the
repository's non-production platform workflows.

## Platform toolchain at a glance

| Tool or concept | Role in Atlas Platform |
| --- | --- |
| Kubernetes or `k8s` | the target platform model for cluster-based environments |
| k3s | the lightweight local Kubernetes distribution used for `dev` and `staging-local` |
| `kubectl` | the direct CLI for inspecting cluster resources |
| Kustomize | builds environment-specific overlays from reusable manifest pieces |
| Argo CD | reconciles Git-defined state into the cluster |
| GitOps | the operating model that says Git is the desired source of truth |
| SOPS and age | keep secrets encrypted while still storing them in the repo |
| KSOPS | decrypts SOPS files during Kustomize rendering |
| Kyverno | enforces repository policy rules over rendered manifests |
| Trivy, Cosign, Syft, SBOMs | protect the image release and promotion path |

## Read this section in order

1. [Local Compose](local-compose.md)
2. [k3s dev environment](k3s-dev.md)
3. [GitOps bootstrap](gitops-bootstrap.md)
4. [Staging-local](staging-local.md)
5. [Canonical staging](canonical-staging.md)
6. [Backup and restore](backup-restore.md)
7. [Release workflow](release-workflow.md)
8. [Staging promotion](staging-promotion.md)

## Environment model

| Environment | Primary purpose | Typical commands |
| --- | --- | --- |
| Local | build app features quickly | `compose-up`, `backend-dev`, `frontend-dev` |
| `dev` | validate Kubernetes overlays with local images | `k8s-build-images`, `k8s-import-images`, `k8s-deploy-dev` |
| `staging-local` | rehearse Argo CD + SOPS on a local cluster | `gitops-deploy-staging` |
| `staging` | canonical pre-production path | digest promotion plus Argo CD reconciliation |

## Important boundaries

- `dev` is a local k3s lab, not the canonical staging path.
- `staging-local` exists to learn and validate the topology locally without weakening canonical `staging`.
- `staging` should consume registry images by digest, not local dev images.
- Kubernetes knowledge matters most from `dev` onward; Compose is intentionally a simpler first step.
- Production is intentionally outside the repo's current operational scope.

## Where the deep detail lives

- [Deployment runbooks index](../deployment/README.md)
- [k3s runbook](../deployment/k3s/RUNBOOK.md)
- [GitOps runbook](../deployment/gitops/ARGOCD_SOPS_RUNBOOK.md)
- [Image promotion runbook](../deployment/releases/IMAGE_PROMOTION.md)
