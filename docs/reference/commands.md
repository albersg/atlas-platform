# Command Reference

`mise.toml` is the source of truth for project commands. This page explains the
most important tasks, which repo files own them, and what really happens when you
run them.

For a cross-cutting view of tools, ownership, and configuration, use the
[tool ownership matrix](tool-ownership-matrix.md). For variables mentioned here,
use [configuration and environment variables](configuration.md).

## How to use this page without reading all of it

| If you are trying to... | Jump to this section |
| --- | --- |
| get a machine ready for repo work | [Setup and environment](#setup-and-environment) |
| understand validation, tests, or docs commands | [Quality, tests, and docs](#quality-tests-and-docs) |
| run the app locally | [Application development](#application-development) |
| learn local k3s and non-GitOps cluster commands | [Kubernetes and cluster flows](#kubernetes-and-cluster-flows) |
| understand staged GitOps deployment and Argo CD commands | [GitOps and Argo CD](#gitops-and-argo-cd) |

If you are still learning the tool names, read the
[tooling primer](../getting-started/tooling-primer.md) first. This page is the
"tell me exactly what the command does" reference.

## How commands compose in this repo

Atlas Platform uses a layered command model:

1. `mise` gives the repo one stable command surface,
2. each `mise run ...` task wraps real tools or scripts,
3. repo-owned scripts under `scripts/` encode the platform workflow,
4. GitHub Actions reuses the same contracts for CI, release, and promotion.

That means most commands are not isolated. They are deliberate entry points into a
larger workflow.

## Tool ownership behind the commands

| Tool | What it is for | Primary owner in this repo | Main configuration surfaces | Common commands |
| --- | --- | --- | --- | --- |
| `mise` | pinned toolchain and task runner | `mise.toml` | `mise.toml`, `mise.lock` | almost every `mise run ...` command |
| `pre-commit` | shared lint, formatting, policy, and security hook runner | repo quality layer | `.pre-commit-config.yaml` | `bootstrap`, `fmt`, `lint`, `security` |
| `uv` | backend dependency and Python command runner | backend service workflow | `mise.toml`, `services/inventory-service/pyproject.toml` | `app-bootstrap`, `backend-*`, `test`, `typecheck` |
| `npm` and Vite | frontend install, dev server, build, and typecheck | `apps/web` | `apps/web/package.json` | `app-bootstrap`, `frontend-dev`, `frontend-build`, `frontend-typecheck` |
| Docker and Compose | full local stack and image builds | local app workflow | `docker-compose.yml`, Dockerfiles, `scripts/compose/require-compose.sh` | `compose-up`, `compose-down`, `compose-logs`, image-build tasks |
| `kubectl` and k3s | direct cluster access and local Kubernetes runtime | cluster operations layer | `scripts/k3s/**` | `k8s-*` commands |
| Helm | reusable workload and infra packaging | platform packaging layer | `platform/helm/**`, `scripts/gitops/render-platform-infra.sh` | `gitops-render-platform-infra-*`, `k8s-validate-overlays` |
| Kustomize and KSOPS | environment overlays and encrypted manifest rendering | workload and env overlay layer | `platform/k8s/**`, `.gitops-local/xdg/kustomize/plugin/.../ksops` | `gitops-render-*`, `k8s-validate-overlays` |
| Argo CD | GitOps reconciliation | staging deployment layer | `platform/argocd/apps/**`, `scripts/gitops/bootstrap/*.sh` | `gitops-bootstrap-core`, `gitops-apply-*`, `gitops-deploy-staging`, `gitops-wait-staging` |
| SOPS and age | encrypted secrets in Git | secure overlay layer | encrypted overlays plus local `.gitops-local/age/keys.txt` | bootstrap, render, validation, promotion |
| Kyverno | policy validation of rendered manifests | policy layer | `platform/policy/kyverno/**` | `k8s-validate-overlays`, `policy-check`, `ci` |
| Istio | staged ingress and service mesh runtime | platform infra layer | `platform/helm/istio/**`, `platform/k8s/components/mesh/istio/**` | staged deploy, render, validation, smoke |
| Prometheus | staged monitoring stack | platform infra plus workload observability split | `platform/helm/prometheus/**`, `platform/k8s/components/observability/prometheus/**` | staged deploy, render, status, smoke |
| Trivy, Syft, Cosign | release security, SBOM, and trusted-image verification | release and promotion layer | `.github/workflows/release-images.yml`, `scripts/release/verify-trusted-images.sh` | release workflow, promotion workflow, canonical staging verification |

## Setup and environment

### `mise run doctor`

- Purpose: show general `mise` diagnostics plus repository Kubernetes and GitOps readiness.
- Owned by: `[tasks.doctor]` in `mise.toml` and `scripts/k3s/cluster/doctor.sh`.
- Under the hood: runs `mise doctor`, validates task definitions, then runs the repo-specific doctor script.
- Composition: the doctor script checks basic tools first, then staging-specific helpers, then cluster prerequisites, then live Argo CD, Istio, Prometheus, and workload presence.
- Useful variable: `ATLAS_DOCTOR_SCOPE=dev` gives a lighter check than the default staging-oriented scope.
- Success looks like: no blocking prereq failures and a final "ready" message for the chosen scope.
- Run next: `mise run bootstrap`, `mise run app-bootstrap`, or the missing setup step it pointed out.

### `mise run bootstrap`

- Purpose: install repo Git hooks.
- Owned by: `[tasks.bootstrap]` in `mise.toml`.
- Under the hood: runs `pre-commit install --install-hooks --hook-type pre-commit --hook-type pre-push`.
- Composition: this makes later `git commit`, `git push`, `mise run fmt`, and `mise run lint` use the same hook ecosystem.
- Success looks like: pre-commit reports installed hooks.
- Run next: `mise run app-bootstrap`.

### `mise run app-bootstrap`

- Purpose: install backend and frontend dependencies.
- Owned by: `[tasks.app-bootstrap]` in `mise.toml`.
- Under the hood: runs `uv sync --extra dev` inside `services/inventory-service` and `npm install` inside `apps/web`.
- Composition: this prepares every later backend, frontend, test, docs, and quality command except the separate GitOps helper installer.
- Success looks like: Python lock-resolved deps and Node modules install cleanly.
- Run next: your local development loop or validation commands.

## Quality, tests, and docs

### `mise run fmt`

- Purpose: apply safe formatter-style fixes before linting.
- Owned by: `[tasks.fmt]` in `mise.toml`.
- Under the hood: runs selected manual `pre-commit` hooks for whitespace, line endings, `shfmt`, and `ruff format`.
- Composition: intentionally smaller than full lint; it fixes low-risk issues so `lint` can focus on problems that need attention.
- Success looks like: files are updated or reported clean.
- Run next: `mise run lint`.

### `mise run fmt-check`

- Purpose: prove formatting is already clean.
- Owned by: `[tasks.fmt-check]` in `mise.toml`.
- Under the hood: runs `mise run fmt`, then `git diff --exit-code`.
- Composition: mirrors CI behavior by allowing the same formatters to act, then asserting they had nothing left to change.
- Success looks like: no remaining diff.
- Run next: `mise run check` or `mise run ci`.

### `mise run lint`

- Purpose: run the full hook-based lint, policy, and docs-quality path.
- Owned by: `[tasks.lint]` in `mise.toml` plus `.pre-commit-config.yaml`.
- Under the hood: validates the pre-commit config, then retries `pre-commit run --all-files --show-diff-on-failure` up to `MISE_LINT_MAX_TRIES`.
- Composition: this is where `markdownlint`, `yamllint`, `ruff`, `shellcheck`, repository policy hooks, and other shared checks actually live.
- Why the retry loop exists: some hooks legitimately modify files on an earlier pass, so the task reruns until the tree stabilizes or the retry cap is hit.
- Success looks like: every hook passes and no more auto-fixes appear.
- Run next: `mise run typecheck`.

### `mise run security`

- Purpose: run the focused security subset without the full CI bundle.
- Owned by: `[tasks.security]` in `mise.toml` and security hooks in `.pre-commit-config.yaml`.
- Under the hood: runs private-key detection, `detect-secrets`, `gitleaks`, workflow checks, and `zizmor`.
- Composition: complements `lint`; some security checks are severe enough to deserve their own explicit task and their own place in `ci`.
- Success looks like: no secret leaks, unsafe workflow patterns, or blocked GitHub Actions issues.
- Run next: `mise run ci` if you are preparing PR-bound work.

### `mise run test`

- Purpose: run repository policy tests and backend unit tests.
- Owned by: `[tasks.test]` in `mise.toml`.
- Under the hood: runs `python -m unittest discover -s tests -p 'test_*.py' -v`, then `uv run --project services/inventory-service --extra dev pytest services/inventory-service/tests/unit`.
- Composition: combines repo-level policy assertions with backend service behavior in one command.
- Beginner mental model: the first half tests repository contracts; the second half tests `inventory-service` itself.
- Success looks like: both suites pass.
- Run next: `mise run docs-build` or `mise run check`.

### `mise run backend-test-cov`

- Purpose: run the full backend test tree with coverage-oriented output.
- Owned by: `[tasks.backend-test-cov]` in `mise.toml`.
- Under the hood: runs backend `pytest` over `services/inventory-service/tests` through `uv`.
- Composition: deeper than `mise run backend-test`, useful when backend work goes beyond the fastest path.
- Success looks like: backend tests pass across the whole service suite.
- Run next: `mise run backend-typecheck` or broader validation.

### `mise run backend-typecheck`

- Purpose: static type checking for the backend.
- Owned by: `[tasks.backend-typecheck]` in `mise.toml` and the backend project config.
- Under the hood: runs `uv run --project services/inventory-service --extra dev pyright`.
- Composition: also appears as a pre-push hook and inside `mise run typecheck`.
- Success looks like: no `pyright` errors.
- Run next: `mise run test`.

### `mise run typecheck`

- Purpose: run all static type checks in one place.
- Owned by: `[tasks.typecheck]` in `mise.toml`.
- Under the hood: runs `mise run backend-typecheck` and `mise run frontend-typecheck`.
- Composition: gives one stable command even though backend and frontend use different underlying tools.
- Success looks like: both backends of the monorepo are type-clean.
- Run next: `mise run test`.

### `mise run docs-build`

- Purpose: build the docs site in strict mode.
- Owned by: `[tasks.docs-build]` in `mise.toml` and docs nav in `mkdocs.yml`.
- Under the hood: runs `uvx --from mkdocs==1.6.1 --with mkdocs-material==9.6.18 mkdocs build --strict`.
- Composition: validates page references, nav entries, and broken links without needing a long-lived local virtualenv.
- Success looks like: MkDocs completes with no strict-mode failures.
- Run next: `mise run check` or `mise run ci`.

### `mise run docs-serve`

- Purpose: preview the docs locally while editing.
- Owned by: `[tasks.docs-serve]` in `mise.toml`.
- Under the hood: runs `mkdocs serve -a 0.0.0.0:8001` through pinned `uvx` packages.
- Composition: pairs naturally with `docs-build`; use serve for iteration and build for strict validation.
- Success looks like: a docs server on port `8001`.
- Run next: refresh the browser while editing, then finish with `mise run docs-build`.

### `mise run check`

- Purpose: run the standard grouped local validation path.
- Owned by: `[tasks.check]` in `mise.toml`.
- Under the hood: runs `lint`, `typecheck`, `frontend-build`, and `test`.
- Composition: this is the core "is my code safe locally?" bundle, but it does not include docs or full platform validation.
- Success looks like: core code-quality, type, build, and test paths all pass.
- Run next: `mise run docs-build`, then `mise run ci` for PR-grade confidence.

### `mise run ci`

- Purpose: approximate the full CI pipeline locally.
- Owned by: `[tasks.ci]` in `mise.toml`.
- Under the hood: runs `fmt-check`, `check`, `k8s-validate-overlays`, `docs-build`, and `security`.
- Composition: this is where application quality, docs quality, platform manifest validation, and security checks finally meet.
- Beginner mental model: `ci` is the repo's "full dress rehearsal" command.
- Success looks like: your local result should closely match what GitHub Actions expects.
- Run next: open a pull request or investigate the failing stage.

## Application development

### `mise run backend-dev`

- Purpose: run the backend locally with reload.
- Owned by: `[tasks.backend-dev]` in `mise.toml`.
- Under the hood: starts Uvicorn inside `services/inventory-service` on port `8000`.
- Composition: usually paired with local PostgreSQL or Compose; reads backend runtime settings from the `INVENTORY_...` env contract.
- Success looks like: backend reachable on `http://localhost:8000`.
- Run next: `mise run backend-test` or `mise run backend-migrate`.

### `mise run backend-migrate`

- Purpose: apply Alembic migrations.
- Owned by: `[tasks.backend-migrate]` in `mise.toml`.
- Under the hood: runs `alembic upgrade head` inside the backend project.
- Composition: uses the same `INVENTORY_DATABASE_URL` contract as the service runtime and migration job.
- Success looks like: Alembic reaches head cleanly.
- Run next: rerun the backend or tests that depend on the new schema.

### `mise run backend-test`

- Purpose: run the backend test suite quickly.
- Owned by: `[tasks.backend-test]` in `mise.toml`.
- Under the hood: runs `pytest -q` inside `services/inventory-service`.
- Composition: a faster backend-only loop than the repo-wide `test` task.
- Success looks like: backend tests pass.
- Run next: `mise run backend-test-cov` or grouped validation.

### `mise run frontend-dev`

- Purpose: run the frontend Vite dev server.
- Owned by: `[tasks.frontend-dev]` in `mise.toml` and `apps/web/package.json`.
- Under the hood: runs `npm run dev` in `apps/web`.
- Composition: pairs with `backend-dev` for split local work or with Compose for a fuller stack.
- Success looks like: hot-reload frontend server is reachable.
- Run next: `mise run frontend-build` or `mise run frontend-typecheck`.

### `mise run frontend-build`

- Purpose: build the production frontend bundle.
- Owned by: `[tasks.frontend-build]` in `mise.toml` and `apps/web/package.json`.
- Under the hood: runs `vite build`.
- Composition: appears inside `mise run check`, so frontend buildability is part of the standard validation path.
- Success looks like: Vite emits a production build without errors.
- Run next: `mise run check` or `mise run ci`.

### `mise run frontend-typecheck`

- Purpose: static type checking for the frontend.
- Owned by: `[tasks.frontend-typecheck]` in `mise.toml` and `apps/web/package.json`.
- Under the hood: runs `npm run typecheck`.
- Composition: bundled into `mise run typecheck`.
- Success looks like: no TypeScript errors.
- Run next: `mise run frontend-build`.

### `mise run compose-up`

- Purpose: start the full local app stack with Docker Compose.
- Owned by: `[tasks.compose-up]` in `mise.toml`, `docker-compose.yml`, and `scripts/compose/require-compose.sh`.
- Under the hood: runs Compose `up --build -d` through the wrapper script.
- Composition: uses containerized PostgreSQL, backend, and web services with the same `INVENTORY_DATABASE_URL` contract as other environments.
- Success looks like: PostgreSQL becomes healthy, then backend, then web.
- Run next: `mise run compose-logs` or manual browser/API testing.

### `mise run compose-down`

- Purpose: stop the Compose stack.
- Owned by: `[tasks.compose-down]` in `mise.toml`.
- Under the hood: runs Compose `down` through the wrapper.
- Composition: cleanly unwinds the local stack created by `compose-up`.
- Success looks like: containers stop and resources are released.
- Run next: another local workflow if needed.

### `mise run compose-logs`

- Purpose: inspect full-stack Compose logs.
- Owned by: `[tasks.compose-logs]` in `mise.toml`.
- Under the hood: tails Compose logs with `-f --tail=200`.
- Composition: the first command to reach for when Compose health checks fail.
- Success looks like: readable logs from PostgreSQL, backend, and web.
- Run next: fix the underlying issue or continue testing.

## Kubernetes and cluster flows

### `mise run k8s-preflight`

- Purpose: validate local k3s prerequisites before the `dev` path.
- Owned by: `[tasks.k8s-preflight]` in `mise.toml` and `scripts/k3s/cluster/preflight.sh`.
- Under the hood: runs repo-owned cluster capability checks.
- Composition: intended for the simpler `dev` overlay, before the heavier GitOps staging toolchain matters.
- Success looks like: the cluster is ready for repo-managed Kubernetes workflows.
- Run next: `mise run k8s-build-images`.

### `mise run k8s-doctor`

- Purpose: check repository-specific Kubernetes and GitOps readiness.
- Owned by: `[tasks.k8s-doctor]` in `mise.toml` and `scripts/k3s/cluster/doctor.sh`.
- Under the hood: verifies tools, local files like `.gitops-local/age/keys.txt`, Argo CD credentials, render preflight, and live infra namespaces and apps.
- Composition: it bridges static readiness and live-cluster health, which is why it matters before any serious staged work.
- Success looks like: both prerequisites and operational checks pass for the requested scope.
- Run next: `mise run k8s-validate-overlays` or the relevant deploy command.

### `mise run k8s-build-images` -> `mise run k8s-import-images` -> `mise run k8s-deploy-dev`

- Purpose: the full `dev` deployment chain.
- Owned by: `[tasks.k8s-build-images]`, `[tasks.k8s-import-images]`, `[tasks.k8s-deploy-dev]` in `mise.toml` plus `scripts/k3s/images/*.sh` and `scripts/k3s/deploy/dev.sh`.
- Under the hood:
  - `k8s-build-images` builds local backend and frontend images and records refs,
  - `k8s-import-images` imports them into k3s containerd,
  - `k8s-deploy-dev` applies the `dev` overlay and then runs smoke checks.
- Composition: `dev` is the non-GitOps Kubernetes learning layer; it uses Kustomize and local images, but not the full staged Argo CD + Istio + Prometheus topology.
- Success looks like: healthy workloads in `atlas-platform-dev` plus successful smoke checks.
- Run next: `mise run k8s-status` and `mise run k8s-access`.

### `mise run k8s-smoke`

- Purpose: rerun smoke checks against `dev`.
- Owned by: `[tasks.k8s-smoke]` in `mise.toml` and `scripts/k3s/verify/smoke.sh`.
- Under the hood: checks workload availability, port-forwards backend and web, and hits readiness, API, metrics, and ingress URLs.
- Composition: uses a lighter path than staged smoke because `dev` stays on Traefik rather than Istio.
- Success looks like: all URL probes succeed.
- Run next: fix runtime issues if any step fails.

### `mise run k8s-smoke-staging`

- Purpose: rerun smoke checks against `staging` or `staging-local`.
- Owned by: `[tasks.k8s-smoke-staging]` in `mise.toml` and `scripts/k3s/verify/smoke.sh`.
- Under the hood: waits for workload availability, verifies sidecar readiness in staged envs, validates migration-job behavior, then probes internal services and ingress hostnames.
- Composition: it is mesh-aware and respects `ATLAS_STAGING_INGRESS_SCHEME`, `ATLAS_STAGING_LOCAL_INGRESS_SCHEME`, and local NodePort settings.
- Success looks like: backend readiness, API list, metrics, frontend, and hostname ingress probes all pass.
- Run next: `mise run k8s-status-staging` or operator troubleshooting.

### `mise run k8s-status` and `mise run k8s-status-staging`

- Purpose: show workload status for `dev` or staged environments.
- Owned by: `[tasks.k8s-status]`, `[tasks.k8s-status-staging]` in `mise.toml` and `scripts/k3s/cluster/status.sh`.
- Under the hood: queries deployments, statefulsets, pods, jobs, PVCs, HPAs, services, and ingress-like surfaces; the staging version also includes mesh and monitoring context.
- Composition: the fastest "what is actually running?" command after a deploy or failed wait.
- Success looks like: readable workload and service state that matches the intended environment.
- Run next: `mise run k8s-access*` or deeper troubleshooting.

### `mise run k8s-access` and `mise run k8s-access-staging`

- Purpose: print the hostnames, URLs, and `/etc/hosts` mapping you need to reach the environment.
- Owned by: `[tasks.k8s-access]`, `[tasks.k8s-access-staging]` in `mise.toml` and `scripts/k3s/cluster/access.sh`.
- Under the hood: reads the node IP and, for staged environments, detects whether the Istio ingress service is exposing NodePorts.
- Composition: this is the human-facing companion to smoke checks; it translates cluster details into concrete URLs.
- Success looks like: immediate browser and API URLs plus port-forward fallbacks.
- Run next: manual verification.

### `mise run k8s-delete-dev`

- Purpose: delete the `dev` overlay resources.
- Owned by: `[tasks.k8s-delete-dev]` in `mise.toml`.
- Under the hood: renders the `dev` overlay and pipes it to `kubectl delete -f - --ignore-not-found`.
- Composition: deletes by the same rendered source of truth used to create the environment.
- Success looks like: `dev` resources are removed.
- Run next: rebuild and redeploy when needed.

### `mise run k8s-delete-staging`

- Purpose: safely tear down GitOps-managed staging.
- Owned by: `[tasks.k8s-delete-staging]` in `mise.toml` and `scripts/gitops/delete-staging.sh`.
- Under the hood: enforces an explicit confirmation token, removes the Argo CD Application first, and preserves namespace and PVCs by default.
- Composition: protects GitOps state and persistent data better than a blunt `kubectl delete namespace` would.
- Success looks like: workloads disappear without accidental storage loss.
- Run next: only redeploy if you truly mean to recreate staging.

### `mise run k8s-backup-postgres-staging` and `mise run k8s-restore-postgres-staging`

- Purpose: back up or restore staging PostgreSQL safely.
- Owned by: `[tasks.k8s-backup-postgres-staging]`, `[tasks.k8s-restore-postgres-staging]` in `mise.toml` plus `scripts/k3s/postgres/*.sh`.
- Under the hood:
  - backup resolves the PostgreSQL environment, renders a helper job or uses exec transport, produces a `.dump`, and prints a restore hint,
  - restore requires `BACKUP_FILE` and `ATLAS_CONFIRM_POSTGRES_RESTORE`, performs the restore, reapplies the overlay, reruns the migration job, and finishes with smoke checks.
- Composition: these commands are intentionally coupled to workload reapply and smoke validation so data operations do not stop at "job finished".
- Success looks like: a timestamped dump for backup, or a restored-and-validated environment for restore.
- Run next: store the dump path safely or inspect the restored app state.

### `mise run k8s-validate-overlays`

- Purpose: validate rendered overlays and infra surfaces before rollout.
- Owned by: `[tasks.k8s-validate-overlays]` in `mise.toml` and `scripts/gitops/validate-overlays.sh`.
- Under the hood:
  - installs local GitOps helpers if needed,
  - renders `dev`, `staging`, and `staging-local` workload overlays,
  - renders platform-infra Helm outputs for `staging` and `staging-local`,
  - combines staged workload and infra surfaces,
  - applies Kyverno common and staging-only policies,
  - asserts `ServiceMonitor` and `/metrics` presence in staged outputs,
  - verifies trusted images,
  - schema-checks with kubeconform,
  - runs `istioctl analyze`.
- Composition: this is the single richest DevSecOps command in the repo because it crosses workload, platform, policy, trust, and mesh boundaries.
- Success looks like: every non-production surface renders and validates cleanly.
- Run next: staged deployment or `mise run ci`.

### `mise run policy-check`

- Purpose: a semantically named alias for overlay validation.
- Owned by: `[tasks.policy-check]` in `mise.toml`.
- Under the hood: runs the same script as `k8s-validate-overlays`.
- Composition: useful when you want to emphasize policy validation rather than the broader platform render story.
- Success looks like: same as `k8s-validate-overlays`.
- Run next: deployment or CI.

## GitOps and Argo CD

### `mise run gitops-install-tools`

- Purpose: install the repo-local GitOps helper binaries.
- Owned by: `[tasks.gitops-install-tools]` in `mise.toml` and `scripts/gitops/bootstrap/install-tools.sh`.
- Under the hood: downloads pinned `age`, `sops`, `argocd`, `kustomize`, `ksops`, `kyverno`, `cosign`, `helm`, and `istioctl` into `.gitops-local/bin` and wires the KSOPS plugin path.
- Composition: this intentionally keeps heavy GitOps helper versioning out of the top-level `mise` tool list so platform tooling has one repo-local source of truth.
- Success looks like: helper binaries exist in `.gitops-local/bin`.
- Run next: `mise run gitops-bootstrap-core`.

### `mise run gitops-bootstrap-core`

- Purpose: install Argo CD core and KSOPS into the current cluster.
- Owned by: `[tasks.gitops-bootstrap-core]` in `mise.toml` and `scripts/gitops/bootstrap/install-argocd.sh`.
- Under the hood: installs the repo-pinned Argo CD core manifest and the KSOPS support needed for encrypted overlays.
- Composition: creates the cluster-side half of the GitOps toolchain that `gitops-install-tools` only installs locally.
- Success looks like: the `argocd` namespace and core deployment are present.
- Run next: install the age key and repository credential.

### `mise run gitops-install-age-key`

- Purpose: install the local SOPS age key into `argocd`.
- Owned by: `[tasks.gitops-install-age-key]` in `mise.toml` and `scripts/gitops/bootstrap/install-age-key-secret.sh`.
- Under the hood: reads local age key material and creates `argocd-sops-age-key`.
- Composition: gives Argo CD and KSOPS the same decryption capability your local render path needs.
- Success looks like: `argocd-sops-age-key` exists.
- Run next: `mise run gitops-install-repo-credential`.

### `mise run gitops-install-repo-credential`

- Purpose: install the repository deploy credential for Argo CD.
- Owned by: `[tasks.gitops-install-repo-credential]` in `mise.toml` and `scripts/gitops/bootstrap/install-repo-credential.sh`.
- Under the hood: creates the Argo CD repo secret from the local deploy key.
- Composition: completes the two cluster-side prerequisites for GitOps: decrypt secrets and read the repo.
- Success looks like: the repo credential secret exists in `argocd`.
- Run next: `mise run gitops-apply-apps`.

### `mise run gitops-apply-apps`

- Purpose: apply the full staging application bundle.
- Owned by: `[tasks.gitops-apply-apps]` in `mise.toml` and `scripts/gitops/bootstrap/apply-apps.sh`.
- Under the hood: applies the Atlas workload project, the platform-infra project, the four infra applications, and the staging workload application; patches the workload path and target revision when requested; patches infra apps to use `values-staging-local.yaml` or `values-staging.yaml`.
- Composition: this is the pivot point where GitOps metadata is shaped for either local rehearsal or canonical staging.
- Success looks like: Argo CD applications exist with the expected target path, revision, and value files.
- Run next: `mise run gitops-wait-staging` or `mise run gitops-deploy-staging`.

### `mise run gitops-apply-staging`

- Purpose: apply only the staging workload application.
- Owned by: `[tasks.gitops-apply-staging]` in `mise.toml`.
- Under the hood: runs `scripts/gitops/bootstrap/apply-staging-app.sh`.
- Composition: narrower than `gitops-apply-apps`, useful when troubleshooting the workload app without reapplying the whole bundle.
- Success looks like: the staging application exists or is refreshed.
- Run next: `mise run gitops-wait-staging`.

### `mise run gitops-wait-staging`

- Purpose: wait for the staging application to converge.
- Owned by: `[tasks.gitops-wait-staging]` in `mise.toml` and `scripts/gitops/wait-app.sh`.
- Under the hood: polls Argo CD Application sync, health, and operation-state fields every five seconds until the timeout expires.
- Composition: only waits for the workload app; it does not automatically sequence the full infra app set first.
- Success looks like: `atlas-platform-staging` reaches `Synced` and `Healthy`.
- Run next: `mise run k8s-status-staging` or `mise run k8s-smoke-staging`.

### `mise run gitops-deploy-staging`

- Purpose: run the full staged deployment workflow.
- Owned by: `[tasks.gitops-deploy-staging]` in `mise.toml` and `scripts/gitops/deploy/staging.sh`.
- Under the hood, in order:
  1. decides between `staging-local` and canonical `staging` based on `STAGING_LOCAL_IMAGES`,
  2. for `staging-local`, builds and imports local `:main` images,
  3. runs `ATLAS_DOCTOR_SCOPE=staging` doctor checks,
  4. for canonical staging, verifies trusted images first,
  5. proves Argo CD, age key, and repo credential exist,
  6. applies the Argo CD app bundle,
  7. waits for `atlas-platform-istio-base`, `atlas-platform-istiod`, `atlas-platform-istio-ingress`, and `atlas-platform-prometheus`,
  8. restarts the ingress deployment once if pods still show `image=auto`,
  9. waits for `atlas-platform-staging`,
  10. for `staging-local`, restarts workloads so mutable local images are actually reloaded,
  11. prints status,
  12. runs mesh-aware smoke checks.
- Composition: this is the repo's most complete operational command because it ties together doctor checks, Argo CD, infra ordering, image trust, workload sync, and runtime verification.
- Success looks like: infra apps, workload app, and smoke checks all pass.
- Run next: `mise run k8s-status-staging` and `mise run k8s-access-staging`.

### `mise run gitops-render-dev` and `mise run gitops-render-staging`

- Purpose: render encrypted workload overlays locally.
- Owned by: `[tasks.gitops-render-dev]`, `[tasks.gitops-render-staging]` in `mise.toml` and `scripts/gitops/render-overlay.sh`.
- Under the hood: runs the KSOPS/Kustomize render path for the chosen overlay.
- Composition: useful for debugging workload manifests without touching the cluster.
- Success looks like: clean YAML output.
- Run next: `mise run k8s-validate-overlays`.

### `mise run gitops-render-platform-infra-staging-local` and `mise run gitops-render-platform-infra-staging`

- Purpose: render the staged platform-infra Helm inputs deterministically.
- Owned by: `[tasks.gitops-render-platform-infra-*]` in `mise.toml` and `scripts/gitops/render-platform-infra.sh`.
- Under the hood: installs local helpers if needed, registers upstream Helm repos, then templates the repo-owned wrapper charts for Istio base, Istiod, gateway, and Prometheus using `values-common.yaml` plus the chosen environment-specific values file.
- Composition: this is how the repo keeps platform infra chart rendering deterministic before Argo CD ever touches the cluster.
- Success looks like: Helm emits clean YAML for every staged infra add-on.
- Run next: `mise run k8s-validate-overlays` or staged deployment.

## Related references

- [Configuration and environment variables](configuration.md)
- [Tool ownership matrix](tool-ownership-matrix.md)
- [Quality and CI](../development/quality-and-ci.md)
- [Troubleshooting](troubleshooting.md)
- [Monitoring](../operations/monitoring.md)
