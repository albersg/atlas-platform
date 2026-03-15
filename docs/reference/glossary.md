# Glossary

## Core repo terms

- `Atlas Platform`: the whole monorepo, including app code, automation, docs, and platform assets.
- `inventory-service`: the active backend service in `services/inventory-service`.
- `web`: the frontend app in `apps/web`.
- `bounded context`: a domain boundary that may eventually justify a separate service.
- `agent-first`: workflows are designed so human contributors and coding agents can use the same commands and rules.

## Tooling terms

- `mise`: the toolchain and task runner used as the primary command interface.
- `pre-commit`: the hook framework that runs formatting, linting, and security checks.
- `ruff`: the Python linter and formatter used by local hooks and validation tasks.
- `pyright`: the static type checker used for the backend Python code.
- `pytest`: the backend test runner.
- `uv`: the Python package manager and command runner used by the backend.
- `npm`: the Node package manager used by the frontend.
- `Vite`: the frontend dev server and production bundler for `apps/web`.
- `FastAPI`: the backend web framework used by `inventory-service`.
- `PostgreSQL`: the main relational database used by the backend and non-production clusters.
- `Docker`: the container runtime used to build and run local or published images.
- `Docker Compose`: the multi-container local app workflow that brings up frontend, backend, and PostgreSQL together.
- `MkDocs Material`: the docs site generator and theme used by `mise run docs-build`.

## Environment terms

- `local`: your workstation running the app through Compose or separate processes.
- `dev`: the local k3s namespace used to validate Kubernetes overlays with locally built images.
- `staging-local`: a local rehearsal of the staging GitOps topology using local `:main` images.
- `staging`: the canonical GitOps-managed pre-production environment using registry images by digest.

## Delivery terms

- `Kubernetes` or `k8s`: the container orchestration platform used for the repo's cluster-based environments.
- `k3s`: the lightweight Kubernetes distribution used for local cluster learning and validation.
- `kubectl`: the standard CLI for talking to a Kubernetes cluster.
- `Kustomize`: the manifest composition tool used to build Kubernetes overlays.
- `GitOps`: the deployment model where Argo CD reconciles manifests from the repository.
- `Argo CD`: the GitOps controller that watches the repo and syncs Kubernetes resources into the cluster.
- `SOPS`: the tool used to keep secrets encrypted in the repo.
- `age`: the encryption key format and tooling used by SOPS in this repo.
- `KSOPS`: the Kustomize plugin that decrypts SOPS-managed secrets during rendering.
- `Kyverno`: the policy engine used to validate rendered overlays against repository policy bundles.
- `digest promotion`: updating the staging image references to immutable `sha256:` digests instead of mutable tags.
- `Trivy`: the image scanner used in the image release workflow.
- `Cosign`: the signing tool used to verify trust for published images.
- `Syft`: the tool used to generate image SBOMs.
- `SBOM`: a software bill of materials; here it is generated for released images and attached as an attestation.

## Validation terms

- `smoke check`: a quick runtime verification that backend, frontend, ingress, and migrations are healthy.
- `strict docs build`: MkDocs build mode that fails on broken references and nav issues.
- `policy check`: repository or overlay validation beyond normal app tests, including security and deployment rules.
- `gitleaks`: the secret scanner used to catch committed credentials or tokens.
- `detect-secrets`: the baseline-aware secret scanner run through `pre-commit`.
- `GitHub Actions`: the CI and release automation system under `.github/workflows/`.
- `dependency review`: the pull-request workflow that blocks risky new runtime dependencies.
- `Dependabot`: the bot that opens dependency update pull requests for GitHub Actions, Python, npm, and Docker inputs.
