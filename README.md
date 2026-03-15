# Atlas Platform

[![CI](https://github.com/albersg/atlas-platform/actions/workflows/ci.yml/badge.svg)](https://github.com/albersg/atlas-platform/actions/workflows/ci.yml)
[![Security](https://github.com/albersg/atlas-platform/actions/workflows/security.yml/badge.svg)](https://github.com/albersg/atlas-platform/actions/workflows/security.yml)
[![CodeQL](https://github.com/albersg/atlas-platform/actions/workflows/codeql.yml/badge.svg)](https://github.com/albersg/atlas-platform/actions/workflows/codeql.yml)
[![Release Images](https://github.com/albersg/atlas-platform/actions/workflows/release-images.yml/badge.svg)](https://github.com/albersg/atlas-platform/actions/workflows/release-images.yml)

Atlas Platform is an agent-first application and platform monorepo. It keeps the
backend, frontend, documentation, local infrastructure, GitOps assets, and
quality guardrails in one place so a contributor can move from local coding to
pre-production validation with the same set of commands.

## What this repository contains

- `services/inventory-service`: the active FastAPI backend with SQLAlchemy and Alembic.
- `apps/web`: the React + Vite + TypeScript frontend.
- `platform/k8s`: shared manifests, reusable components, and overlays for non-production environments.
- `platform/argocd`: Argo CD bootstrap and applications for the GitOps path.
- `scripts/`: the operational entrypoints behind most `mise run` tasks.
- `docs/`: the step-by-step documentation portal.

## Environment model

| Environment | Purpose | How it runs |
| --- | --- | --- |
| Local | Fast feedback while building features | Docker Compose or separate backend/frontend processes |
| `dev` | Kubernetes learning and smoke-test lab | Local k3s with locally built images |
| `staging` | Canonical pre-production validation | Argo CD + SOPS + GHCR images promoted by digest |
| `staging-local` | Local rehearsal of the staging topology | Argo CD + SOPS + local `:main` images on k3s |

`prod` is intentionally out of scope for this repository today.

## Start here

If this is your first time in the repo, follow this order:

1. Read [`docs/getting-started/what-is-atlas-platform.md`](docs/getting-started/what-is-atlas-platform.md).
2. Follow [`docs/getting-started/learning-path.md`](docs/getting-started/learning-path.md).
3. Complete [`docs/getting-started/quickstart.md`](docs/getting-started/quickstart.md).
4. Use [`docs/development/local-development.md`](docs/development/local-development.md) for daily work.
5. Use [`docs/operations/overview.md`](docs/operations/overview.md) when you move into k3s, GitOps, or promotion.

The full documentation site starts at [`docs/index.md`](docs/index.md).

## First-day commands

```bash
mise install
mise run bootstrap
mise run app-bootstrap
mise run check
mise run docs-build
```

What these do:

- `mise install`: installs the pinned toolchain from `mise.toml`.
- `mise run bootstrap`: installs the Git hooks used by the repository.
- `mise run app-bootstrap`: installs backend and frontend dependencies.
- `mise run check`: runs the standard local validation path.
- `mise run docs-build`: verifies that the documentation site builds cleanly.

## Common next steps

| Goal | Read this |
| --- | --- |
| Understand the repo layout | [`docs/getting-started/repository-map.md`](docs/getting-started/repository-map.md) |
| Learn the day-to-day change lifecycle | [`docs/development/END_TO_END_WORKFLOW.md`](docs/development/END_TO_END_WORKFLOW.md) |
| Work on the backend | [`docs/development/backend-development.md`](docs/development/backend-development.md) |
| Work on the frontend | [`docs/development/frontend-development.md`](docs/development/frontend-development.md) |
| Run Compose locally | [`docs/operations/local-compose.md`](docs/operations/local-compose.md) |
| Validate Kubernetes flows | [`docs/operations/k3s-dev.md`](docs/operations/k3s-dev.md) |
| Learn GitOps bootstrap and staging | [`docs/operations/gitops-bootstrap.md`](docs/operations/gitops-bootstrap.md) |
| Look up commands and environment variables | [`docs/reference/commands.md`](docs/reference/commands.md), [`docs/reference/configuration.md`](docs/reference/configuration.md) |

## Canonical validation commands

```bash
mise run fmt
mise run lint
mise run typecheck
mise run test
mise run docs-build
mise run check
mise run ci
```

These commands are explained in beginner-friendly detail in
[`docs/reference/commands.md`](docs/reference/commands.md).

## Deep runbooks

The learning-path guides are the primary entrypoint. The deep operational details
stay in these runbooks:

- [`docs/deployment/k3s/RUNBOOK.md`](docs/deployment/k3s/RUNBOOK.md)
- [`docs/deployment/gitops/ARGOCD_SOPS_RUNBOOK.md`](docs/deployment/gitops/ARGOCD_SOPS_RUNBOOK.md)
- [`docs/deployment/releases/IMAGE_PROMOTION.md`](docs/deployment/releases/IMAGE_PROMOTION.md)

## Project rules

- [`AGENTS.md`](AGENTS.md): repository contract for agentic work.
- [`CONTRIBUTING.md`](CONTRIBUTING.md): contributor workflow and pull request expectations.
- [`SECURITY.md`](SECURITY.md): vulnerability reporting and secure development requirements.
- [`.github/CODEOWNERS`](.github/CODEOWNERS): mandatory review ownership.
