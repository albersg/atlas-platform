# Release Workflow

Atlas Platform builds release images from `main` and treats those images as the
source material for canonical staging. Release does not deploy by itself. It
produces trusted artifacts that the promotion and GitOps flows can later use.

## What release is for in this repo

- publish immutable OCI images to GHCR,
- prove those images pass vulnerability scanning,
- generate SBOMs,
- sign the resulting digests,
- feed canonical staging with artifacts that are safe to trust by digest.

## What release is not

- It is not a direct deployment step.
- It is not the same thing as staging promotion.
- It is not exposed as a day-to-day `mise run ...` task; in this repo release is a GitHub Actions workflow, not a local operator command.

That distinction matters because beginners often expect "release" to mean
"deploy now." Here it means "produce trusted artifacts that later workflows may
promote and deploy."

## Who owns the release flow

| Piece | Owner in this repo | Source of truth |
| --- | --- | --- |
| image build and publish automation | GitHub Actions release workflow | `.github/workflows/release-images.yml` |
| trusted-image verification rules | release trust script | `scripts/release/verify-trusted-images.sh` |
| digest rewrite for staging promotion | promotion helper | `scripts/release/promote-by-digest.sh` |
| canonical staging image targets | staging image component | `platform/k8s/components/images/staging/kustomization.yaml` |

## What happens under the hood

The `Release Images` workflow in `.github/workflows/release-images.yml`:

1. triggers after successful `CI` runs on `main`, or manually,
2. checks out the exact source commit that is being released,
3. logs in to GHCR,
4. enables Docker Buildx,
5. builds and pushes `atlas-inventory-service`,
6. builds and pushes `atlas-web`,
7. records the published image digests,
8. scans the published images with Trivy,
9. installs Syft and Cosign,
10. generates SPDX SBOMs,
11. signs the image digests and attaches SBOM attestations,
12. publishes the digests in the workflow summary.

## The tools behind each step

| Tool | What it does here | Where it is configured |
| --- | --- | --- |
| GitHub Actions | orchestrates the release pipeline | `.github/workflows/release-images.yml` |
| Docker Buildx | builds and pushes OCI images | same workflow |
| GHCR | stores release images | image refs in the workflow env block |
| Trivy | fails release on high or critical image vulnerabilities | same workflow |
| Syft | generates SBOM JSON for each image | same workflow |
| Cosign | signs the published digests and attaches SBOM attestations | same workflow |

## Why digests matter more than tags

- tags such as `:main` are useful for rehearsal and convenience,
- digests are immutable and point to one exact published artifact,
- canonical `staging` is meant to verify a real release candidate,
- migration jobs and backend deployments must stay aligned to the same backend digest.

That is why the canonical staging path promotes `sha256:...` references rather
than trusting moving tags.

## How release composes with promotion and GitOps

Release is one stage in a larger chain:

1. local and CI validation prove the source and manifests are sound,
2. release builds, scans, signs, and publishes the images,
3. promotion rewrites Git to use those exact digests,
4. Argo CD reconciles the Git change into canonical `staging`,
5. canonical staging verifies runtime health, mesh routing, and monitoring.

If you skip any link, the system loses some of its trust story.

## Local commands that support release-oriented work

| Command | Why it matters before promotion |
| --- | --- |
| `mise run k8s-validate-overlays` | proves manifests, policies, trust rules, and mesh validation still pass |
| `mise run gitops-render-staging` | shows the canonical workload overlay still renders locally |
| `mise run gitops-render-platform-infra-staging` | shows the staged infra wrapper charts still render cleanly |

## Troubleshooting mindset for release failures

- If buildx fails, treat it as an image build or Dockerfile problem.
- If Trivy fails, treat it as a release-security problem, not just a CI inconvenience.
- If Syft or Cosign fails, treat it as a supply-chain trust problem.
- If later promotion fails verification, the release artifact may exist but still not satisfy the canonical staging trust contract.

## Read next

- [Staging promotion](staging-promotion.md)
- [Canonical staging](canonical-staging.md)
- [Configuration and environment variables](../reference/configuration.md)
- [Troubleshooting](../reference/troubleshooting.md)
- [Image promotion runbook](../deployment/releases/IMAGE_PROMOTION.md)
