# Learning Path

This page gives a zero-knowledge reader a safe order for learning the repo.

## Phase 1: Orient yourself

Read these first:

1. [What is Atlas Platform?](what-is-atlas-platform.md)
2. [First-day setup](quickstart.md)
3. [Repository tour](repository-map.md)
4. [Glossary](../reference/glossary.md)

Outcome: you know what the repo is, what environments exist, and where code and
platform assets live.

Main tools you should recognize by name after this phase: `mise`, `uv`, `npm`,
Docker, Docker Compose, FastAPI, Vite, PostgreSQL, Kubernetes, k3s, and Argo CD.

## Phase 2: Learn the daily workflow

Read these next:

1. [Daily workflow and change lifecycle](../development/END_TO_END_WORKFLOW.md)
2. [Local development](../development/local-development.md)
3. [Quality and CI](../development/quality-and-ci.md)
4. [Command reference](../reference/commands.md)

Outcome: you can bootstrap, code, validate, and prepare a pull request.

Main tools you should understand after this phase: `pre-commit`, `ruff`,
`pyright`, `pytest`, `gitleaks`, `detect-secrets`, GitHub Actions, Dependabot,
and dependency review.

## Phase 3: Learn the application surfaces

Choose the area you will touch:

- [Backend development](../development/backend-development.md)
- [Database and migrations](../development/database-migrations.md)
- [Frontend development](../development/frontend-development.md)
- [Docs workflow](../development/docs-workflow.md)

Outcome: you understand the local loop for your part of the repo.

Tooling emphasis:

- Backend: FastAPI, PostgreSQL, Alembic, `uv`, `pytest`, `pyright`.
- Frontend: React, Vite, `npm`, TypeScript.
- Docs: MkDocs Material via `mise run docs-build`.

## Phase 4: Learn the platform journey

Move here when local application work is not enough:

1. [Operations overview](../operations/overview.md)
2. [Local Compose](../operations/local-compose.md)
3. [k3s dev environment](../operations/k3s-dev.md)
4. [GitOps bootstrap](../operations/gitops-bootstrap.md)
5. [Staging-local](../operations/staging-local.md)
6. [Canonical staging](../operations/canonical-staging.md)
7. [Backup and restore](../operations/backup-restore.md)
8. [Release workflow](../operations/release-workflow.md)
9. [Staging promotion](../operations/staging-promotion.md)

Outcome: you understand how a change moves from local work into Kubernetes and
the GitOps-driven staging model.

Main tools you should understand after this phase: `kubectl`, k3s, Kustomize,
Argo CD, GitOps, SOPS, age, KSOPS, Kyverno, Trivy, Cosign, and Syft or SBOM
generation.

## Phase 5: Keep the deep references nearby

Use these when you need exact operational detail instead of onboarding context:

- [k3s runbook](../deployment/k3s/RUNBOOK.md)
- [GitOps runbook](../deployment/gitops/ARGOCD_SOPS_RUNBOOK.md)
- [Image promotion runbook](../deployment/releases/IMAGE_PROMOTION.md)
- [Configuration reference](../reference/configuration.md)
- [Troubleshooting](../reference/troubleshooting.md)
