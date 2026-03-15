# What Is Atlas Platform?

Atlas Platform is a single repository for building and validating a small
application platform end to end. It combines application code, operational
automation, documentation, and delivery guardrails so contributors and agents
use the same workflows.

## What lives here

- A backend service in `services/inventory-service`.
- A frontend application in `apps/web`.
- Local and Kubernetes deployment assets in `platform/`.
- Automation scripts in `scripts/`.
- Project rules and contributor workflows in the repository root.
- A documentation portal in `docs/`.

## Why it is organized this way

- The repo keeps local development, CI, and staging aligned through `mise run`.
- The same validation path works for humans and agentic tooling.
- Platform assets stay close to the app code they deploy.
- Documentation can explain the whole journey in one place.

## What the repo is not

- It is not a production platform yet.
- It is not a multi-service production fleet.
- It is not only an app repo or only an infra repo; it intentionally mixes both.

## Current environments

| Environment | Why it exists | Normal entrypoint |
| --- | --- | --- |
| Local | Fast feature work | `mise run compose-up`, `mise run backend-dev`, `mise run frontend-dev` |
| `dev` | Learn and validate Kubernetes overlays locally | `mise run k8s-deploy-dev` |
| `staging-local` | Rehearse the staging GitOps topology on a local cluster | `mise run gitops-deploy-staging` |
| `staging` | Canonical pre-production validation | digest promotion into `platform/k8s/overlays/staging` |

## How to read the docs

1. Read [Learning path](learning-path.md) for the reading order.
2. Complete [First-day setup](quickstart.md) to make your machine usable.
3. Read [Repository tour](repository-map.md) so file locations make sense.
4. Move into the development and operations guides only when you need them.
