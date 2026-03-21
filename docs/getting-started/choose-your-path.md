# Choose Your Path

Use this page when you do not want to read the docs linearly. Pick the intent that
matches your job, then follow the linked chain in order.

If you are brand new to the repo, start with
[What is Atlas Platform?](what-is-atlas-platform.md) and
[Tooling primer](tooling-primer.md) first.
If you want the full beginner journey in one strict sequence, use
[Beginner study roadmap](beginner-study-roadmap.md).

## Intent routes

### I want to understand the repo

Read in this order:

1. [What is Atlas Platform?](what-is-atlas-platform.md)
2. [Repository tour](repository-map.md)
3. [Architecture overview](../architecture/overview.md)
4. [Platform delivery architecture](../architecture/platform-delivery-architecture.md)

Read next after that: [Learning path](learning-path.md) if you want the full beginner journey, or [Daily workflow and change lifecycle](../development/END_TO_END_WORKFLOW.md) if you are ready to contribute.

### I want to make a code change

Read in this order:

1. [Daily workflow and change lifecycle](../development/END_TO_END_WORKFLOW.md)
2. [Local development](../development/local-development.md)
3. The area-specific guide you need:
   - [Backend development](../development/backend-development.md)
   - [Frontend development](../development/frontend-development.md)
   - [Database and migrations](../development/database-migrations.md)
   - [Docs workflow](../development/docs-workflow.md)
4. [Quality and CI](../development/quality-and-ci.md)
5. [Command reference](../reference/commands.md)

Read next after that: [Troubleshooting](../reference/troubleshooting.md) when validation or runtime behavior fails.

### I want to change platform or Kubernetes config

Read in this order:

1. [Repository tour](repository-map.md)
2. [Platform delivery architecture](../architecture/platform-delivery-architecture.md)
3. [Operations overview](../operations/overview.md)
4. [Configuration and environment variables](../reference/configuration.md)
5. The environment guide you are changing:
   - [k3s dev environment](../operations/k3s-dev.md)
   - [Staging-local](../operations/staging-local.md)
   - [Canonical staging](../operations/canonical-staging.md)

Read next after that: [Command reference](../reference/commands.md) for exact render, validate, and deploy commands.

### I want to learn Helm vs Kustomize here

Read in this order:

1. [Architecture overview](../architecture/overview.md)
2. [Platform delivery architecture](../architecture/platform-delivery-architecture.md)
3. [Operations overview](../operations/overview.md)
4. [GitOps bootstrap](../operations/gitops-bootstrap.md)
5. [Tool ownership matrix](../reference/tool-ownership-matrix.md)

Read next after that: [Command reference](../reference/commands.md) if you want the script and task entrypoints that exercise each layer.

### I want to bootstrap GitOps

Read in this order:

1. [Operations overview](../operations/overview.md)
2. [GitOps bootstrap](../operations/gitops-bootstrap.md)
3. [Staging-local](../operations/staging-local.md)
4. [GitOps runbook](../deployment/gitops/ARGOCD_SOPS_RUNBOOK.md)

Read next after that: [Troubleshooting](../reference/troubleshooting.md) if Argo CD, SOPS, KSOPS, or repo credentials fail.

### I want to use staging-local

Read in this order:

1. [GitOps bootstrap](../operations/gitops-bootstrap.md)
2. [Service mesh](../operations/service-mesh.md)
3. [Monitoring](../operations/monitoring.md)
4. [Staging-local](../operations/staging-local.md)

Read next after that: [Canonical staging](../operations/canonical-staging.md) to understand what gets stricter in the real pre-production path.

### I want to promote to canonical staging

Read in this order:

1. [Release workflow](../operations/release-workflow.md)
2. [Staging promotion](../operations/staging-promotion.md)
3. [Canonical staging](../operations/canonical-staging.md)
4. [Image promotion runbook](../deployment/releases/IMAGE_PROMOTION.md)

Read next after that: [Troubleshooting](../reference/troubleshooting.md) if trust verification, overlay validation, or staged runtime checks fail.

### I want to troubleshoot something

Read in this order:

1. [Troubleshooting](../reference/troubleshooting.md)
2. [Command reference](../reference/commands.md)
3. [Configuration and environment variables](../reference/configuration.md)

Then jump back into the failing area:

- [Quality and CI](../development/quality-and-ci.md)
- [GitOps bootstrap](../operations/gitops-bootstrap.md)
- [Staging-local](../operations/staging-local.md)
- [Canonical staging](../operations/canonical-staging.md)
- [Staging promotion](../operations/staging-promotion.md)

### I want to replicate this architecture in another repo

Read in this order:

1. [Rebuild this platform by hand](rebuild-this-platform.md)
2. [What is Atlas Platform?](what-is-atlas-platform.md)
3. [Architecture overview](../architecture/overview.md)
4. [Platform delivery architecture](../architecture/platform-delivery-architecture.md)
5. [Operating model](../project/operating-model.md)
6. [Governance](../project/governance.md)
7. [ADR 0001 - Monorepo vs multirepo](../adr/0001-monorepo-vs-multirepo.md)

Read next after that: [GitOps bootstrap](../operations/gitops-bootstrap.md) and [Tool ownership matrix](../reference/tool-ownership-matrix.md) if you want the practical implementation split by tool.

## When you want exact details instead of routes

- Use [Command reference](../reference/commands.md) for exact task behavior.
- Use [Configuration and environment variables](../reference/configuration.md) for env vars and script inputs.
- Use [Tool ownership matrix](../reference/tool-ownership-matrix.md) for "which layer owns this" questions.
- Use [Beginner study roadmap](beginner-study-roadmap.md) for the most explicit
  zero-to-expert order.
- Use [Learning path](learning-path.md) for the full zero-to-expert sequence.
