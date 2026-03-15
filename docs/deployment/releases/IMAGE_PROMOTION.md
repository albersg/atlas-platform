# Image Promotion Runbook

Use this runbook when you need to move canonical `staging` to exact released image
digests. This is the deep reference for the release-image trust model, digest
selection, local preflight validation, and the promotion mechanics that rewrite the
staging image component.

If you are still learning the release flow, read these pages first:

- [Release workflow](../../operations/release-workflow.md)
- [Staging promotion](../../operations/staging-promotion.md)
- [Canonical staging](../../operations/canonical-staging.md)

## Core rules

- Build each image once per commit on `main`.
- Publish immutable OCI images to GHCR.
- Promote canonical `staging` by digest, never by mutable tag.
- Trust only digests signed by the repository `Release Images` workflow on `main`.
- Keep the backend deployment and migration job on the same backend digest.

These rules exist so staging always points at an exact, auditable artifact instead
of a moving tag.

## Prerequisites

Before you promote, make sure you have:

- the backend and frontend digests produced by the `Release Images` workflow,
- access to the repo branch where the promotion change will be made,
- the `SOPS_AGE_KEY` needed for encrypted overlay validation,
- a clear understanding of the difference between `staging-local` and canonical
  `staging`.

If you only tested `staging-local`, you have not yet proven the canonical staging
path. `staging-local` is a rehearsal environment. Promotion targets canonical
`staging` only.

## Understand the release workflow first

The `Release Images` GitHub Actions workflow is the source of truth for trusted
release artifacts.

### What the workflow does

1. waits for `CI` success on `main` or runs manually,
2. builds `atlas-inventory-service` and `atlas-web`,
3. pushes both `:main` and `:${GITHUB_SHA}` tags to GHCR,
4. scans the published images with Trivy,
5. generates SPDX SBOMs,
6. signs the image digests and attaches SBOM attestations with Cosign,
7. prints the published digests in the workflow summary.

### What those steps mean conceptually

- GitHub Actions runs the release automation in a controlled pipeline.
- GHCR stores the immutable artifacts that staging should consume.
- Trivy checks for serious vulnerabilities before the artifacts are trusted.
- Syft produces SBOMs so you can inspect what is inside the images.
- Cosign ties trust to the repository's `Release Images` workflow identity.

Success looks like: you have exact `sha256:...` digests for backend and frontend,
and those digests were produced by the trusted release workflow on `main`.

## Promotion workflow

The promotion path updates canonical `staging` to point at those exact digests.

### What the promotion automation does

1. rewrites `platform/k8s/components/images/staging/kustomization.yaml`,
2. verifies Cosign trust for the target digests against
   `.github/workflows/release-images.yml@refs/heads/main`,
3. requires `SOPS_AGE_KEY` and validates `dev`, `staging`, and `staging-local`,
   while applying staging-only hardening checks only to canonical `staging`,
4. reuses an existing promotion branch when possible,
5. opens or updates a pull request against `main`.

Why this matters: promotion is not just an edit to image refs. It is also a trust,
render, and policy checkpoint.

## Step-by-step local preflight

Use these commands before or during a manual promotion workflow.

### Step 1: Render the canonical staging overlay

```bash
mise run gitops-render-staging >/dev/null
```

What it does conceptually: proves Kustomize plus KSOPS can build the staging
manifests with the current encrypted configuration.

Success looks like: the render completes without decryption or Kustomize errors.

### Step 2: Validate overlays and policy rules

```bash
mise run k8s-validate-overlays
```

What it does conceptually: runs the repo's policy checks across all non-production
overlays and enforces immutable-image and trusted-signature rules only where they
belong: canonical `staging`.

Success looks like: the validator finishes without policy failures, digest trust
errors, or missing `SOPS_AGE_KEY` problems.

## Step-by-step promotion helper

Use the local helper when you want to prepare or verify the promotion change from
your workstation.

```bash
./scripts/release/promote-by-digest.sh staging sha256:<inventory> sha256:<web>
```

What it does conceptually:

1. updates the staging image component to the supplied digests,
2. verifies those digests with Cosign under the repo's trusted GitHub Actions
   identity,
3. leaves you with the digest-pinned staging manifest state ready for PR review.

Success looks like: the script exits cleanly and the only intended manifest changes
are the canonical staging image refs.

## After the promotion change exists

Next, follow the usual review and verification path:

1. confirm the promotion diff only changes the intended staging image refs,
2. verify the PR passes the repository validation,
3. merge the promotion change into `main`,
4. let Argo CD reconcile canonical `staging`,
5. verify staging health with status, smoke checks, and hostname access.

Use these pages for the post-promotion steps:

- [Canonical staging](../../operations/canonical-staging.md)
- [k3s runbook](../k3s/RUNBOOK.md)

## Common mistakes to avoid

- Do not promote mutable tags into canonical `staging`.
- Do not treat `staging-local` success as proof of digest promotion.
- Do not promote a backend digest without keeping the migration job on the same
  digest.
- Do not skip signature verification or encrypted-overlay validation.

## What success looks like overall

You can:

- identify the correct digests from the trusted release workflow,
- explain why digest promotion is safer than tag promotion,
- validate the encrypted staging overlay locally,
- update canonical staging image refs without weakening the trust model,
- hand off a promotion change that Argo CD can reconcile cleanly.

## Read next

- [Canonical staging](../../operations/canonical-staging.md)
- [Staging promotion](../../operations/staging-promotion.md)
- [Troubleshooting](../../reference/troubleshooting.md)
