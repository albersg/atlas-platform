# GitOps Bootstrap

Use this guide when you want a local cluster ready for the GitOps-driven staging path.

## Goal

By the end of this guide you should have:

- Argo CD core installed,
- the SOPS age key available to Argo CD,
- repository credentials installed,
- the staging application bundle applied.

## Tooling explained

| Tool | Why it exists in this flow |
| --- | --- |
| Argo CD | watches this repo and reconciles Kubernetes resources into the cluster |
| GitOps | means the Git repository is the desired state, not ad-hoc `kubectl apply` commands |
| SOPS | keeps secret manifests encrypted in Git |
| age | provides the encryption keys used by SOPS in this repo |
| KSOPS | lets Kustomize decrypt SOPS-managed files during manifest rendering |
| Kustomize | assembles the base resources and overlays before Argo CD applies them |
| Helm | renders the pinned Istio platform wrapper charts before sync |
| Istio | supplies the upstream base, control plane, and ingress charts |
| Kyverno | validates rendered manifests against repository policy rules before promotion |

## Recommended order

```bash
mise run gitops-install-tools
./scripts/gitops/bootstrap/generate-age-key.sh
mise run gitops-bootstrap-core
./scripts/gitops/bootstrap/generate-repo-deploy-key.sh
mise run gitops-install-age-key
mise run gitops-install-repo-credential
mise run gitops-apply-apps
```

## What the key commands do

### `mise run gitops-install-tools`

- installs local helper binaries used by the GitOps scripts,
- should be run before any bootstrap work on a new machine.

### `mise run gitops-bootstrap-core`

- installs Argo CD core and the KSOPS plugin into the current cluster,
- prepares the cluster to reconcile encrypted manifests.

### `mise run gitops-install-age-key`

- creates or installs the local SOPS age key into the `argocd` namespace,
- allows KSOPS to decrypt repository secrets during render.

### `mise run gitops-install-repo-credential`

- installs the Argo CD repository credential,
- by default targets `git@github.com:albersg/atlas-platform.git`.

### `mise run gitops-apply-apps`

- applies the non-production Argo CD application bundle,
- creates the `atlas-platform-infra` project plus the Istio applications and the `atlas-platform-staging` application,
- patches the Istio applications to `values-staging-local.yaml` or `values-staging.yaml` based on the target rollout mode.

## Important notes

- `staging-local` is the local rehearsal path; canonical `staging` remains digest-driven.
- `mise run gitops-deploy-staging` now waits for `atlas-platform-istio-base`, `atlas-platform-istiod`, and `atlas-platform-istio-ingress` before the Atlas workload app.
- `mise run k8s-doctor` and `mise run k8s-status-staging` now surface infra-app health separately from workload-app health.
- Do not commit `.gitops-local/age/keys.txt` or `.gitops-local/ssh/argocd-repo`.
- If you want to validate a branch before merge, set `ARGOCD_APP_REVISION=<remote-branch-or-commit>`.
- The repo still uses helper scripts for bootstrap, but once bootstrap is complete Argo CD becomes the system continuously driving cluster state.

## Read next

- [Staging-local](staging-local.md)
- [Canonical staging](canonical-staging.md)
- [Service mesh](service-mesh.md)
- [GitOps runbook](../deployment/gitops/ARGOCD_SOPS_RUNBOOK.md)
