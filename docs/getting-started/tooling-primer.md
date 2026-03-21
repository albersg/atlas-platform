# Tooling Primer

This page explains the major tools in plain language before you dive into deeper
guides. The goal is not to memorize everything. The goal is to know what each
tool does, which part of the repo owns it, and when it becomes relevant.

For the dense version, use the [tool ownership matrix](../reference/tool-ownership-matrix.md).

## Start with the mental model

Atlas Platform is one repo with four layers:

1. application code you change every day,
2. local workflows that help you run and validate that code,
3. platform packaging and deployment assets,
4. security and release automation that make staged delivery trustworthy.

Most beginner confusion comes from assuming every tool matters all the time.
It does not.

- Local app work uses a small tool set.
- `dev` adds Kubernetes.
- `staging-local` adds the full GitOps architecture.
- canonical `staging` adds immutable release and promotion rules.

## Daily development tools

| Tool | What it is for | Who owns it in this repo | Where it is configured | When you care |
| --- | --- | --- | --- | --- |
| `mise` | the repo front door for tool versions and shared commands | root automation layer | `mise.toml`, `mise.lock` | immediately; nearly every guide starts here |
| `uv` | backend dependency manager and Python command runner | backend workflow | `mise.toml`, backend project config | when installing backend deps, running tests, or running FastAPI |
| `npm` | frontend dependency manager | `apps/web` | `apps/web/package.json` | when installing frontend deps or running frontend tasks |
| FastAPI | backend web framework | `services/inventory-service` | backend source tree | when changing API behavior |
| Vite | frontend dev server and build tool | `apps/web` | `apps/web/package.json`, `apps/web/src/vite-env.d.ts` | when running or building the web app |
| PostgreSQL | primary database | backend plus platform workload layer | `docker-compose.yml`, k8s postgres components, workload templates | when backend changes touch persistence or migrations |
| Docker | container engine and image builder | local app and release workflows | Dockerfiles, `docker-compose.yml` | when running Compose or building Kubernetes images |
| Docker Compose | easiest full-stack local runtime | local app workflow | `docker-compose.yml`, `scripts/compose/require-compose.sh` | when you want frontend, backend, and database together |

## Quality and safety tools

| Tool | What it is for | Who owns it in this repo | Where it is configured | How it composes |
| --- | --- | --- | --- | --- |
| `pre-commit` | one place to run formatting, linting, policy, and security hooks | quality layer | `.pre-commit-config.yaml` | sits behind `mise run fmt`, `mise run lint`, and local Git hooks |
| `ruff` | Python formatting and linting | Python quality layer | `.pre-commit-config.yaml`, backend config | runs through `pre-commit` rather than as a separate workflow most of the time |
| `pyright` | static type checking | backend and frontend quality flow | `.pre-commit-config.yaml`, `mise.toml`, app package scripts | appears in `typecheck` and as a pre-push backend check |
| `pytest` | backend test runner | backend workflow | backend project config | used through `uv` to stay on the pinned Python environment |
| Markdown linting | documentation quality | docs workflow | `.pre-commit-config.yaml` | keeps docs changes aligned with code-quality expectations |
| secret scanners (`detect-secrets`, `gitleaks`) | stop accidental secrets from landing in Git | security layer | `.pre-commit-config.yaml`, `.secrets.baseline` | run in `lint`, `security`, and CI |
| GitHub Actions | hosted CI, release, and promotion automation | `.github/workflows/` | workflow YAML files | reuses the same repo contracts later in CI and release automation |

## Kubernetes and GitOps tools

| Tool or concept | What it is for | Who owns it in this repo | Where it is configured | When you care |
| --- | --- | --- | --- | --- |
| Kubernetes | the platform model for non-local environments | platform operations layer | `platform/k8s/**`, `scripts/k3s/**` | when local app-only work is not enough |
| k3s | lightweight local Kubernetes cluster | local platform workflow | `scripts/k3s/**` | when you want a local cluster on your workstation |
| `kubectl` | standard cluster CLI | cluster operations layer | command-line plus repo scripts | when helper scripts are not enough or you need live inspection |
| Helm | reusable packaging for workload and infra bases | platform packaging layer | `platform/helm/**` | when changing reusable chart inputs or staged platform add-ons |
| Kustomize | environment-specific overlay composition | env overlay layer | `platform/k8s/**` | when changing `dev`, `staging-local`, or `staging` behavior |
| Argo CD | GitOps controller | staging deployment layer | `platform/argocd/apps/**`, `scripts/gitops/bootstrap/*.sh` | when working with `staging-local` or canonical `staging` |
| GitOps | operating model where Git is the desired state | staging operating model | Argo CD apps plus Git-managed manifests | when you need to understand why manual cluster edits do not last |
| SOPS | encrypted secret storage | secure overlay layer | encrypted overlays and `.sops.yaml` | when staged overlays include secrets |
| age | key format used by SOPS | secure bootstrap layer | `.gitops-local/age/keys.txt`, bootstrap scripts | when bootstrapping or rotating secret access |
| KSOPS | Kustomize plugin that decrypts SOPS files | secure render layer | repo-local plugin path created by bootstrap | when local render commands or Argo CD build encrypted overlays |
| Kyverno | policy-as-code validator | platform policy layer | `platform/policy/kyverno/**` | when overlay validation blocks a change |

## Traffic, observability, and trust tools

| Tool or concept | What it is for | Who owns it in this repo | Where it is configured | Why it matters |
| --- | --- | --- | --- | --- |
| Istio | staged ingress and service mesh | platform infra plus workload mesh split | `platform/helm/istio/**`, `platform/k8s/components/mesh/istio/**` | staged traffic is intentionally richer than `dev` traffic |
| Prometheus | staged monitoring stack | split between infra and workload observability | `platform/helm/prometheus/**`, `platform/k8s/components/observability/prometheus/**` | lets staged environments prove metrics wiring, not just app health |
| `ServiceMonitor` | workload scrape declaration for Prometheus | workload observability layer | `platform/k8s/components/observability/prometheus/inventory-service-monitor.yaml` | a healthy Prometheus stack still needs workload scrape intent |
| Trivy | vulnerability scanning for published images | release security layer | `.github/workflows/release-images.yml` | keeps release artifacts from skipping security review |
| Syft | SBOM generation | release supply-chain layer | `.github/workflows/release-images.yml` | records what is inside each image |
| Cosign | image signing and trust verification | release and promotion trust layer | `.github/workflows/release-images.yml`, `scripts/release/verify-trusted-images.sh` | canonical staging trusts signed digests, not mutable tags |

## Environment ladder

| Environment | Why it exists | Main tools | What changes from the previous step |
| --- | --- | --- | --- |
| Local | fastest application development | `mise`, `uv`, `npm`, Compose | no Kubernetes or GitOps yet |
| `dev` | first Kubernetes learning and smoke-test layer | k3s, `kubectl`, Kustomize | local images plus a simpler Traefik path |
| `staging-local` | local rehearsal of the real staging topology | Argo CD, SOPS, age, KSOPS, Helm, Kustomize, Istio, Prometheus | adds the full staged architecture, but still uses local images |
| `staging` | canonical pre-production verification | same staged stack plus GHCR digests, Cosign trust, release promotion | replaces mutable local images with trusted immutable digests |

## One beginner-friendly way to think about composition

- `mise` is the menu.
- repo scripts under `scripts/` are the recipes.
- Helm and Kustomize build what should exist.
- Argo CD keeps the cluster matching that Git state.
- Kyverno, `istioctl`, Trivy, and Cosign stop unsafe or untrusted states from being accepted.

## When the tool names stop being enough

- If you want the safe reading order, go to the [learning path](learning-path.md).
- If you want exact commands, go to the [command reference](../reference/commands.md).
- If a command mentions variables you do not recognize, go to [configuration and environment variables](../reference/configuration.md).
- If the tool list feels too dense, use the [tool ownership matrix](../reference/tool-ownership-matrix.md) as a lookup table rather than reading it front to back.

## Read next

1. [Learning path](learning-path.md)
2. [First-day setup](quickstart.md)
3. [Command reference](../reference/commands.md)
4. [Architecture overview](../architecture/overview.md)
