# Image Promotion

## Principles

- Build each image once per commit on `main`.
- Publish immutable OCI images to GHCR.
- Promote `staging` by digest, never by mutable tags.
- Keep the backend deployment and migration job on the same digest.

## Release workflow

`Release Images`:

1. waits for `CI` success on `main` (or can be triggered manually),
2. builds `atlas-inventory-service` and `atlas-web`,
3. pushes `:main` and `:${GITHUB_SHA}` tags to GHCR,
4. scans the published images with Trivy,
5. generates SPDX SBOMs,
6. signs images and attaches SBOM attestations with Cosign,
7. prints the published digests in the workflow summary.

## Promotion workflow

Use the published digests as inputs for:

- `Promote Staging`

The current promotion workflow:

1. rewrites `platform/k8s/components/images/staging/kustomization.yaml`,
2. requires `SOPS_AGE_KEY` and validates `dev` + `staging` overlays and policies,
3. reuses an existing promotion branch when possible,
4. opens or updates a pull request against `main`.

## Local promotion helper

```bash
./scripts/release/promote-by-digest.sh staging sha256:<inventory> sha256:<web>
```

## Validation

```bash
mise run gitops-render-staging >/dev/null
```

`staging` is registry-backed. Do not point it at local dev images.

Production promotion is intentionally deferred until the project has separate production infrastructure.
