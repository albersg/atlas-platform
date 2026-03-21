# Beginner Study Roadmap

Use this page when your question is: "I want to learn everything here from zero.
What exactly should I read, in what order, and why?"

This roadmap is intentionally linear. Each step tells you:

- what to read,
- what that page teaches,
- when you are ready to move on,
- and one small practical thing to try in parallel.

If you already know your immediate goal, use [Choose your path](choose-your-path.md)
instead.

## How to use this roadmap

- Stay in order for your first pass.
- Do the `Try this in parallel` step only if it is safe on your machine and you
  want hands-on reinforcement.
- Do not aim to memorize every command. Aim to build the mental model first,
  then the workflow, then the platform details.
- Use [Glossary](../reference/glossary.md),
  [Command reference](../reference/commands.md), and
  [Configuration and environment variables](../reference/configuration.md) as
  lookup pages whenever a term or variable slows you down.

## Phase 1: Build the basic mental model

| Order | Read this | What it teaches | Move on when... | Try this in parallel |
| --- | --- | --- | --- | --- |
| 1 | [What is Atlas Platform?](what-is-atlas-platform.md) | The repo's purpose, scope, environments, and why app code, platform assets, automation, and docs live together. | You can explain what this repo is trying to teach and why it has `local`, `dev`, `staging-local`, and `staging`. | Run `git status` and scan the repo root so the top-level folders match the page. |
| 2 | [Tooling primer](tooling-primer.md) | The major tools, who owns each layer, and when each tool starts to matter. | You can say what `mise`, `uv`, `npm`, Helm, Kustomize, Argo CD, SOPS, Istio, and Prometheus do here at a high level. | Run `mise run --help` or open `mise.toml` and match a few task names to the tooling categories. |
| 3 | [First-day setup](quickstart.md) | The minimum workstation setup and the safest first commands for becoming productive. | You know what you need installed and what the normal bootstrap path looks like. | Compare the setup steps with the tools you just learned so the install flow stops feeling like a random checklist. |
| 4 | [Repository tour](repository-map.md) | Where code, platform assets, scripts, tests, and governance files live. | You can answer "where would I start editing?" for backend, frontend, docs, GitOps, and release tasks. | Open the listed top-level directories and verify the map against the real repo layout. |
| 5 | [Glossary](../reference/glossary.md) | Shared vocabulary used across the rest of the docs. | Terms like overlay, GitOps, chart, promotion, and ServiceMonitor stop feeling ambiguous. | Keep it open in another tab and use it as a decoder while reading the next phases. |

## Phase 2: Understand the architecture before the workflows

| Order | Read this | What it teaches | Move on when... | Try this in parallel |
| --- | --- | --- | --- | --- |
| 6 | [Architecture overview](../architecture/overview.md) | The big-picture architecture and how app, platform, policy, and delivery layers fit together. | You can describe the system without going file by file. | Sketch the major layers on paper: app, local workflows, platform packaging, staged delivery. |
| 7 | [Platform delivery architecture](../architecture/platform-delivery-architecture.md) | Why Helm, Kustomize, Argo CD, SOPS, Kyverno, Istio, and Prometheus are combined instead of using one tool for everything. | You understand tool boundaries and the repo's "who owns what" split. | While reading, jump to [Tool ownership matrix](../reference/tool-ownership-matrix.md) when a boundary feels fuzzy. |
| 8 | [Deployment topology](../architecture/deployment-topology.md) | How environments differ and what gets added as you move from local work to staged delivery. | You can explain what changes between local, `dev`, `staging-local`, and canonical `staging`. | Compare the topology doc with the environment ladder in [Tooling primer](tooling-primer.md). |

## Phase 3: Learn the daily contributor loop

| Order | Read this | What it teaches | Move on when... | Try this in parallel |
| --- | --- | --- | --- | --- |
| 9 | [Daily workflow and change lifecycle](../development/END_TO_END_WORKFLOW.md) | The normal change path from reading docs to validating locally to opening a PR. | You can explain the repo's default loop without guessing. | Trace the commands mentioned there back to `mise.toml` so you know where the workflow is defined. |
| 10 | [Local development](../development/local-development.md) | How to run the app and supporting services during day-to-day work. | You know the difference between running pieces individually and using the full local stack. | Choose one local path to rehearse mentally: backend only, frontend only, or full stack via Compose. |
| 11 | [Quality and CI](../development/quality-and-ci.md) | How formatting, linting, typing, tests, security checks, and CI compose into one contract. | You understand why local validation mirrors CI instead of being a different world. | Look up the matching tasks in [Command reference](../reference/commands.md) for `fmt`, `lint`, `typecheck`, `test`, `check`, and `ci`. |
| 12 | [Command reference](../reference/commands.md) | The exact entrypoints behind the workflows you just learned. | The command names stop being magic and you know where to look up details. | Pick three commands you expect to use most and note what each one really runs. |

## Phase 4: Learn the surface you will actually edit

Read the one that matches the type of work you expect to do first, then come back
for the others later.

| If you want to work on... | Read this | It teaches | Move on when... | Try this in parallel |
| --- | --- | --- | --- | --- |
| Backend behavior | [Backend development](../development/backend-development.md) | Service structure, backend workflow, tests, and API change habits. | You know how to run backend-specific commands and where business logic lives. | Open `services/inventory-service` and map the guide to the real folders. |
| Database changes | [Database and migrations](../development/database-migrations.md) | Migration flow, schema change expectations, and how persistence changes are validated. | You know how schema changes move safely through the repo. | Compare the migration guidance to the backend guide so app and DB work feel connected. |
| Frontend work | [Frontend development](../development/frontend-development.md) | Frontend workflow, app structure, and build expectations. | You know where UI code lives and how frontend validation fits the main repo contract. | Open `apps/web` and match the guide's concepts to the real source tree. |
| Docs work | [Docs workflow](../development/docs-workflow.md) | How docs are built, validated, and kept aligned with the rest of the repo. | You know how to change docs without breaking navigation or quality checks. | Read this page while viewing `mkdocs.yml` so nav updates make sense immediately. |

## Phase 5: Learn the platform journey from simple to staged

Do this phase after the local developer loop makes sense. These pages are easier
once you already understand the repo, tools, and daily workflow.

| Order | Read this | What it teaches | Move on when... | Try this in parallel |
| --- | --- | --- | --- | --- |
| 13 | [Operations overview](../operations/overview.md) | The operations map and how the environment-specific guides fit together. | You know which operational guide answers which class of question. | Use it as a table of contents before diving deeper. |
| 14 | [Local Compose](../operations/local-compose.md) | The fastest full-stack runtime outside Kubernetes. | You understand when Compose is enough and when Kubernetes is required. | Compare it with [Local development](../development/local-development.md). |
| 15 | [k3s dev environment](../operations/k3s-dev.md) | The first Kubernetes step and how local images reach a dev cluster. | You understand the repo's simpler Kubernetes learning environment. | Note which pieces are still lighter than staged GitOps. |
| 16 | [GitOps bootstrap](../operations/gitops-bootstrap.md) | How Argo CD, SOPS, KSOPS, and bootstrap scripts create the staged GitOps shape. | You can explain how the repo moves from "run commands locally" to "Git declares desired state." | Keep the [GitOps runbook](../deployment/gitops/ARGOCD_SOPS_RUNBOOK.md) nearby for exact operational detail. |
| 17 | [Service mesh](../operations/service-mesh.md) | Why staged traffic is richer than the simpler environments and what Istio owns. | You understand how ingress and traffic policy fit the staged setup. | Cross-check any unfamiliar ownership questions in [Tool ownership matrix](../reference/tool-ownership-matrix.md). |
| 18 | [Monitoring](../operations/monitoring.md) | What observability is expected to prove in staged environments and what Prometheus owns. | You know the difference between platform monitoring and workload scrape intent. | Look for how `ServiceMonitor` fits into the monitoring story. |
| 19 | [Staging-local](../operations/staging-local.md) | The local rehearsal of the full staged architecture. | You understand what makes `staging-local` more realistic than `dev`. | Read this together with [GitOps bootstrap](../operations/gitops-bootstrap.md) if the bootstrap flow still feels abstract. |
| 20 | [Canonical staging](../operations/canonical-staging.md) | The stricter pre-production environment and its trust expectations. | You can explain why canonical staging is not just "staging-local on another cluster." | Compare its guarantees with the earlier environment docs. |
| 21 | [Backup and restore](../operations/backup-restore.md) | Data safety and operational recovery expectations. | You understand recovery responsibilities, not just happy-path deploys. | Link this mentally to the PostgreSQL sections in the configuration reference. |
| 22 | [Release workflow](../operations/release-workflow.md) | How releasable artifacts are built, scanned, and signed. | You understand where immutable digests, SBOMs, and trust verification enter the process. | Compare this flow with the CI page so local checks and release checks feel like one pipeline. |
| 23 | [Staging promotion](../operations/staging-promotion.md) | How trusted artifacts move into canonical staging and how GitOps promotion differs from local deployment. | You can explain release vs promotion vs runtime validation without mixing them up. | Keep the [Image promotion runbook](../deployment/releases/IMAGE_PROMOTION.md) nearby for the low-level procedure. |

## Phase 6: Keep the lookup pages nearby

These are not the best first pages, but they are the best "I need exact detail"
pages once the overview is in your head.

1. [Tool ownership matrix](../reference/tool-ownership-matrix.md) for "which tool
   owns this layer?"
2. [Configuration and environment variables](../reference/configuration.md) for
   variables, toggles, and script inputs.
3. [Troubleshooting](../reference/troubleshooting.md) for failure-driven reading.
4. [GitOps runbook](../deployment/gitops/ARGOCD_SOPS_RUNBOOK.md) for deep staged
   bootstrap operations.
5. [k3s runbook](../deployment/k3s/RUNBOOK.md) for detailed local cluster work.
6. [Image promotion runbook](../deployment/releases/IMAGE_PROMOTION.md) for the
   deeper promotion procedure.

## If you want the shortest possible zero-to-expert order

Read these in order for the best single-pass journey:

1. [What is Atlas Platform?](what-is-atlas-platform.md)
2. [Tooling primer](tooling-primer.md)
3. [First-day setup](quickstart.md)
4. [Repository tour](repository-map.md)
5. [Glossary](../reference/glossary.md)
6. [Architecture overview](../architecture/overview.md)
7. [Platform delivery architecture](../architecture/platform-delivery-architecture.md)
8. [Deployment topology](../architecture/deployment-topology.md)
9. [Daily workflow and change lifecycle](../development/END_TO_END_WORKFLOW.md)
10. [Local development](../development/local-development.md)
11. [Quality and CI](../development/quality-and-ci.md)
12. [Command reference](../reference/commands.md)
13. The development guide for your area
14. [Operations overview](../operations/overview.md)
15. [GitOps bootstrap](../operations/gitops-bootstrap.md)
16. [Staging-local](../operations/staging-local.md)
17. [Canonical staging](../operations/canonical-staging.md)
18. [Release workflow](../operations/release-workflow.md)
19. [Staging promotion](../operations/staging-promotion.md)
20. Reference and runbook pages as needed

## Read next

1. [Learning path](learning-path.md) for the shorter phased version.
2. [Choose your path](choose-your-path.md) if your goal is now more specific than
   "learn everything."
3. [Tool ownership matrix](../reference/tool-ownership-matrix.md) when you start
   asking "which layer owns this behavior?"
