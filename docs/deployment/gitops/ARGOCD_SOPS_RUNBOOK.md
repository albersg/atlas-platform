# Argo CD + SOPS Runbook

This repository supports GitOps deployment with:

- Argo CD
- Kustomize overlays
- KSOPS plugin for Kustomize
- SOPS with age-encrypted Kubernetes secrets stored in git

## Architecture

- `platform/argocd/core/`: Argo CD installation, AppProject, and repo-server KSOPS integration.
- `platform/argocd/apps/`: Argo CD Applications for `dev` and `prod`.
- `platform/k8s/overlays/*/secrets/*.enc.yaml`: encrypted secrets committed to git.
- `.sops.yaml`: repository encryption policy with the age public key recipient.
- `.gitops-local/age/keys.txt` (ignored): local private key used to encrypt/decrypt and bootstrap Argo CD.
- `.gitops-local/ssh/argocd-repo` (ignored): read-only deploy key for Argo CD to clone the private repository.

## Secret model

- Secrets are encrypted with the age public key from `.sops.yaml`.
- The matching private key is **not** stored in git.
- Argo CD decrypts secrets at sync time using a Kubernetes secret named `argocd-sops-age-key`.

## Bootstrap flow

### 1. Install local helper binaries

```bash
mise run gitops-install-tools
```

### 2. Generate the local age key (one-time)

```bash
./scripts/gitops/bootstrap/generate-age-key.sh
```

This creates:

- `.gitops-local/age/keys.txt` (ignored by git)

### 3. Install Argo CD core

```bash
mise run gitops-bootstrap-core
```

### 4. Generate the GitHub deploy key for Argo CD

```bash
./scripts/gitops/bootstrap/generate-repo-deploy-key.sh
```

Add the printed public key to GitHub:

- `Repository -> Settings -> Deploy keys -> Add deploy key`
- mark it as **read-only**

### 5. Install the repository credential into Argo CD

```bash
./scripts/gitops/bootstrap/install-repo-credential.sh
```

### 6. Install the age private key into Argo CD

```bash
mise run gitops-install-age-key
```

This creates `argocd/argocd-sops-age-key` in the cluster.

### 7. Apply Argo CD applications

```bash
mise run gitops-apply-apps
```

For local branch testing before merge, point the Applications at a pushed branch or commit:

```bash
ARGOCD_APP_REVISION=<remote-branch-or-commit> mise run gitops-apply-apps
```

At that point Argo CD can sync the encrypted `dev` and `prod` overlays into their
dedicated namespaces:

- `atlas-platform-dev`
- `atlas-platform-prod`

## Local render validation

Before trusting a sync, validate overlays locally:

```bash
mise run gitops-render-dev >/dev/null
mise run gitops-render-prod >/dev/null
```

## Access Argo CD locally

### Login helper

```bash
./scripts/gitops/argocd/login-local.sh
```

### Initial admin password only

```bash
./scripts/gitops/argocd/get-initial-password.sh
```

After login, inspect:

- `atlas-platform-dev`
- `atlas-platform-prod`

## Sync policy

- `atlas-platform-dev`: automated sync, prune, self-heal.
- `atlas-platform-prod`: manual sync by default.

## Rotation and re-encryption

If you rotate the age key pair:

1. update `.sops.yaml` with the new public key,
2. re-encrypt `platform/k8s/overlays/*/secrets/*.enc.yaml`,
3. update `argocd-sops-age-key` in the cluster,
4. re-run local render validation.

## Security notes

- Do not commit `.gitops-local/age/keys.txt`.
- Do not commit `.gitops-local/ssh/argocd-repo`.
- Treat the Argo CD namespace as sensitive because it contains the decryption key.
- For production, back up the private key in a secure out-of-band system.
