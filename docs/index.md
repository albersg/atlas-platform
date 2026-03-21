# Atlas Platform Docs

This documentation is organized as a learning system for a beginner. Start with
repo purpose, then learn the tools, then learn the architecture, then practice
the development and operations workflows in that order.
If you want the most explicit zero-to-expert reading order, use
[Beginner study roadmap](getting-started/beginner-study-roadmap.md).
If you want the staged build-it-yourself version, use
[Rebuild this platform by hand](getting-started/rebuild-this-platform.md).
If you already know your goal, jump to
[Choose your path](getting-started/choose-your-path.md).

## Pick your starting guide

| Page | Best when you want to... | Why this page exists |
| --- | --- | --- |
| [Learning path](getting-started/learning-path.md) | get the shorter phased onboarding route | It groups the docs into a few broad learning stages. |
| [Beginner study roadmap](getting-started/beginner-study-roadmap.md) | follow one strict zero-to-expert reading order | It tells you exactly what to read next, when to move on, and what to try in parallel. |
| [Choose your path](getting-started/choose-your-path.md) | jump straight to a job-to-be-done route | It is the best entry when your goal is already specific. |
| [Rebuild this platform by hand](getting-started/rebuild-this-platform.md) | recreate the architecture in another repo | It is an implementation roadmap, not a reading roadmap. |

## Recommended reading order

1. [What is Atlas Platform?](getting-started/what-is-atlas-platform.md)
2. [Tooling primer](getting-started/tooling-primer.md)
3. [Beginner study roadmap](getting-started/beginner-study-roadmap.md)
4. [Rebuild this platform by hand](getting-started/rebuild-this-platform.md)
5. [Learning path](getting-started/learning-path.md)
6. [First-day setup](getting-started/quickstart.md)
7. [Repository tour](getting-started/repository-map.md)
8. [Glossary](reference/glossary.md)
9. [Architecture overview](architecture/overview.md)
10. [Platform delivery architecture](architecture/platform-delivery-architecture.md)
11. [Daily workflow and change lifecycle](development/END_TO_END_WORKFLOW.md)
12. [Local development](development/local-development.md)
13. [Quality and CI](development/quality-and-ci.md)
14. [Operations overview](operations/overview.md)

## Choose your next guide

| If you want to... | Read this next |
| --- | --- |
| Understand the purpose and boundaries of the repo | [What is Atlas Platform?](getting-started/what-is-atlas-platform.md) |
| Learn everything from zero in one explicit guided order | [Beginner study roadmap](getting-started/beginner-study-roadmap.md) |
| Compare the four main beginner entry pages before choosing one | [Choose your path](getting-started/choose-your-path.md) |
| Rebuild a repo like this phase by phase | [Rebuild this platform by hand](getting-started/rebuild-this-platform.md) |
| Learn what the tool names mean before using them | [Tooling primer](getting-started/tooling-primer.md) |
| Set up your machine on day one | [First-day setup](getting-started/quickstart.md) |
| Learn where code and platform assets live | [Repository tour](getting-started/repository-map.md) |
| Understand Kyverno and policy-as-code before it blocks a change | [Policy-as-code basics](getting-started/policy-as-code-basics.md) |
| Understand why the repo uses Helm, Kustomize, Argo CD, Kyverno, Istio, and Prometheus together | [Architecture overview](architecture/overview.md) and [Platform delivery architecture](architecture/platform-delivery-architecture.md) |
| Learn the standard developer loop | [Daily workflow and change lifecycle](development/END_TO_END_WORKFLOW.md) |
| Run the whole app locally | [Local Compose](operations/local-compose.md) |
| Change backend code or migrations | [Backend development](development/backend-development.md) and [Database and migrations](development/database-migrations.md) |
| Change frontend code | [Frontend development](development/frontend-development.md) |
| Update docs safely | [Docs workflow](development/docs-workflow.md) |
| Follow a route by job instead of reading linearly | [Choose your path](getting-started/choose-your-path.md) |
| Understand validation and GitHub Actions | [Quality and CI](development/quality-and-ci.md) |
| Learn k3s, GitOps, staging, monitoring, or promotion | [Operations overview](operations/overview.md) |
| Look up commands, env vars, or error recovery | [Command reference](reference/commands.md), [Configuration reference](reference/configuration.md), and [Troubleshooting](reference/troubleshooting.md) |

## Intent-first routes

Use these when you want the docs to tell you what to read next, not just what a
page covers:

If you want the most explicit beginner sequence with "read this, then try this,"
start with [Beginner study roadmap](getting-started/beginner-study-roadmap.md).

| If your intent is... | Start here | Then read |
| --- | --- | --- |
| understand the repo | [What is Atlas Platform?](getting-started/what-is-atlas-platform.md) | [Repository tour](getting-started/repository-map.md) -> [Architecture overview](architecture/overview.md) -> [Platform delivery architecture](architecture/platform-delivery-architecture.md) |
| understand policy-as-code | [Policy-as-code basics](getting-started/policy-as-code-basics.md) | [Platform delivery architecture](architecture/platform-delivery-architecture.md) -> [Deployment topology](architecture/deployment-topology.md) -> [Quality and CI](development/quality-and-ci.md) |
| make a code change | [Daily workflow and change lifecycle](development/END_TO_END_WORKFLOW.md) | [Local development](development/local-development.md) -> the relevant backend, frontend, database, or docs guide -> [Quality and CI](development/quality-and-ci.md) |
| change platform or Kubernetes config | [Platform delivery architecture](architecture/platform-delivery-architecture.md) | [Operations overview](operations/overview.md) -> [Configuration reference](reference/configuration.md) -> the relevant `dev`, `staging-local`, or `staging` guide |
| learn Helm vs Kustomize here | [Platform delivery architecture](architecture/platform-delivery-architecture.md) | [Operations overview](operations/overview.md) -> [GitOps bootstrap](operations/gitops-bootstrap.md) -> [Tool ownership matrix](reference/tool-ownership-matrix.md) |
| bootstrap GitOps | [GitOps bootstrap](operations/gitops-bootstrap.md) | [Staging-local](operations/staging-local.md) -> [GitOps runbook](deployment/gitops/ARGOCD_SOPS_RUNBOOK.md) |
| use `staging-local` | [Staging-local](operations/staging-local.md) | [Service mesh](operations/service-mesh.md) -> [Monitoring](operations/monitoring.md) -> [Canonical staging](operations/canonical-staging.md) |
| promote to canonical staging | [Release workflow](operations/release-workflow.md) | [Staging promotion](operations/staging-promotion.md) -> [Canonical staging](operations/canonical-staging.md) -> [Image promotion runbook](deployment/releases/IMAGE_PROMOTION.md) |
| troubleshoot something | [Troubleshooting](reference/troubleshooting.md) | [Command reference](reference/commands.md) -> [Configuration reference](reference/configuration.md) -> the failing workflow guide |
| replicate this architecture in another repo | [Rebuild this platform by hand](getting-started/rebuild-this-platform.md) | [Architecture overview](architecture/overview.md) -> [Platform delivery architecture](architecture/platform-delivery-architecture.md) -> [Operating model](project/operating-model.md) -> [Governance](project/governance.md) |

For the full routed version, use [Choose your path](getting-started/choose-your-path.md).

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
