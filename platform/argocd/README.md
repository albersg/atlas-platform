# Argo CD Layout

- `core/`: installs Argo CD itself and the KSOPS/SOPS integration.
- `apps/`: staging GitOps bundle.

The repository keeps encrypted Kubernetes secrets in git for GitOps rendering via KSOPS. The local/non-production bootstrap applies only `platform/argocd/apps`.

For local branch validation on a pushed branch, use:

```bash
ARGOCD_APP_REVISION=<remote-branch-or-commit> mise run gitops-apply-apps
```

To wait for the staging application and run namespace smoke checks after sync:

```bash
ARGOCD_APP_REVISION=<remote-branch-or-commit> mise run gitops-deploy-staging
```

Production is intentionally outside the current operational scope of this repository.
