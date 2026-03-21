# Release Workflow

Atlas Platform builds release images from `main` and treats those images as the
source material for canonical staging.

This page explains the release side of the delivery story. Read it after you
understand GitOps and the staging environments.

## Principles

- build each image once per commit on `main`,
- publish immutable OCI images to GHCR,
- scan and sign what gets published,
- promote staging by digest, never by mutable tag.

## Main remote workflow

The `Release Images` GitHub Actions workflow:

1. waits for CI success on `main` or runs manually,
2. builds `atlas-inventory-service` and `atlas-web`,
3. pushes `:main` and `:${GITHUB_SHA}` tags,
4. scans the images,
5. generates SBOMs,
6. signs images and attaches attestations,
7. reports the published digests.

Tooling behind those steps:

- GitHub Actions runs the automation.
- Docker Buildx builds and pushes the OCI images.
- Trivy scans the published images for high and critical vulnerabilities.
- Syft generates SBOM files that describe what is inside each image.
- Cosign signs the image digests and attaches the SBOM attestations.

Expected result: you get backend and frontend digests that canonical `staging` can
trust and promote.

## Why digests matter

- tags can move,
- digests are immutable,
- staging should point at an exact released artifact,
- migration jobs and backend deployments must stay aligned to the same backend digest.

## How release and GitOps connect

- The release workflow produces trusted images.
- The promotion workflow updates Git to point at those exact digests.
- Argo CD then reconciles that Git state into canonical `staging`.

Release does not deploy by itself. It creates the artifacts that GitOps later uses.

## Local preparation commands

- `mise run k8s-validate-overlays`
- `mise run gitops-render-staging`

Use these before or during promotion-related work to prove the manifests still render and pass policy checks.

## Read next

- [Staging promotion](staging-promotion.md)
- [Image promotion runbook](../deployment/releases/IMAGE_PROMOTION.md)
