# Tooling Primer

This page explains the major tools and concepts in plain language before you dive
into deeper guides. You do not need to master everything at once. The goal is to
know what each name means, why the repo uses it, and when it becomes relevant.

## Start with the mental model

Atlas Platform is one repo with three layers:

1. application code you change every day,
2. platform and deployment assets that run the app,
3. automation and policy that keep changes safe.

The tools below exist because each layer needs a different kind of help.

## Daily development tools

| Tool | Plain-language meaning | When you care |
| --- | --- | --- |
| `mise` | The repo's front door. It installs pinned tool versions and gives you standard `mise run ...` tasks. | Immediately. Use it first. |
| `uv` | Python package manager and runner for the backend. | When you install backend dependencies, run tests, or run FastAPI locally. |
| `npm` | Node package manager for the frontend. | When you install frontend dependencies or run the Vite app. |
| FastAPI | The Python web framework for `inventory-service`. | When you change API routes, business logic, or backend behavior. |
| Vite | The frontend dev server and production bundler. | When you run or build `apps/web`. |
| PostgreSQL | The main relational database. | When backend changes touch persistence or migrations. |
| Docker | The container engine used for local stack runs and image builds. | When you use Compose or build images for Kubernetes flows. |
| Docker Compose | The easiest way to run the full local app stack together. | When you want frontend, backend, and PostgreSQL at once. |

## Code quality and safety tools

| Tool | Plain-language meaning | When you care |
| --- | --- | --- |
| `pre-commit` | A wrapper that runs formatting, linting, security, and policy hooks consistently. | During local validation and Git hooks. |
| `ruff` | Python formatter and linter. | When backend formatting or lint checks fail. |
| `pyright` | Static type checker for Python and TypeScript-related workflows. | When type validation fails. |
| `pytest` | Backend test runner. | When you run backend tests. |
| GitHub Actions | The CI system that runs validation, security checks, releases, and promotions. | Before and after pull requests. |
| Trivy | Image vulnerability scanner. | In release and promotion workflows. |
| Cosign | Image signing and trust verification tool. | In release and digest promotion workflows. |
| SBOM / Syft | An SBOM is a list of what is inside an image; Syft generates it. | In release workflows and supply-chain verification. |

## Kubernetes and GitOps tools

| Tool or concept | Plain-language meaning | When you care |
| --- | --- | --- |
| Kubernetes | The container orchestration platform model used for `dev`, `staging-local`, and `staging`. | When local app-only work is not enough. |
| k3s | A lightweight local Kubernetes distribution. | When you want a local cluster on your workstation. |
| `kubectl` | The standard CLI for inspecting and querying a cluster directly. | When helper scripts are not enough or you are troubleshooting. |
| Helm | The packaging tool used here for reusable workload and infra bases. | When you change reusable chart inputs or platform add-ons. |
| Kustomize | The overlay tool used here for environment-specific changes. | When you change `dev`, `staging-local`, or `staging` behavior. |
| Argo CD | The GitOps controller that reconciles Git state into the cluster. | When you work with `staging-local` or canonical `staging`. |
| GitOps | The operating model where Git is the desired source of truth. | When you need to understand why direct manual cluster edits do not last. |
| SOPS | Secret encryption for files stored safely in Git. | When overlays include encrypted secrets. |
| age | The encryption format and key type SOPS uses here. | When you bootstrap or rotate secret access. |
| KSOPS | The plugin that lets Kustomize decrypt SOPS secrets while rendering. | When Argo CD or local render commands build encrypted overlays. |
| Kyverno | Policy-as-code validation for rendered manifests. | When overlay validation blocks a change. |

## Traffic, security, and observability tools

| Tool or concept | Plain-language meaning | When you care |
| --- | --- | --- |
| Istio | The service mesh used in staged environments. | When you work on routing, gateways, sidecars, or mesh policy. |
| service mesh | A networking layer that adds traffic control, identity, and observability around services. | When `staging-local` or `staging` traffic flows behave differently from `dev`. |
| Prometheus | The monitoring system that scrapes metrics from the platform and workloads. | When you work on `/metrics`, `ServiceMonitor`, or monitoring health. |
| `ServiceMonitor` | A Kubernetes object that tells Prometheus which service endpoints to scrape. | When a workload should be monitored. |

## Environment ladder

| Environment | Why it exists | Main toolchain |
| --- | --- | --- |
| Local | Fast app development on your machine. | `mise`, `uv`, `npm`, Docker Compose |
| `dev` | First Kubernetes learning and smoke-test layer. | k3s, `kubectl`, Kustomize |
| `staging-local` | Local rehearsal of the real GitOps topology. | Argo CD, SOPS, age, KSOPS, Helm, Kustomize, Istio, Prometheus |
| `staging` | Canonical pre-production environment. | Same as `staging-local`, but registry images pinned by digest |

## Most important idea to remember

The repo does not use every tool for every environment.

- Local work starts simple.
- `dev` introduces Kubernetes.
- `staging-local` introduces the full GitOps architecture on your machine.
- Canonical `staging` keeps the same architecture, but adds immutable release and
  promotion rules.

## Read next

1. [Learning path](learning-path.md)
2. [First-day setup](quickstart.md)
3. [Architecture overview](../architecture/overview.md)
