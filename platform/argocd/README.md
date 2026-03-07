# Argo CD Layout

- `core/`: installs Argo CD itself, AppProject, and KSOPS plugin integration.
- `apps/`: Argo CD `Application` resources for repository overlays.

The repository uses Argo CD + KSOPS + SOPS(age) so encrypted Kubernetes secrets can stay in git while decryption happens inside the repo-server during sync.

The committed `Application` manifests track `main` by default. For local validation on an unmerged branch, use `ARGOCD_APP_REVISION=<remote-branch-or-commit> mise run gitops-apply-apps` after pushing the branch.
