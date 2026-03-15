# GitOps Runbook: Argo CD, KSOPS, and SOPS

Use this runbook when you need the full operator workflow for bootstrapping or
operating the repository's GitOps path. It covers Argo CD installation, SOPS and
age key handling, repo credentials, local branch validation, and the boundary
between `staging-local` and canonical `staging`.

If you are still learning the flow, read these pages first:

- [Operations overview](../../operations/overview.md)
- [GitOps bootstrap](../../operations/gitops-bootstrap.md)
- [Staging-local](../../operations/staging-local.md)
- [Canonical staging](../../operations/canonical-staging.md)

## Environment model

| Environment | What GitOps means there | Image source |
| --- | --- | --- |
| `dev` | GitOps is not the primary control loop. Helpers render and apply directly. | Local build-specific images. |
| `staging-local` | Argo CD runs the staging topology on your local cluster. | Local `:main` image refs imported into k3s. |
| Canonical `staging` | Argo CD reconciles the real pre-production contract. | Registry images pinned by digest. |

When people confuse the environments, it is usually because the command name is
the same: `mise run gitops-deploy-staging`. On local k3s that command defaults to
the `staging-local` wrapper. Set `STAGING_LOCAL_IMAGES=0` to force the canonical
staging behavior.

## Architecture and files involved

- `platform/argocd/core/` installs Argo CD and the KSOPS integration.
- `platform/argocd/apps/` defines the application bundle for non-production.
- `platform/k8s/overlays/*/secrets/*.enc.yaml` stores encrypted secrets.
- `.sops.yaml` defines how the repo encrypts and decrypts those files.
- `.gitops-local/` stores ignored local bootstrap material such as age keys and
  repo SSH credentials.

## Prerequisites

Before you start, make sure you have:

- `mise`, `kubectl`, and the cluster access required to install Argo CD.
- A local or target cluster already running.
- Access to the repository you want Argo CD to reconcile.
- Permission to generate or install the age key used for SOPS decryption.
- Permission to create the deploy key or other repository credential Argo CD will
  use.

Run this command first on a new workstation if you are unsure which helper tools
are already present:

```bash
mise run gitops-install-tools
```

What it does conceptually: installs the local binaries and helper dependencies the
GitOps scripts rely on.

Success looks like: the install step finishes cleanly and later GitOps scripts no
longer fail because of missing local tooling.

## Step-by-step bootstrap

Use this order for a first-time non-production bootstrap.

### Step 1: Generate the local age key

```bash
./scripts/gitops/bootstrap/generate-age-key.sh
```

What it does conceptually: creates the local age keypair that SOPS uses to decrypt
the repository's encrypted secret manifests.

Success looks like: the key material exists under `.gitops-local/age/` and is not
tracked by Git.

### Step 2: Install Argo CD core and KSOPS

```bash
mise run gitops-bootstrap-core
```

What it does conceptually: installs Argo CD core and the KSOPS plugin so the
cluster can reconcile Kustomize overlays that include SOPS-encrypted files.

Success looks like: the `argocd` namespace and the core Argo CD workloads are
healthy.

### Step 3: Generate the repository deploy key

```bash
./scripts/gitops/bootstrap/generate-repo-deploy-key.sh
```

What it does conceptually: creates the SSH keypair Argo CD will use to read the
repository over Git.

Success looks like: the private key exists under `.gitops-local/ssh/` and the
public key is ready to register with GitHub.

### Step 4: Install the age key into Argo CD

```bash
mise run gitops-install-age-key
```

What it does conceptually: creates or updates the `argocd-sops-age-key` secret so
KSOPS can decrypt the encrypted manifests inside the cluster.

Success looks like: the command completes without secret-creation errors and
subsequent render steps can decrypt secrets.

### Step 5: Install the repository credential

```bash
mise run gitops-install-repo-credential
```

What it does conceptually: installs the repository credential secret that lets Argo
CD clone the repo.

Important defaults:

- the default repo URL is `git@github.com:albersg/atlas-platform.git`,
- the default secret name is `argocd-repo-atlas-platform`.

Only override `GITOPS_REPO_URL` or `ARGOCD_REPO_SECRET_NAME` if you intentionally
need a different repository target.

Success looks like: Argo CD can access the repo without authentication failures.

### Step 6: Apply the non-production applications

```bash
mise run gitops-apply-apps
```

What it does conceptually: creates the non-production application bundle,
including `atlas-platform-staging`.

Success looks like: the staging application exists in Argo CD and points at the
expected repo and revision.

## Validate before sync

Run these commands before you ask Argo CD to reconcile a branch or a new digest:

```bash
mise run gitops-render-dev >/dev/null
mise run gitops-render-staging >/dev/null
mise run k8s-validate-overlays
```

What they do conceptually:

- the render commands prove Kustomize plus KSOPS can build the target manifests,
- `mise run k8s-validate-overlays` enforces the repo's policy rules across `dev`,
  `staging`, and `staging-local`,
- immutable image and signature rules only apply to canonical `staging`.

Success looks like: rendering succeeds and the validator does not report policy or
signature failures.

## Sync a branch or revision locally

### Rehearse the staging topology on local k3s

```bash
ARGOCD_APP_REVISION=<remote-branch-or-commit> mise run gitops-deploy-staging
```

What it does conceptually on local k3s:

1. builds or reuses local `:main` image refs,
2. imports them into k3s,
3. points the application at `platform/k8s/overlays/staging-local`,
4. waits for reconciliation,
5. runs smoke checks.

Success looks like: `atlas-platform-staging` reaches synced and healthy state on
the local wrapper overlay.

### Force canonical staging behavior

```bash
STAGING_LOCAL_IMAGES=0 \
ARGOCD_APP_REVISION=<remote-branch-or-commit> \
mise run gitops-deploy-staging
```

What it does conceptually: disables the local-image wrapper and tells Argo CD to
reconcile the real `platform/k8s/overlays/staging` path instead.

Use this only when the required registry images already exist and you want the real
digest-driven staging contract.

Success looks like: the application syncs the canonical overlay, not the local
wrapper, and the environment stays healthy under staging-only policy rules.

## Inspect and access Argo CD locally

### Log in

```bash
./scripts/gitops/argocd/login-local.sh
```

What it does conceptually: opens the local access path for Argo CD and authenticates
your CLI or browser session.

### Get the initial password

```bash
./scripts/gitops/argocd/get-initial-password.sh
```

Use this when you need the bootstrap admin password for the local Argo CD install.

Success looks like: you can reach the Argo CD UI or CLI and inspect the
`atlas-platform-staging` application directly.

## Sync policy and teardown

- `atlas-platform-staging` is configured for auto-sync, prune, and self-heal.
- This is why direct manual cluster edits are not the long-term source of truth for
  staging.

Before you destroy staging, use the GitOps-aware teardown:

```bash
ATLAS_CONFIRM_STAGING_DELETE=atlas-platform-staging mise run k8s-delete-staging
```

What it does conceptually:

1. removes the Argo CD application without cascading first,
2. prevents self-heal from recreating resources while cleanup runs,
3. preserves the namespace and PVC by default unless
   `PRESERVE_POSTGRES_PVC=0` is set.

Success looks like: the application is gone and the remaining resources match your
chosen teardown scope.

## SOPS key rotation

If you rotate the age keypair, do this in order:

1. update `.sops.yaml`,
2. re-encrypt `platform/k8s/overlays/*/secrets/*.enc.yaml`,
3. update `argocd-sops-age-key` in the target cluster,
4. rerun local render validation,
5. resync Argo CD.

What success looks like: encrypted secrets still render locally and Argo CD resumes
normal reconciliation without decryption failures.

## Security rules for this workflow

- Never commit `.gitops-local/age/keys.txt`.
- Never commit `.gitops-local/ssh/argocd-repo`.
- Treat the `argocd` namespace as sensitive operational space.
- Keep `dev`, `staging-local`, and canonical `staging` conceptually separate.
- Provide `SOPS_AGE_KEY` to CI or promotion workflows that need encrypted overlay
  validation.
- Production remains intentionally outside the repo's current GitOps scope.

## Quick troubleshooting map

### Argo CD cannot clone the repo

- verify the GitHub deploy key is registered,
- rerun `mise run gitops-install-repo-credential`,
- confirm `GITOPS_REPO_URL` still matches the expected repository.

### KSOPS or SOPS decryption fails

- verify the local or in-cluster age key is the correct one,
- rerun `mise run gitops-install-age-key`,
- rerun the local render commands before syncing again.

### The application stays out of sync

- confirm `ARGOCD_APP_REVISION` points to a reachable remote branch or commit,
- run `mise run gitops-wait-staging` after fixing the underlying error,
- inspect the Argo CD UI for the exact resource diff or render failure.

### Policy validation fails for canonical staging

- confirm the target images were published and signed by the trusted release
  workflow,
- switch to the [image promotion runbook](../releases/IMAGE_PROMOTION.md) if the
  problem is digest or signature related.

## What success looks like overall

You can:

- bootstrap Argo CD and encrypted manifest support from scratch,
- explain why `staging-local` and canonical `staging` are different,
- validate renders before sync,
- reconcile the correct overlay for the task,
- rotate keys or tear down staging without bypassing guardrails.

## Read next

- [Image promotion runbook](../releases/IMAGE_PROMOTION.md)
- [k3s runbook](../k3s/RUNBOOK.md)
- [Troubleshooting](../../reference/troubleshooting.md)
