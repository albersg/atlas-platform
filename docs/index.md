# Atlas Platform Docs

This documentation is organized as a learning system for a beginner. Start with
repo purpose, then learn the tools, then learn the architecture, then practice
the development and operations workflows in that order.

## Recommended reading order

1. [What is Atlas Platform?](getting-started/what-is-atlas-platform.md)
2. [Tooling primer](getting-started/tooling-primer.md)
3. [Learning path](getting-started/learning-path.md)
4. [First-day setup](getting-started/quickstart.md)
5. [Repository tour](getting-started/repository-map.md)
6. [Glossary](reference/glossary.md)
7. [Architecture overview](architecture/overview.md)
8. [Platform delivery architecture](architecture/platform-delivery-architecture.md)
9. [Daily workflow and change lifecycle](development/END_TO_END_WORKFLOW.md)
10. [Local development](development/local-development.md)
11. [Quality and CI](development/quality-and-ci.md)
12. [Operations overview](operations/overview.md)

## Choose your next guide

| If you want to... | Read this next |
| --- | --- |
| Understand the purpose and boundaries of the repo | [What is Atlas Platform?](getting-started/what-is-atlas-platform.md) |
| Learn what the tool names mean before using them | [Tooling primer](getting-started/tooling-primer.md) |
| Set up your machine on day one | [First-day setup](getting-started/quickstart.md) |
| Learn where code and platform assets live | [Repository tour](getting-started/repository-map.md) |
| Understand why the repo uses Helm, Kustomize, Argo CD, Kyverno, Istio, and Prometheus together | [Architecture overview](architecture/overview.md) and [Platform delivery architecture](architecture/platform-delivery-architecture.md) |
| Learn the standard developer loop | [Daily workflow and change lifecycle](development/END_TO_END_WORKFLOW.md) |
| Run the whole app locally | [Local Compose](operations/local-compose.md) |
| Change backend code or migrations | [Backend development](development/backend-development.md) and [Database and migrations](development/database-migrations.md) |
| Change frontend code | [Frontend development](development/frontend-development.md) |
| Update docs safely | [Docs workflow](development/docs-workflow.md) |
| Understand validation and GitHub Actions | [Quality and CI](development/quality-and-ci.md) |
| Learn k3s, GitOps, staging, monitoring, or promotion | [Operations overview](operations/overview.md) |
| Look up commands, env vars, or error recovery | [Command reference](reference/commands.md), [Configuration reference](reference/configuration.md), and [Troubleshooting](reference/troubleshooting.md) |

## Environment journey

| Stage | What you learn | Primary guide |
| --- | --- | --- |
| Local | App development, validation, and docs work | [Local development](development/local-development.md) |
| `dev` | Kubernetes overlays and smoke checks on local k3s | [k3s dev environment](operations/k3s-dev.md) |
| `staging-local` | Local rehearsal of the GitOps topology | [Staging-local](operations/staging-local.md) |
| `staging` | Canonical GitOps deployment and digest promotion | [Canonical staging](operations/canonical-staging.md) |

## Architecture in one sentence

Atlas Platform uses Helm for reusable workload and infra bases, Kustomize for
environment overlays, Argo CD for GitOps reconciliation, SOPS plus age plus KSOPS
for encrypted secrets, Kyverno for policy-as-code validation, Istio for the staged
service mesh, and Prometheus for platform monitoring.

## Deep runbooks

Use these after the overview pages have oriented you:

- [k3s runbook](deployment/k3s/RUNBOOK.md)
- [GitOps runbook](deployment/gitops/ARGOCD_SOPS_RUNBOOK.md)
- [Image promotion runbook](deployment/releases/IMAGE_PROMOTION.md)
- [Agent-first DevSecOps playbook](AGENT_FIRST_DEVSECOPS_PLAYBOOK.md)
