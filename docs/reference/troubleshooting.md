# Troubleshooting

Start with the smallest failing layer. Do not jump straight to k3s or GitOps if
the problem already appears in local validation.

## Setup and tooling

### `mise` is not available

- confirm `mise` is installed and activated in your shell,
- restart the shell,
- rerun `mise install`.

### Git hooks seem broken

- rerun `mise run bootstrap`,
- then rerun `mise run lint`.

## Validation failures

### `fmt-check` fails

- run `mise run fmt`,
- inspect the resulting diff,
- rerun `mise run fmt-check` or `mise run ci`.

### `docs-build` fails

- check for broken links,
- check that new files were added to `mkdocs.yml`,
- check for renamed files that old pages still reference.

### `lint` keeps failing after auto-fixes

- inspect the failing hook rather than rerunning blindly,
- use `MISE_LINT_MAX_TRIES` only when you know hooks are making legitimate sequential edits.

## Backend and database

### Backend cannot connect to PostgreSQL

- confirm `INVENTORY_DATABASE_URL`,
- confirm PostgreSQL is actually running,
- if using Compose, check `mise run compose-logs`.

### Alembic migration fails

- confirm the database is reachable,
- confirm the migration files are present,
- rerun `mise run backend-migrate` after fixing the root cause.

## Compose

### The stack starts but one service stays unhealthy

- run `mise run compose-logs`,
- inspect whether PostgreSQL became healthy first,
- then inspect backend readiness and frontend logs.

## k3s and GitOps

### k3s seems to reuse old images in `dev`

- rerun `mise run k8s-build-images`,
- rerun `mise run k8s-import-images`,
- redeploy with `mise run k8s-deploy-dev`.

### Staging or staging-local does not reconcile

- run `mise run k8s-doctor`,
- confirm Argo CD, the repo credential, and the age key are installed,
- rerun `mise run gitops-wait-staging` after fixing the missing dependency.

### Restore or staging delete refuses to run

- read the required confirmation variable carefully,
- export the exact required token,
- retry only after verifying you really intend the destructive action.

## When to switch to a deeper runbook

- use the [k3s runbook](../deployment/k3s/RUNBOOK.md) for cluster-level operation,
- use the [GitOps runbook](../deployment/gitops/ARGOCD_SOPS_RUNBOOK.md) for Argo CD and SOPS issues,
- use the [Image promotion runbook](../deployment/releases/IMAGE_PROMOTION.md) for digest-promotion issues.
