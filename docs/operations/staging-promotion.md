# Staging Promotion

Staging promotion is the process of updating canonical `staging` to use specific
published image digests. It is the bridge between the release workflow and the
real staged environment.

If you remember one sentence, remember this one: promotion changes Git to point
at trusted digests, and Argo CD deploys that Git change only after the promotion
PR is reviewed and merged.

## What promotion is for

- move canonical `staging` from placeholder or old digests to a specific release,
- keep Git as the source of truth for the promoted image set,
- verify those digests are trusted before Argo CD is asked to deploy them,
- create a reviewable pull request instead of silently changing the environment.

## Main owners in this repo

| Piece | Owner in this repo | Source of truth |
| --- | --- | --- |
| digest rewrite logic | release helper scripts | `scripts/release/promote-by-digest.sh` |
| trust verification logic | release trust helper | `scripts/release/verify-trusted-images.sh` |
| promotion automation | GitHub Actions workflow | `.github/workflows/promote-staging.yml` |
| canonical staging image targets | staging image component | `platform/k8s/components/images/staging/kustomization.yaml` |

## Inputs you need

- a backend digest from the release workflow,
- a frontend digest from the release workflow,
- a branch or commit containing the desired staging manifest state,
- access to the SOPS key if canonical overlay validation must decrypt secrets.

## Local helper

```bash
./scripts/release/promote-by-digest.sh staging sha256:<inventory> sha256:<web>
```

## What the helper actually does

`scripts/release/promote-by-digest.sh`:

1. validates that the environment is `staging`,
2. validates both digests look like `sha256:...`,
3. rewrites `platform/k8s/components/images/staging/kustomization.yaml`,
4. uses `ATLAS_REGISTRY_OWNER` when building the GHCR image names,
5. immediately runs `scripts/release/verify-trusted-images.sh` against the result.

That last step matters: digest rewrite and trust verification are intentionally
coupled, so canonical staging does not drift toward unverified images.

## What the GitHub Actions promotion workflow does

The `Promote Staging` workflow in `.github/workflows/promote-staging.yml`:

1. accepts backend and web digests as workflow inputs,
2. rewrites the canonical staging image component,
3. requires `SOPS_AGE_KEY` and materializes it into `.gitops-local/age/keys.txt`,
4. runs `scripts/gitops/validate-overlays.sh`,
5. creates or updates a promotion branch,
6. commits the digest rewrite if there is a real change,
7. pushes the branch,
8. creates or updates the promotion pull request.

## Why promotion happens through Git instead of direct cluster edits

- canonical `staging` is GitOps-managed,
- Argo CD will reconcile back to Git anyway,
- a PR leaves a review trail,
- the exact promoted digests become part of the repository history,
- trust verification happens before the cluster is asked to consume the images.

## Important rules

- never promote mutable tags into canonical `staging`,
- keep backend deployment and migration job on the same digest,
- treat `staging-local` as rehearsal, not proof of digest promotion,
- do not treat a successful rewrite as sufficient; overlay validation and later runtime verification still matter.

## What happens after promotion

1. the promotion pull request is reviewed,
2. the change is merged,
3. Argo CD notices the new Git state,
4. canonical `staging` reconciles the promoted digests,
5. operators verify sync status, health, mesh traffic, and monitoring.

## Related variables you will see

| Variable | What it affects |
| --- | --- |
| `ATLAS_REGISTRY_OWNER` | which GHCR namespace the rewrite and trust scripts target |
| `SOPS_AGE_KEY` | whether encrypted canonical overlays can be validated in automation |
| `ATLAS_GITHUB_REPOSITORY` | which repository Cosign trust verification expects |
| `ATLAS_TRUST_WORKFLOW_PATH` | which workflow path is allowed to have signed the images |

## Read next

- If you need the artifact-production side first, read [Release workflow](release-workflow.md) next.
- If you need the environment that consumes the promoted digests, read [Canonical staging](canonical-staging.md) next.
- If you need the exact variables that shape trust and promotion, read [Configuration and environment variables](../reference/configuration.md) next.
- If promotion or trust verification is failing, read [Troubleshooting](../reference/troubleshooting.md) next.
- If you need the deepest operator detail, read the [Image promotion runbook](../deployment/releases/IMAGE_PROMOTION.md) next.
