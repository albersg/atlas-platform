# Atlas Platform Docs

This documentation is organized as a learning path. Start with the beginner
guides, then move into development workflows, then use the operational runbooks
only when you need deeper platform detail.

## Recommended reading order

1. [What is Atlas Platform?](getting-started/what-is-atlas-platform.md)
2. [Learning path](getting-started/learning-path.md)
3. [First-day setup](getting-started/quickstart.md)
4. [Repository tour](getting-started/repository-map.md)
5. [Glossary](reference/glossary.md)
6. [Daily workflow and change lifecycle](development/END_TO_END_WORKFLOW.md)
7. [Local development](development/local-development.md)
8. [Backend development](development/backend-development.md)
9. [Frontend development](development/frontend-development.md)
10. [Quality and CI](development/quality-and-ci.md)
11. [Operations overview](operations/overview.md)

## Choose your next guide

| If you want to... | Read this next |
| --- | --- |
| Understand the purpose and boundaries of the repo | [What is Atlas Platform?](getting-started/what-is-atlas-platform.md) |
| Set up your machine on day one | [First-day setup](getting-started/quickstart.md) |
| Learn where code and platform assets live | [Repository tour](getting-started/repository-map.md) |
| Learn the standard developer loop | [Daily workflow and change lifecycle](development/END_TO_END_WORKFLOW.md) |
| Run the whole app locally | [Local Compose](operations/local-compose.md) |
| Change backend code or migrations | [Backend development](development/backend-development.md) and [Database and migrations](development/database-migrations.md) |
| Change frontend code | [Frontend development](development/frontend-development.md) |
| Update docs safely | [Docs workflow](development/docs-workflow.md) |
| Understand validation and GitHub Actions | [Quality and CI](development/quality-and-ci.md) |
| Learn k3s, GitOps, staging, or promotion | [Operations overview](operations/overview.md) |
| Look up commands, env vars, or error recovery | [Command reference](reference/commands.md), [Configuration reference](reference/configuration.md), and [Troubleshooting](reference/troubleshooting.md) |

## Environment journey

| Stage | What you learn | Primary guide |
| --- | --- | --- |
| Local | App development, validation, and docs work | [Local development](development/local-development.md) |
| `dev` | Kubernetes overlays and smoke checks on local k3s | [k3s dev environment](operations/k3s-dev.md) |
| `staging-local` | Local rehearsal of the GitOps topology | [Staging-local](operations/staging-local.md) |
| `staging` | Canonical GitOps deployment and digest promotion | [Canonical staging](operations/canonical-staging.md) |

## Deep runbooks

Use these after the overview pages have oriented you:

- [k3s runbook](deployment/k3s/RUNBOOK.md)
- [GitOps runbook](deployment/gitops/ARGOCD_SOPS_RUNBOOK.md)
- [Image promotion runbook](deployment/releases/IMAGE_PROMOTION.md)
- [Agent-first DevSecOps playbook](AGENT_FIRST_DEVSECOPS_PLAYBOOK.md)
