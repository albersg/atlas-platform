# Staging Promotion

Staging promotion is the process of updating canonical `staging` to use specific
published image digests.

This is the bridge between the release workflow and the real staging environment.

## Inputs you need

- a backend digest from the release workflow,
- a frontend digest from the release workflow,
- a branch or commit that contains the desired staging manifest state,
- access to the SOPS key if the workflow validates encrypted overlays.

## Local helper

```bash
./scripts/release/promote-by-digest.sh staging sha256:<inventory> sha256:<web>
```

## What the promotion path does

- rewrites `platform/k8s/components/images/staging/kustomization.yaml`,
- verifies trusted-image signatures for the target digests,
- validates overlays and staging-only hardening,
- opens or updates the promotion pull request.

Expected result: Git now points canonical `staging` at exact, trusted images.

## Important rules

- never promote mutable tags into canonical `staging`,
- keep backend deployment and migration job on the same digest,
- treat `staging-local` as a learning aid, not as proof of digest promotion.

## What happens after promotion

1. the promotion pull request is reviewed,
2. the change is merged,
3. Argo CD notices the new Git state,
4. canonical `staging` reconciles the promoted digests,
5. operators verify health, traffic, and monitoring.

## Read next

- [Canonical staging](canonical-staging.md)
- [Release workflow](release-workflow.md)
- [Image promotion runbook](../deployment/releases/IMAGE_PROMOTION.md)
