# GitOps Bootstrap

Use this guide when you want a cluster ready for the GitOps-driven staging path.
This is the first page to read when you want to understand how Argo CD, encrypted
secrets, Helm, Kustomize, Istio, and Prometheus work together in this repo.

## Goal

By the end of this guide you should have:

- repo-local GitOps helper tools installed,
- Argo CD core installed,
- the SOPS age key available to Argo CD,
- repository credentials installed,
- the staged application bundle applied,
- a clear picture of how workload overlays and platform-infra apps split ownership,
- a clear understanding of why `staging-local` and canonical `staging` use the
  same GitOps architecture but different image rules.

## Tooling explained in repo terms

| Tool | What it is for | Who owns it in this repo | Where it is configured |
| --- | --- | --- | --- |
| Argo CD | continuously reconciles Git state into the cluster | staging deployment layer | `platform/argocd/apps/**`, `scripts/gitops/bootstrap/*.sh` |
| GitOps | operating model where Git is the desired state | staging operating model | Argo CD app manifests plus overlay/chart sources |
| SOPS | stores encrypted secrets safely in Git | secure overlay layer | encrypted overlay files and `.sops.yaml` |
| age | key format SOPS uses here | secure bootstrap layer | `.gitops-local/age/keys.txt`, bootstrap scripts |
| KSOPS | lets Kustomize and Argo CD decrypt SOPS files while rendering | secure render layer | repo-local plugin path created by `scripts/gitops/bootstrap/install-tools.sh` |
| Kustomize | assembles workload overlays, secrets, and workload-owned monitoring resources | workload env layer | `platform/k8s/**` |
| Helm | renders reusable workload and platform-infra chart layers | platform packaging layer | `platform/helm/**`, `scripts/gitops/render-platform-infra.sh` |
| Istio | staged mesh and ingress infra add-on | platform infra layer | `platform/helm/istio/**`, `platform/k8s/components/mesh/istio/**` |
| Prometheus | staged monitoring infra add-on | infra plus workload observability split | `platform/helm/prometheus/**`, `platform/k8s/components/observability/prometheus/**` |
| Kyverno | validates rendered manifests against repo policy before rollout | platform policy layer | `platform/policy/kyverno/**`, `scripts/gitops/validate-overlays.sh` |

## Architecture contract in this flow

- Helm is the reusable base layer.
- Kustomize is the environment overlay layer.
- Helm owns reusable bases under `platform/helm/`, including staged platform add-ons.
- Kustomize owns environment overlays under `platform/k8s/overlays/`.
- Workload-owned resources, such as the first `inventory-service` `ServiceMonitor`, stay in the workload layer even when they are meant for a shared infra system.
- Argo CD owns continuous reconciliation after bootstrap, but it does not replace the repo-owned render model.
- Do not encode the same environment-specific behavior in both Helm values and Kustomize overlays.

That split matters because it keeps the repo teachable:

- reusable package logic lives in Helm,
- environment-specific composition lives in Kustomize,
- cluster convergence lives in Argo CD,
- policy and trust checks stay outside the cluster mutability path.

## Before you run commands

Make sure you understand these differences:

| Environment | What Argo CD reconciles | Which images it expects | Why it exists |
| --- | --- | --- | --- |
| `staging-local` | local staging wrapper overlay plus staged infra apps | local `:main` refs imported into k3s | rehearse the real architecture locally |
| `staging` | canonical staging overlay plus staged infra apps | registry images pinned by digest | real pre-production verification |

The same deployment family appears in both paths, but image trust and ingress
behavior are different.

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

## What each command really does

### `mise run gitops-install-tools`

- Runs `scripts/gitops/bootstrap/install-tools.sh`.
- Downloads pinned local copies of `age`, `sops`, `argocd`, `kustomize`, `ksops`, `kyverno`, `cosign`, `helm`, and `istioctl` into `.gitops-local/bin`.
- Creates the repo-local KSOPS plugin path so encrypted overlay rendering works consistently.
- Exists because the repo wants one local source of truth for GitOps helper versions instead of splitting that responsibility between `mise` and ad-hoc installers.

### `mise run gitops-bootstrap-core`

- Runs `scripts/gitops/bootstrap/install-argocd.sh`.
- Installs Argo CD core and the cluster-side support needed for encrypted manifest rendering.
- Creates the cluster-side half of the GitOps toolchain.

### `mise run gitops-install-age-key`

- Runs `scripts/gitops/bootstrap/install-age-key-secret.sh`.
- Installs the local age private key into `argocd` as `argocd-sops-age-key`.
- Gives Argo CD and KSOPS the same decryption ability your local render commands use.

### `mise run gitops-install-repo-credential`

- Runs `scripts/gitops/bootstrap/install-repo-credential.sh`.
- Installs the repository deploy credential used by Argo CD.
- By default, the repo target is `git@github.com:albersg/atlas-platform.git`.

### `mise run gitops-apply-apps`

- Runs `scripts/gitops/bootstrap/apply-apps.sh`.
- Applies:
  - `project-atlas-platform.yaml`,
  - `project-atlas-platform-infra.yaml`,
  - `atlas-platform-istio-base`,
  - `atlas-platform-istiod`,
  - `atlas-platform-istio-ingress`,
  - `atlas-platform-prometheus`,
  - `atlas-platform-staging`.
- Patches infra apps to use either `values-staging-local.yaml` or `values-staging.yaml`.
- Can patch the workload app path and target revision by using `ARGOCD_APP_PATH` and `ARGOCD_APP_REVISION`.

Expected result: Argo CD now knows both the workload app and the staged platform-infra app set it should reconcile.

## How the pieces compose after bootstrap

Once bootstrap is complete:

1. Argo CD reads app definitions from `platform/argocd/apps/**`.
2. The workload app renders `platform/k8s/overlays/staging-local` or `platform/k8s/overlays/staging`.
3. The infra apps render the wrapper charts under `platform/helm/istio/**` and `platform/helm/prometheus/**`.
4. KSOPS decrypts encrypted overlay inputs using the installed age key.
5. Later validation commands re-render the same surfaces locally with Kyverno, kubeconform, trusted-image verification, and `istioctl analyze`.

That is why bootstrap is not only about "install Argo CD". It establishes the
full contract that later deploy, validation, promotion, and troubleshooting flows depend on.

## Important operational notes

- `staging-local` is the local rehearsal path; canonical `staging` remains digest-driven.
- `mise run gitops-deploy-staging` waits for the full infra app set before the workload app.
- `mise run k8s-doctor` and `mise run k8s-status-staging` surface infra-app health separately from workload-app health.
- `ARGOCD_APP_REVISION=<remote-branch-or-commit>` is the supported way to validate a pushed branch before merge.
- The staged infra wait includes `atlas-platform-istio-base`, `atlas-platform-istiod`, `atlas-platform-istio-ingress`, and `atlas-platform-prometheus` before the Atlas workload app.
- Do not commit `.gitops-local/age/keys.txt` or `.gitops-local/ssh/argocd-repo`.

## Read next

- If you want to rehearse the topology locally, read [Staging-local](staging-local.md) next.
- If you want the stricter digest-driven path, read [Canonical staging](canonical-staging.md) next.
- If you want to understand staged traffic and ingress, read [Service mesh](service-mesh.md) next.
- If you want to understand staged observability, read [Monitoring](monitoring.md) next.
- If bootstrap is failing and you need deeper operator detail, read the [GitOps runbook](../deployment/gitops/ARGOCD_SOPS_RUNBOOK.md) next.
