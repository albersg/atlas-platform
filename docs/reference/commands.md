# Command Reference

`mise.toml` is the source of truth for project commands. This page explains the
most important tasks in a consistent template so a first-time reader knows when
to use them and what to expect.

## Important tools behind the commands

These commands are wrappers around a smaller set of tools the repo depends on:

| Tool | Why it matters |
| --- | --- |
| `mise` | pins tool versions and gives the repo a single command surface |
| `uv` | installs and runs backend Python tooling |
| `npm` and Vite | install, serve, and build the frontend |
| Docker and Docker Compose | run the local stack and build images |
| `kubectl`, k3s, and Kustomize | support local Kubernetes rendering and deployment |
| Argo CD, SOPS, age, KSOPS, Helm, Istio, and Prometheus | power the GitOps, encrypted-secret, workload-base, and platform-infra render flows |
| Kyverno | validates rendered overlays against repository policy rules |
| Trivy, Cosign, and Syft | protect the image release and promotion path |
| `pre-commit`, `ruff`, `pyright`, `pytest` | provide local quality checks |
| GitHub Actions, Dependabot, dependency review | keep CI and dependency maintenance consistent |

## How to read an entry

Each command section answers the same questions:

- what the command is for,
- when to run it,
- prerequisites,
- what it does under the hood,
- what success looks like,
- what to run next.

## Setup and environment

### `mise run doctor`

- Purpose: show general `mise` diagnostics plus repository Kubernetes readiness.
- When to run: machine setup problems or confusing tool state.
- Prerequisites: `mise` installed.
- Under the hood: runs `mise doctor`, validates task definitions, then runs `./scripts/k3s/cluster/doctor.sh`.
- Success looks like: a readable environment report with no missing critical dependencies.
- Run next: `mise run bootstrap` or the specific missing setup step.

### `mise run bootstrap`

- Purpose: install Git hooks.
- When to run: first setup or after hook problems.
- Prerequisites: toolchain installed through `mise install`.
- Under the hood: runs `pre-commit install --install-hooks` for `pre-commit` and `pre-push`.
- Success looks like: hook installation messages.
- Run next: `mise run app-bootstrap`.

### `mise run app-bootstrap`

- Purpose: install backend and frontend dependencies.
- When to run: first setup or after dependency changes.
- Prerequisites: `mise run bootstrap` is recommended first.
- Under the hood: runs backend `uv sync --extra dev` and frontend `npm install`.
- Success looks like: Python and Node dependencies installed without errors.
- Run next: your chosen dev loop.

### `mise run hooks-update`

- Purpose: update pinned `pre-commit` hook revisions.
- When to run: maintenance work on repository tooling.
- Prerequisites: working `pre-commit` installation.
- Under the hood: runs `pre-commit autoupdate`.
- Success looks like: `.pre-commit-config.yaml` revisions updated.
- Run next: `mise run lint` and `mise run ci`.

### `mise run lock`

- Purpose: refresh `mise.lock`.
- When to run: after changing tool versions in `mise.toml`.
- Prerequisites: updated `mise.toml`.
- Under the hood: runs `mise lock`.
- Success looks like: `mise.lock` reflects the current tool definitions.
- Run next: `mise install` and validation.

## Quality, tests, and docs

### `mise run fmt`

- Purpose: apply safe formatting fixes.
- When to run: before linting or when `fmt-check` fails.
- Prerequisites: hooks installed.
- Under the hood: runs selected formatting-oriented `pre-commit` hooks.
- Success looks like: files are updated or confirmed clean.
- Run next: `mise run lint`.

### `mise run fmt-check`

- Purpose: prove formatting is already clean.
- When to run: inside CI-equivalent validation.
- Prerequisites: none beyond a working repo checkout.
- Under the hood: runs `mise run fmt` and then `git diff --exit-code`.
- Success looks like: no remaining diff.
- Run next: `mise run check`.

### `mise run lint`

- Purpose: run lint and repository policy checks.
- When to run: after formatting and before full validation.
- Prerequisites: hooks installed.
- Under the hood: validates the hook config and runs `pre-commit` with bounded retries.
- Success looks like: all hooks pass and no further auto-fixes remain.
- Run next: `mise run typecheck`.

### `mise run security`

- Purpose: run focused security checks.
- When to run: before a PR or when security-related files changed.
- Prerequisites: hook tooling installed.
- Under the hood: runs private-key detection, `detect-secrets`, `gitleaks`, workflow checks, and `zizmor`.
- Success looks like: no secrets, unsafe workflow patterns, or blocked issues found.
- Run next: `mise run ci` if you are preparing a PR.

### `mise run test`

- Purpose: run repo policy tests and backend unit tests.
- When to run: after lint and type checks.
- Prerequisites: backend dependencies installed.
- Under the hood: runs `unittest` in `tests/` and backend `pytest` unit tests through `uv`.
- Success looks like: repository policy and backend behavior both pass.
- Run next: `mise run docs-build` or `mise run check`.

### `mise run backend-test-cov`

- Purpose: run the backend tests with coverage-oriented output.
- When to run: backend-focused validation or deeper debugging.
- Prerequisites: backend dependencies installed.
- Under the hood: runs backend `pytest` over the full backend test tree.
- Success looks like: backend tests pass across the service test suite.
- Run next: `mise run backend-typecheck` or broader validation.

### `mise run backend-typecheck`

- Purpose: static type checking for the backend.
- When to run: backend changes or before grouped validation.
- Prerequisites: backend dependencies installed.
- Under the hood: runs `pyright` in the backend project.
- Success looks like: no type errors.
- Run next: `mise run typecheck` or `mise run test`.

### `mise run typecheck`

- Purpose: run all repository type checks.
- When to run: before tests in the standard validation flow.
- Prerequisites: backend and frontend dependencies installed.
- Under the hood: runs `backend-typecheck` and `frontend-typecheck`.
- Success looks like: both backend and frontend type systems are clean.
- Run next: `mise run test`.

### `mise run docs-build`

- Purpose: build the docs site in strict mode.
- When to run: after any docs change and before PRs that change workflows.
- Prerequisites: internet access the first time `uvx` fetches MkDocs packages.
- Under the hood: runs `mkdocs build --strict` through `uvx` with pinned versions.
- Success looks like: the docs site builds without navigation or link errors.
- Run next: `mise run check` or `mise run ci`.

### `mise run docs-serve`

- Purpose: preview docs locally.
- When to run: while iterating on documentation.
- Prerequisites: none beyond docs build dependencies being available.
- Under the hood: runs `mkdocs serve -a 0.0.0.0:8001`.
- Success looks like: a local docs server on port `8001`.
- Run next: refresh your browser while editing docs.

### `mise run check`

- Purpose: run the standard grouped local validation path.
- When to run: before you call a change locally complete.
- Prerequisites: dependencies installed.
- Under the hood: runs `lint`, `typecheck`, `frontend-build`, and `test`.
- Success looks like: the core local quality path passes.
- Run next: `mise run docs-build` and then `mise run ci` if the change is PR-bound.

### `mise run fix`

- Purpose: shorthand for safe auto-fixes.
- When to run: when you want formatting fixes without remembering the canonical formatter command.
- Prerequisites: same as `fmt`.
- Under the hood: runs `mise run fmt`.
- Success looks like: same outcome as `fmt`.
- Run next: `mise run lint`.

### `mise run ci`

- Purpose: reproduce the CI path locally as closely as practical.
- When to run: before opening a pull request or after broad changes.
- Prerequisites: dependencies installed plus any required platform tooling for overlay validation.
- Under the hood: runs `fmt-check`, `check`, `k8s-validate-overlays`, `docs-build`, and `security`.
- Success looks like: the local result closely matches what GitHub Actions will expect.
- Run next: open the pull request or investigate the failing stage.

## Application development

### `mise run backend-dev`

- Purpose: run the backend locally.
- When to run: backend-focused development.
- Prerequisites: backend dependencies installed; database reachable if needed.
- Under the hood: starts Uvicorn with reload in `services/inventory-service`.
- Success looks like: backend available on port `8000`.
- Run next: `mise run backend-test` or `mise run backend-migrate`.

### `mise run backend-migrate`

- Purpose: apply backend migrations.
- When to run: after pulling schema changes or testing a new migration.
- Prerequisites: reachable database.
- Under the hood: runs `alembic upgrade head`.
- Success looks like: Alembic reaches the head revision.
- Run next: run the backend or tests that depend on the new schema.

### `mise run backend-test`

- Purpose: run backend tests quickly.
- When to run: backend-focused validation.
- Prerequisites: backend dependencies installed.
- Under the hood: runs backend `pytest -q`.
- Success looks like: service test suite passes.
- Run next: `mise run backend-test-cov` or grouped validation.

### `mise run frontend-dev`

- Purpose: run the frontend locally.
- When to run: frontend-focused development.
- Prerequisites: frontend dependencies installed.
- Under the hood: runs `npm run dev` in `apps/web`.
- Success looks like: a local Vite server with hot reload.
- Run next: `mise run frontend-build` or `mise run frontend-typecheck`.

### `mise run frontend-build`

- Purpose: build the production frontend bundle.
- When to run: before handoff or as part of grouped validation.
- Prerequisites: frontend dependencies installed.
- Under the hood: runs `vite build`.
- Success looks like: a successful production build.
- Run next: `mise run check` or `mise run ci`.

### `mise run frontend-typecheck`

- Purpose: static type checking for the frontend.
- When to run: frontend changes or before grouped validation.
- Prerequisites: frontend dependencies installed.
- Under the hood: runs `tsc --noEmit`.
- Success looks like: no TypeScript errors.
- Run next: `mise run typecheck` or `mise run frontend-build`.

### `mise run compose-up`

- Purpose: start the full local stack with Docker Compose.
- When to run: full-stack local testing.
- Prerequisites: Docker available.
- Under the hood: calls the Compose wrapper script with `up --build -d`.
- Success looks like: PostgreSQL, backend, and frontend are all running.
- Run next: `mise run compose-logs`.

### `mise run compose-down`

- Purpose: stop the Compose stack.
- When to run: cleanup after full-stack work.
- Prerequisites: a running Compose stack.
- Under the hood: calls the Compose wrapper with `down`.
- Success looks like: containers stop cleanly.
- Run next: another local loop, if needed.

### `mise run compose-logs`

- Purpose: inspect stack logs.
- When to run: startup debugging or runtime troubleshooting.
- Prerequisites: running Compose stack.
- Under the hood: tails Compose logs.
- Success looks like: readable logs from the local services.
- Run next: fix the underlying issue or continue testing.

## Kubernetes and cluster flows

### `mise run k8s-preflight`

- Purpose: validate cluster prerequisites.
- When to run: before using `dev` on k3s.
- Prerequisites: `kubectl` and an accessible cluster.
- Under the hood: runs `./scripts/k3s/cluster/preflight.sh`.
- Success looks like: the cluster is ready for the repo's Kubernetes workflows.
- Run next: `mise run k8s-build-images`.

### `mise run k8s-doctor`

- Purpose: check repository-specific Kubernetes and GitOps readiness.
- When to run: before staging-local or canonical staging work.
- Prerequisites: cluster access and relevant tooling.
- Under the hood: runs `./scripts/k3s/cluster/doctor.sh`.
- Useful detail: set `ATLAS_DOCTOR_SCOPE=dev` for a lighter check.
- Useful detail: the staging scope now checks the full infra Argo CD app set (`atlas-platform-istio-base`, `atlas-platform-istiod`, `atlas-platform-istio-ingress`, and `atlas-platform-prometheus`), plus the live `istio-system` and `monitoring` runtimes separately from the Atlas workload app.
- Success looks like: no missing critical GitOps or k3s prerequisites.
- Run next: `mise run k8s-validate-overlays` or deployment.

### `mise run k8s-build-images`

- Purpose: build local images for the `dev` overlay.
- When to run: before importing and deploying `dev`.
- Prerequisites: Docker and a local checkout.
- Under the hood: runs `./scripts/k3s/images/build.sh` and records image tags.
- Success looks like: locally built backend and frontend images plus `.gitops-local/k3s/dev-images.env`.
- Run next: `mise run k8s-import-images`.

### `mise run k8s-import-images`

- Purpose: import the built images into k3s containerd.
- When to run: after `k8s-build-images`.
- Prerequisites: active image state written by the build step.
- Under the hood: runs `./scripts/k3s/images/import.sh`.
- Success looks like: the cluster can access the exact images you built.
- Run next: `mise run k8s-deploy-dev`.

### `mise run k8s-build-staging-images`

- Purpose: build local image refs for `staging-local`.
- When to run: before local staging rehearsal.
- Prerequisites: Docker and a local cluster path.
- Under the hood: runs `./scripts/k3s/images/build-staging.sh`.
- Success looks like: local images tagged for the staging-local path.
- Run next: `mise run k8s-import-staging-images` or `mise run gitops-deploy-staging`.

### `mise run k8s-import-staging-images`

- Purpose: import local staging-local refs into k3s.
- When to run: after building staging-local images.
- Prerequisites: staging-local images already built.
- Under the hood: runs `./scripts/k3s/images/import-staging.sh`.
- Success looks like: the local cluster can reuse those `:main` refs.
- Run next: `mise run gitops-deploy-staging`.

### `mise run k8s-deploy-dev`

- Purpose: deploy the `dev` overlay and run smoke checks.
- When to run: after building and importing local images.
- Prerequisites: `k8s-preflight`, built images, imported images.
- Under the hood: runs `./scripts/k3s/deploy/dev.sh`.
- Success looks like: workloads become healthy and smoke checks pass.
- Run next: `mise run k8s-status` or `mise run k8s-access`.

### `mise run k8s-smoke`

- Purpose: run smoke checks against `dev`.
- When to run: after deployment or while debugging runtime health.
- Prerequisites: the `dev` namespace exists.
- Under the hood: calls `./scripts/k3s/verify/smoke.sh dev atlas-platform-dev`.
- Success looks like: backend, frontend, ingress, and migration checks pass.
- Run next: fix the runtime issue if any step fails.

### `mise run k8s-smoke-staging`

- Purpose: run smoke checks against `staging` or `staging-local`.
- When to run: after GitOps synchronization.
- Prerequisites: the staging namespace exists.
- Under the hood: calls `./scripts/k3s/verify/smoke.sh staging atlas-platform-staging`.
- Useful detail: set `ATLAS_STAGING_INGRESS_SCHEME=https` if a later TLS-enabled gateway rollout is in place; the first mesh slice defaults to HTTP.
- Success looks like: staging runtime paths pass their smoke checks through the Istio gateway hostnames.
- Run next: verify access or continue promotion validation.

### `mise run k8s-status`

- Purpose: show `dev` workload status.
- When to run: after deployment or during troubleshooting.
- Prerequisites: `dev` namespace exists.
- Under the hood: calls `./scripts/k3s/cluster/status.sh`.
- Success looks like: clear workload, service, and ingress status for `dev`.
- Run next: `mise run k8s-access`.

### `mise run k8s-status-staging`

- Purpose: show staging workload status.
- When to run: after GitOps synchronization or during troubleshooting.
- Prerequisites: staging namespace exists.
- Under the hood: calls `./scripts/k3s/cluster/status.sh atlas-platform-staging`.
- Success looks like: clear workload status plus the live `istio-system` runtime and Argo CD application states for staging.
- Run next: `mise run k8s-access-staging`.

### `mise run k8s-access`

- Purpose: print `dev` host mappings and URLs.
- When to run: after a healthy `dev` deployment.
- Prerequisites: `dev` is deployed.
- Under the hood: runs `./scripts/k3s/cluster/access.sh`.
- Success looks like: hostnames and URLs you can use immediately.
- Run next: open the app or API.

### `mise run k8s-access-staging`

- Purpose: print staging host mappings and URLs.
- When to run: after a healthy staging synchronization.
- Prerequisites: staging exists.
- Under the hood: runs the access helper with the staging namespace and hostnames.
- Useful detail: it follows `ATLAS_STAGING_INGRESS_SCHEME`, which defaults to `http` for the first mesh onboarding slice.
- Success looks like: URLs for `staging.atlas.example.com` and `api.staging.atlas.example.com`.
- Run next: manual smoke verification in a browser or API client.

### `mise run k8s-delete-dev`

- Purpose: remove `dev` overlay resources.
- When to run: when cleaning up the k3s lab.
- Prerequisites: a deployed `dev` environment.
- Under the hood: renders the `dev` overlay and pipes it to `kubectl delete`.
- Success looks like: `dev` resources are removed.
- Run next: rebuild and redeploy when needed.

### `mise run k8s-delete-staging`

- Purpose: tear down GitOps-managed staging safely.
- When to run: intentional staging cleanup only.
- Prerequisites: explicit confirmation via `ATLAS_CONFIRM_STAGING_DELETE=atlas-platform-staging`.
- Under the hood: uses the GitOps-aware delete script that removes the Argo CD Application first and preserves namespace and PVCs by default.
- Success looks like: workloads are removed without accidental storage loss.
- Run next: only redeploy when you intend to recreate staging.

### `mise run k8s-backup-postgres-staging`

- Purpose: create a timestamped staging backup.
- When to run: before risky staging data work or during recovery rehearsal.
- Prerequisites: staging PostgreSQL reachable through the cluster workflow.
- Under the hood: runs the staging backup script with `ATLAS_POSTGRES_ENV=staging`.
- Success looks like: a backup file saved under `.gitops-local/backups/staging/`.
- Run next: store the path for restore if needed.

### `mise run k8s-restore-postgres-staging`

- Purpose: restore staging PostgreSQL from a chosen dump.
- When to run: controlled recovery only.
- Prerequisites: `BACKUP_FILE` plus explicit confirmation token.
- Under the hood: runs the staging restore script with guardrails and post-restore verification.
- Success looks like: restore completes, migration reruns, and smoke checks pass.
- Run next: verify the application state carefully.

### `mise run k8s-validate-overlays`

- Purpose: validate rendered non-production overlays and policies.
- When to run: before CI, before promotion, or after manifest changes.
- Prerequisites: GitOps tooling and SOPS context if encrypted overlays are involved.
- Under the hood: runs `./scripts/gitops/validate-overlays.sh`, which renders the Helm-backed Atlas workload base through Kustomize and KSOPS, renders the full platform-infra add-on inventory with Helm for `staging` and `staging-local`, applies Kyverno policy bundles to combined staging surfaces, verifies trusted images, schema-checks manifests, and runs `istioctl analyze`.
- Success looks like: `dev`, `staging`, `staging-local`, and both platform-infra render targets build cleanly for Istio plus Prometheus.
- Run next: deployment or `mise run ci`.

### `mise run policy-check`

- Purpose: alias for overlay-aware policy validation.
- When to run: when you want a semantically named policy step.
- Prerequisites: same as `k8s-validate-overlays`.
- Under the hood: runs the same validation script.
- Success looks like: same outcome as `k8s-validate-overlays`.
- Run next: deployment or CI.

## GitOps and Argo CD

### `mise run gitops-install-tools`

- Purpose: install local Argo CD, SOPS, age, Helm, Istio, and helper binaries.
- When to run: first GitOps bootstrap on a machine.
- Prerequisites: shell access and permissions to install local helper tooling.
- Under the hood: runs `./scripts/gitops/bootstrap/install-tools.sh` to fetch local Argo CD, SOPS, age, Kustomize, Kyverno, Helm, Istio, and related GitOps helpers.
- Success looks like: required GitOps helper binaries are present.
- Run next: bootstrap Argo CD core.

### `mise run gitops-bootstrap-core`

- Purpose: install Argo CD core and KSOPS into the cluster.
- When to run: during GitOps bootstrap.
- Prerequisites: cluster access.
- Under the hood: runs `./scripts/gitops/bootstrap/install-argocd.sh`.
- Success looks like: `argocd` namespace and core components are ready.
- Run next: install age key and repository credential.

### `mise run gitops-install-age-key`

- Purpose: install the local SOPS age key into `argocd`.
- When to run: after generating or obtaining the local age key.
- Prerequisites: local key material plus cluster access.
- Under the hood: runs `./scripts/gitops/bootstrap/install-age-key-secret.sh`.
- Success looks like: Argo CD can decrypt the encrypted secrets it needs.
- Run next: install the repository credential.

### `mise run gitops-install-repo-credential`

- Purpose: install the repository deploy credential for Argo CD.
- When to run: during GitOps bootstrap.
- Prerequisites: the local deploy key already exists.
- Under the hood: runs `./scripts/gitops/bootstrap/install-repo-credential.sh`.
- Success looks like: Argo CD can read the repository over Git.
- Run next: apply apps.

### `mise run gitops-apply-apps`

- Purpose: apply the Argo CD application bundle.
- When to run: after core bootstrap and credentials are ready.
- Prerequisites: Argo CD ready, repo credential ready, age key ready.
- Under the hood: runs `./scripts/gitops/bootstrap/apply-apps.sh`.
- Success looks like: the infra application set (`atlas-platform-istio-base`, `atlas-platform-istiod`, `atlas-platform-istio-ingress`, and `atlas-platform-prometheus`) plus `atlas-platform-staging` exist with the expected environment-specific value files.
- Run next: wait or deploy staging.

### `mise run gitops-apply-staging`

- Purpose: apply only the staging Argo CD application.
- When to run: more targeted GitOps setup or troubleshooting.
- Prerequisites: same prerequisites as `gitops-apply-apps`.
- Under the hood: runs `./scripts/gitops/bootstrap/apply-staging-app.sh`.
- Success looks like: the full staging topology application set is applied with the current rollout mode.
- Run next: `mise run gitops-wait-staging`.

### `mise run gitops-wait-staging`

- Purpose: wait for the staging Argo CD application to converge.
- When to run: after applying or deploying staging.
- Prerequisites: staging application exists.
- Under the hood: runs `./scripts/gitops/wait-app.sh atlas-platform-staging`.
- Useful detail: this command waits only for the Atlas workload application; `mise run gitops-deploy-staging` is the command that waits for the full infra add-on set first.
- Success looks like: synchronization completes successfully.
- Run next: `mise run k8s-status-staging` or smoke checks.

### `mise run gitops-deploy-staging`

- Purpose: deploy staging through Argo CD and run smoke checks.
- When to run: local staging rehearsal or canonical staging deployment, depending on flags.
- Prerequisites: GitOps bootstrap complete.
- Under the hood: runs `./scripts/gitops/deploy/staging.sh`.
- Important detail: by default on local k3s it uses `staging-local`; set `STAGING_LOCAL_IMAGES=0` to target canonical `staging` behavior.
- Important detail: it waits for `atlas-platform-istio-base`, `atlas-platform-istiod`, `atlas-platform-istio-ingress`, and `atlas-platform-prometheus` before the Atlas workload app, then prints staging status and runs mesh-aware smoke checks.
- Important detail: Prometheus validation only counts when the `monitoring` namespace resources actually converge in the target cluster; rendering alone is not enough.
- Success looks like: Argo CD infra sync, workload sync, and smoke checks all succeed.
- Run next: `mise run k8s-status-staging` and `mise run k8s-access-staging`.

### `mise run gitops-render-dev`

- Purpose: render the encrypted `dev` overlay locally.
- When to run: manifest or policy debugging.
- Prerequisites: KSOPS/SOPS tooling available.
- Under the hood: runs `./scripts/gitops/render-overlay.sh platform/k8s/overlays/dev`.
- Success looks like: rendered manifests printed successfully.
- Run next: inspect output or run overlay validation.

### `mise run gitops-render-staging`

- Purpose: render the encrypted staging overlay locally.
- When to run: promotion prep or staging manifest debugging.
- Prerequisites: KSOPS/SOPS tooling available.
- Under the hood: runs `./scripts/gitops/render-overlay.sh platform/k8s/overlays/staging`.
- Success looks like: canonical staging manifests render without decryption errors.
- Run next: `mise run k8s-validate-overlays`.

### `mise run gitops-render-platform-infra-staging-local`

- Purpose: render the staged platform-infra add-on inputs for `staging-local`.
- When to run: before local infra rehearsal or while editing Helm wrapper chart values.
- Prerequisites: `mise run gitops-install-tools` completed.
- Under the hood: runs `./scripts/gitops/render-platform-infra.sh staging-local` and templates every registered platform-infra wrapper chart in a deterministic order.
- Success looks like: Helm emits clean YAML for the staged Istio and Prometheus applications using `values-staging-local.yaml`.
- Run next: `mise run k8s-validate-overlays`.

### `mise run gitops-render-platform-infra-staging`

- Purpose: render the staged platform-infra add-on inputs for canonical `staging`.
- When to run: before promoting the infra model beyond local rehearsal.
- Prerequisites: `mise run gitops-install-tools` completed.
- Under the hood: runs `./scripts/gitops/render-platform-infra.sh staging` against the pinned wrapper charts and `values-staging.yaml`.
- Success looks like: Helm emits clean YAML for the staged Istio and Prometheus applications using the canonical staging value set.
- Run next: `mise run k8s-validate-overlays`.

## Related references

- [Configuration and environment variables](configuration.md)
- [Troubleshooting](troubleshooting.md)
- [Operations overview](../operations/overview.md)
- [Monitoring](../operations/monitoring.md)
