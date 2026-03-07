# Atlas Platform Docs

Welcome to the Atlas Platform documentation portal.

## Quick links

- Architecture decision records in `docs/adr/`.
- Architecture blueprints in `docs/architecture/`.
- End-to-end developer workflow in `docs/development/`.
- Deployment runbook in `docs/deployment/`.
- GitOps runbook for Argo CD + SOPS in `docs/deployment/gitops/`.

## Standard validation path

Use the canonical commands:

```bash
mise run fmt
mise run lint
mise run typecheck
mise run test
mise run docs-build
mise run check
mise run ci
```

## Development environments

- Local stack: `mise run compose-up`
- k3s dev deployment: `mise run k8s-deploy-dev`
