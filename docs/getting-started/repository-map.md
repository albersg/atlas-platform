# Repository Tour

This page explains where things live and why they are grouped that way.

## Top-level map

```text
.
├── apps/
├── services/
├── platform/
├── scripts/
├── docs/
├── tests/
├── mise.toml
└── .pre-commit-config.yaml
```

## Application code

- `apps/web`: the React + Vite frontend.
- `services/inventory-service`: the active backend service.
- `services/billing-service`: a placeholder for a future bounded context.

If you are changing product behavior, you usually start in `apps/web` or
`services/inventory-service`.

## Platform and delivery assets

- `platform/k8s`: shared manifests, components, and overlays for `dev`, `staging`, and `staging-local`.
- `platform/argocd`: Argo CD bootstrap and GitOps application definitions.
- `platform/policy`: policy checks applied to non-production overlays.

If you are changing deployment shape, networking, secrets flow, or image wiring,
you usually start in `platform/`.

## Automation entrypoints

- `mise.toml`: source of truth for tools and canonical commands.
- `scripts/k3s`: k3s preflight, image build/import, access, smoke, and cluster helpers.
- `scripts/gitops`: Argo CD bootstrap, render, deploy, and validation helpers.
- `scripts/release`: digest promotion and trusted-image verification helpers.

## Where major tools show up

| Tool or concept | Main repo locations |
| --- | --- |
| `mise` | `mise.toml`, plus every guide that uses `mise run ...` |
| `pre-commit`, `ruff`, `detect-secrets`, `gitleaks`, `pyright` | `.pre-commit-config.yaml` |
| `uv`, FastAPI, `pytest` | `services/inventory-service/`, `pyproject.toml`, backend tests |
| `npm`, Vite, TypeScript | `apps/web/`, `apps/web/package.json`, `apps/web/vite.config.ts` |
| Docker and Docker Compose | `docker-compose.yml`, app Dockerfiles, `scripts/compose/` |
| Kubernetes, k3s, `kubectl`, Kustomize | `platform/k8s/`, `scripts/k3s/`, `scripts/gitops/render-overlay.sh` |
| Argo CD, GitOps, SOPS, age, KSOPS | `platform/argocd/`, `platform/k8s/overlays/`, `scripts/gitops/` |
| Kyverno policies | `platform/policy/kyverno/` |
| Trivy, Cosign, Syft, SBOM release flow | `.github/workflows/release-images.yml`, `scripts/release/` |
| GitHub Actions and dependency review | `.github/workflows/` |
| Dependabot | `.github/dependabot.yml` |

If you want to know what a `mise run` task really does, inspect the matching task
in `mise.toml` and then the script it calls.

## Documentation and governance

- `docs/`: the learning path, guides, and deep runbooks.
- `AGENTS.md`: operating contract for agent sessions.
- `CONTRIBUTING.md`: contributor expectations and pull request rules.
- `SECURITY.md`: vulnerability reporting and secure development requirements.
- `.github/workflows/`: the automation that mirrors local validation and release flows.

## Tests and policy checks

- `tests/`: repository policy tests.
- `services/inventory-service/tests/`: backend tests.

## Where to edit by task type

| If you are changing... | Start here |
| --- | --- |
| Web UI | `apps/web` |
| API, domain rules, persistence, migrations | `services/inventory-service` |
| Docker-based local stack | `docker-compose.yml` and app folders |
| k3s overlays or runtime settings | `platform/k8s` |
| Argo CD or SOPS bootstrap | `platform/argocd` and `scripts/gitops` |
| Release or digest promotion | `scripts/release` and `platform/k8s/components/images/staging` |
| Documentation | `README.md` and `docs/` |

## Read next

- [Glossary](../reference/glossary.md)
- [Daily workflow and change lifecycle](../development/END_TO_END_WORKFLOW.md)
- [Monorepo component map](../reference/components.md)
