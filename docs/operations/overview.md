# Operations Overview

This section explains how Atlas Platform moves from local development into the
repository's non-production platform workflows. Read it as an environment ladder:
start simple, then add more platform concepts only when you need them.

## Three ideas to keep in your head while reading

- A local environment is for learning and coding quickly on one machine.
- A cluster environment is for checking how the app behaves when Kubernetes is in charge.
- A GitOps environment is for checking how the platform behaves when Git, Argo CD,
  encrypted secrets, and staged infrastructure all work together.

If those three ideas are clear, the rest of the operations docs stop feeling like
random tool accumulation.

## A few words that matter a lot here

| Word | Plain-language meaning in these docs |
| --- | --- |
| reconcile | notice that the live cluster differs from Git and make the cluster match Git again |
| overlay | the environment-specific layer that changes a reusable base for `dev`, `staging-local`, or `staging` |
| platform-infra | shared infrastructure apps such as Istio and Prometheus that support workloads but are not the workload itself |
| workload | the application resources for Atlas Platform itself, such as the backend, frontend, jobs, and their service wiring |
| canonical staging | the stricter, reviewable pre-production path that uses promoted registry digests instead of local images |

## Platform toolchain at a glance

| Tool or concept | Role in Atlas Platform |
| --- | --- |
| Kubernetes or `k8s` | the target platform model for cluster-based environments |
| k3s | the lightweight local Kubernetes distribution used for `dev` and `staging-local` |
| `kubectl` | the direct CLI for inspecting cluster resources |
| Helm | defines reusable workload and platform add-on bases, including upstream chart wrappers |
| Kustomize | builds environment-specific overlays, patches, and KSOPS-backed secret composition |
| Argo CD | reconciles Git-defined state into the cluster |
| GitOps | the operating model that says Git is the desired source of truth |
| SOPS and age | keep secrets encrypted while still storing them in the repo |
| KSOPS | decrypts SOPS files during Kustomize rendering |
| Istio | provides the staged non-production service-mesh layer |
| Kyverno | enforces repository policy rules over rendered manifests |
| Prometheus and `ServiceMonitor` | collect and define staged monitoring targets |
| Trivy, Cosign, Syft, SBOMs | protect the image release and promotion path |

## Read this section in order

1. [Local Compose](local-compose.md)
2. [k3s dev environment](k3s-dev.md)
3. [GitOps bootstrap](gitops-bootstrap.md)
4. [Service mesh](service-mesh.md)
5. [Monitoring](monitoring.md)
6. [Staging-local](staging-local.md)
7. [Canonical staging](canonical-staging.md)
8. [Backup and restore](backup-restore.md)
9. [Release workflow](release-workflow.md)
10. [Staging promotion](staging-promotion.md)

## Environment model

| Environment | Primary purpose | Typical commands |
| --- | --- | --- |
| Local | build app features quickly | `compose-up`, `backend-dev`, `frontend-dev` |
| `dev` | validate Kubernetes overlays with local images | `k8s-build-images`, `k8s-import-images`, `k8s-deploy-dev` |
| `staging-local` | rehearse Argo CD + SOPS on a local cluster | `gitops-deploy-staging` |
| `staging` | canonical pre-production path | digest promotion plus Argo CD reconciliation |

You can think of the ladder this way:

- Local proves your code can run.
- `dev` proves your manifests can run in Kubernetes.
- `staging-local` proves the staged architecture can run on your local cluster.
- `staging` proves the same architecture can consume trusted release artifacts by digest.

## The final architecture in plain language

- Helm owns reusable packages.
- Kustomize owns environment adaptation.
- Argo CD owns continuous reconciliation for staged environments.
- SOPS plus age plus KSOPS own encrypted secret rendering.
- Kyverno owns rendered-manifest policy checks.
- Istio owns staged mesh traffic.
- Prometheus owns staged monitoring.

If you remember only one rule, remember this one: do not move environment-specific
logic into Helm when Kustomize should own it, and do not move reusable platform
packaging into Kustomize when Helm should own it.

## Important boundaries

- `dev` is a local k3s lab, not the canonical staging path.
- `staging-local` exists to learn and validate the topology locally without weakening canonical `staging`.
- `staging` should consume registry images by digest, not local dev images.
- Helm owns reusable bases and shared chart configuration under `platform/helm/`.
- Kustomize owns environment overlays, KSOPS/SOPS secrets, and environment adaptation under `platform/k8s/overlays/`.
- Atlas workloads stay in the workload Argo CD boundary, while Istio and Prometheus live in the infra boundary.
- The platform-infra bundle currently includes Istio plus a minimal Prometheus stack in the dedicated `monitoring` namespace.
- Istio now owns the staged mesh path for `staging-local` and `staging`, while `dev` intentionally stays on Traefik.
- Prometheus now owns the first monitoring slice, while workload scrape intent stays in workload-owned `ServiceMonitor` objects.
- Kubernetes knowledge matters most from `dev` onward; Compose is intentionally a simpler first step.
- Production is intentionally outside the repo's current operational scope.

## Choose the right next page

| If you need to understand... | Read this |
| --- | --- |
| the fastest local full-stack loop | [Local Compose](local-compose.md) |
| local Kubernetes without GitOps | [k3s dev environment](k3s-dev.md) |
| how Argo CD, SOPS, and KSOPS are bootstrapped | [GitOps bootstrap](gitops-bootstrap.md) |
| why staged traffic uses Istio | [Service mesh](service-mesh.md) |
| how metrics are scraped and where Prometheus lives | [Monitoring](monitoring.md) |
| why `staging-local` and canonical `staging` are different | [Staging-local](staging-local.md) and [Canonical staging](canonical-staging.md) |
| how released images reach staging | [Release workflow](release-workflow.md) and [Staging promotion](staging-promotion.md) |

## Where the deep detail lives

- [Deployment runbooks index](../deployment/README.md)
- [k3s runbook](../deployment/k3s/RUNBOOK.md)
- [GitOps runbook](../deployment/gitops/ARGOCD_SOPS_RUNBOOK.md)
- [Image promotion runbook](../deployment/releases/IMAGE_PROMOTION.md)
