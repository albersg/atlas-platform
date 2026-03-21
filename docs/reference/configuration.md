# Configuration And Environment Variables

This page maps the most important runtime and operator-facing variables to the
real files and scripts that use them. Use it together with the
[command reference](commands.md) and the
[tool ownership matrix](tool-ownership-matrix.md).

## How configuration is layered

Atlas Platform has four main configuration layers:

1. application runtime variables for the backend and frontend,
2. local workflow variables for `mise`, `pre-commit`, and Docker-based work,
3. GitOps and staging variables that shape Argo CD, Helm, Kustomize, and smoke checks,
4. safety and recovery variables that gate destructive operations.

When you are unsure where a variable belongs, ask two questions:

- does it change application behavior, or only operator workflow?
- is it read by app code, or by a script under `scripts/`?

## Backend runtime

Primary owner in this repo:

- application config model in `services/inventory-service/src/inventory_service/shared/config.py`
- Kubernetes wiring in `platform/helm/atlas/workloads/templates/inventory-service.yaml`
- Compose wiring in `docker-compose.yml`

| Variable | Used by | Default or role | Where configured in this repo | How it composes |
| --- | --- | --- | --- | --- |
| `INVENTORY_APP_NAME` | backend app settings | `inventory-service` | `services/inventory-service/src/inventory_service/shared/config.py` | Pure app metadata; currently not injected by Kubernetes templates. |
| `INVENTORY_APP_ENV` | backend app settings and staged config map | `dev` | default in `services/inventory-service/src/inventory_service/shared/config.py`; injected from `platform/helm/atlas/workloads/templates/configmap.yaml` | Connects app runtime to environment overlays without hard-coding env names into the container image. |
| `INVENTORY_DATABASE_URL` | backend app, migrations, Compose, Kubernetes secrets | local PostgreSQL URL by default | `services/inventory-service/src/inventory_service/shared/config.py`, `docker-compose.yml`, `platform/helm/atlas/workloads/templates/inventory-service.yaml`, `platform/helm/atlas/workloads/templates/inventory-migration-job.yaml` | Shared by the API and migration job so schema and runtime stay on the same database contract. |
| `INVENTORY_SENTRY_DSN` | backend observability | optional | `services/inventory-service/src/inventory_service/shared/config.py` | Enables backend error reporting only when explicitly provided. |
| `INVENTORY_SENTRY_TRACES_SAMPLE_RATE` | backend observability | `0.0` | `services/inventory-service/src/inventory_service/shared/config.py` | Lets tracing stay disabled by default while keeping the same runtime shape in every environment. |

Important note: the Helm workload templates also inject `RUN_MIGRATIONS_ON_STARTUP`
from `platform/helm/atlas/workloads/templates/configmap.yaml`, but that is a
chart-owned platform setting rather than an application `BaseSettings` variable.

## Frontend runtime

Primary owner in this repo:

- Vite env typing in `apps/web/src/vite-env.d.ts`
- Sentry initialization in `apps/web/src/shared/observability/sentry.ts`

| Variable | Used by | Role | Where configured in this repo | How it composes |
| --- | --- | --- | --- | --- |
| `VITE_SENTRY_DSN` | frontend Sentry bootstrap | optional Sentry DSN | `apps/web/src/vite-env.d.ts`, `apps/web/src/shared/observability/sentry.ts` | If unset, Sentry does not initialize at all. |
| `VITE_SENTRY_ENVIRONMENT` | frontend Sentry bootstrap | environment label | `apps/web/src/shared/observability/sentry.ts` | Falls back to `import.meta.env.MODE`, so Vite mode and Sentry environment stay aligned unless overridden. |
| `VITE_SENTRY_TRACES_SAMPLE_RATE` | frontend Sentry bootstrap | tracing sample rate string parsed into a number | `apps/web/src/shared/observability/sentry.ts` | Mirrors the backend tracing pattern: disabled by default, explicit when needed. |

## Local workflow and validation

Primary owner in this repo:

- task definitions in `mise.toml`
- hook definitions in `.pre-commit-config.yaml`

| Variable | Used by | Default or role | Where configured in this repo | Which commands use it |
| --- | --- | --- | --- | --- |
| `MISE_LINT_MAX_TRIES` | `mise` lint retry loop | `3` | `mise.toml` under `[tasks.lint]` | `mise run lint`, then indirectly `mise run check` and `mise run ci` |
| `ATLAS_VALIDATE_PREFLIGHT` | overlay validation preflight mode | `0` | `scripts/gitops/validate-overlays.sh` | `mise run k8s-doctor` sets it internally; you can set it manually while debugging render readiness |

`ATLAS_VALIDATE_PREFLIGHT=1` is useful when you want to confirm rendering and
policy bundle assembly without running the full Kyverno, Cosign, kubeconform,
and `istioctl analyze` path.

## GitOps and staging deployment

Primary owner in this repo:

- staging deploy wrapper in `scripts/gitops/deploy/staging.sh`
- Argo CD application patching in `scripts/gitops/bootstrap/apply-apps.sh`
- Argo CD wait loop in `scripts/gitops/wait-app.sh`

| Variable | Used by | Default or role | Where configured in this repo | How it composes |
| --- | --- | --- | --- | --- |
| `STAGING_LOCAL_IMAGES` | staging deployment mode switch | `1` | `scripts/gitops/deploy/staging.sh` | Chooses `staging-local` rehearsal behavior vs canonical `staging` digest behavior. |
| `ARGOCD_APP_REVISION` | Argo CD app patching | optional branch or commit | `scripts/gitops/bootstrap/apply-apps.sh` | Lets you validate a remote branch or commit without changing committed app manifests. |
| `ARGOCD_APP_PATH` | Argo CD app patching | optional overlay path | `scripts/gitops/bootstrap/apply-apps.sh`; set internally by `scripts/gitops/deploy/staging.sh` | Switches the staging app between `platform/k8s/overlays/staging-local` and `platform/k8s/overlays/staging`. |
| `ARGOCD_ENVIRONMENT` | infra values selection | derived from app path unless set | `scripts/gitops/bootstrap/apply-apps.sh`; set internally by `scripts/gitops/deploy/staging.sh` | Ensures infra apps use `values-staging-local.yaml` or `values-staging.yaml` consistently. |
| `ARGOCD_WAIT_TIMEOUT_SECONDS` | app wait timeout | `600` | `scripts/gitops/deploy/staging.sh` | Governs how long staged app sync waits before surfacing a failure. |
| `ARGOCD_REPO_SECRET_NAME` | repo credential lookup | `argocd-repo-atlas-platform` | `scripts/gitops/deploy/staging.sh` | Lets operators use a non-default Argo CD repository secret name if needed. |
| `STAGING_NAMESPACE` | staging namespace override | `atlas-platform-staging` | `scripts/gitops/deploy/staging.sh` | Keeps deploy, status, and smoke logic pointed at the same namespace. |

## Ingress, access, and smoke checks

Primary owner in this repo:

- smoke verifier in `scripts/k3s/verify/smoke.sh`
- access helper in `scripts/k3s/cluster/access.sh`

| Variable | Used by | Default or role | Where configured in this repo | Which commands use it |
| --- | --- | --- | --- | --- |
| `ATLAS_STAGING_INGRESS_SCHEME` | canonical staging smoke and access URLs | `http` | `scripts/k3s/verify/smoke.sh`, `scripts/k3s/cluster/access.sh` | `mise run k8s-smoke-staging`, `mise run k8s-access-staging` |
| `ATLAS_STAGING_LOCAL_INGRESS_SCHEME` | `staging-local` smoke and access URLs | `http` | `scripts/k3s/verify/smoke.sh`, `scripts/k3s/cluster/access.sh` | `mise run gitops-deploy-staging`, `mise run k8s-smoke-staging`, `mise run k8s-access-staging` |
| `ATLAS_STAGING_LOCAL_HTTP_PORT` | local Istio gateway NodePort | `32080` | `scripts/k3s/verify/smoke.sh`, `scripts/k3s/cluster/access.sh` | Same staged access and smoke commands as above |
| `ATLAS_STAGING_LOCAL_HTTPS_PORT` | reserved local HTTPS NodePort | `32443` | `scripts/k3s/verify/smoke.sh`, `scripts/k3s/cluster/access.sh` | Same staged access and smoke commands as above |
| `ATLAS_DOCTOR_SCOPE` | doctor command scope | `staging` | `scripts/k3s/cluster/doctor.sh` | `mise run doctor`, `mise run k8s-doctor` |

These variables do not change the manifests themselves. They change how the
operator helpers interpret and verify the running environment.

## GitOps bootstrap and secret decryption

Primary owner in this repo:

- local helper installer in `scripts/gitops/bootstrap/install-tools.sh`
- GitHub Actions promotion validation in `.github/workflows/promote-staging.yml`

| Variable | Used by | Role | Where configured in this repo | Which commands or workflows use it |
| --- | --- | --- | --- | --- |
| `SOPS_AGE_KEY` | encrypted overlay validation | age private key material | consumed in `.github/workflows/promote-staging.yml`; local material ends up in `.gitops-local/age/keys.txt` | canonical promotion validation and any manual encrypted-render flow |

Local bootstrap scripts usually materialize age keys into `.gitops-local/age/`
instead of reading `SOPS_AGE_KEY` directly, but the workflow still matters because
CI and promotion need the same decryption capability.

## Trusted image and release verification

Primary owner in this repo:

- release verification script in `scripts/release/verify-trusted-images.sh`
- digest rewrite helper in `scripts/release/promote-by-digest.sh`

| Variable | Used by | Default or role | Where configured in this repo | How it composes |
| --- | --- | --- | --- | --- |
| `ATLAS_REGISTRY_OWNER` | digest promotion and trust verification | `albersg` | `scripts/release/promote-by-digest.sh`, `scripts/release/verify-trusted-images.sh`, `.github/workflows/promote-staging.yml` | Keeps digest rewriting and Cosign verification pointed at the same GHCR namespace. |
| `ATLAS_GITHUB_REPOSITORY` | Cosign identity verification | `${ATLAS_REGISTRY_OWNER}/atlas-platform` | `scripts/release/verify-trusted-images.sh` | Matches image signatures back to the expected GitHub repository identity. |
| `ATLAS_TRUST_WORKFLOW_PATH` | Cosign certificate identity regex | `.github/workflows/release-images.yml` | `scripts/release/verify-trusted-images.sh` | Ties trust verification to the release workflow that is allowed to publish signed images. |
| `ATLAS_TRUST_OIDC_ISSUER` | Cosign certificate issuer | `https://token.actions.githubusercontent.com` | `scripts/release/verify-trusted-images.sh` | Guards against accepting signatures from the wrong OIDC issuer. |
| `ATLAS_TRUST_VERIFY_DRY_RUN` | trust verification dry run | `0` | `scripts/release/verify-trusted-images.sh` | Useful for understanding the exact Cosign verification command before live validation. |

## PostgreSQL backup and restore operations

Primary owner in this repo:

- shared library in `scripts/k3s/postgres/lib.sh`
- backup script in `scripts/k3s/postgres/backup.sh`
- restore script in `scripts/k3s/postgres/restore.sh`

| Variable | Used by | Default or role | Where configured in this repo | Which commands use it |
| --- | --- | --- | --- | --- |
| `ATLAS_POSTGRES_ENV` | backup and restore target env | `staging` | `scripts/k3s/postgres/lib.sh` | `mise run k8s-backup-postgres-staging`, `mise run k8s-restore-postgres-staging` |
| `ATLAS_POSTGRES_DRY_RUN` | non-destructive backup or restore rehearsal | `0` | `scripts/k3s/postgres/lib.sh`, `scripts/k3s/postgres/restore.sh`, `scripts/k3s/postgres/backup.sh` | Same backup and restore commands |
| `ATLAS_POSTGRES_TRANSPORT` | backup/restore data transport mode | `job` | `scripts/k3s/postgres/lib.sh` | Same backup and restore commands |
| `ATLAS_POSTGRES_KEEP_JOBS` | keep helper jobs for debugging | `0` | `scripts/k3s/postgres/lib.sh` | Same backup and restore commands |
| `ATLAS_POSTGRES_BACKUP_ROOT` | local backup root directory | `.gitops-local/backups` | `scripts/k3s/postgres/lib.sh` | backup and restore helpers |
| `ATLAS_POSTGRES_BACKUP_DIR` | environment-specific backup output dir | derived from root and env | `scripts/k3s/postgres/lib.sh` | backup helper |
| `ATLAS_POSTGRES_IMAGE` | image for helper jobs | `postgres:16-alpine` | `scripts/k3s/postgres/lib.sh` | backup and restore helpers |
| `ATLAS_POSTGRES_SECRET_NAME` | PostgreSQL secret to read credentials from | `postgres-secret` | `scripts/k3s/postgres/lib.sh` | backup and restore helpers |
| `ATLAS_POSTGRES_HOST` | PostgreSQL service hostname | `postgres` | `scripts/k3s/postgres/lib.sh` | backup and restore helpers |
| `ATLAS_POSTGRES_STATEFULSET` | target statefulset name | `postgres` | `scripts/k3s/postgres/lib.sh` | backup and restore helpers |
| `ATLAS_POSTGRES_POD_WAIT_TIMEOUT_SECONDS` | helper pod wait timeout | `120` | `scripts/k3s/postgres/lib.sh` | backup and restore helpers |
| `ATLAS_POSTGRES_BACKUP_JOB_TIMEOUT_SECONDS` | backup job timeout | `600` | `scripts/k3s/postgres/lib.sh` | backup helper |
| `ATLAS_POSTGRES_RESTORE_JOB_TIMEOUT_SECONDS` | restore job timeout | `900` | `scripts/k3s/postgres/lib.sh` | restore helper |
| `ATLAS_POSTGRES_STATEFULSET_TIMEOUT_SECONDS` | PostgreSQL rollout timeout | `300` | `scripts/k3s/postgres/lib.sh` | backup and restore helpers |
| `ATLAS_POSTGRES_RESTORE_WAIT_SECONDS` | wait before restore starts inside job manifest | `300` | `scripts/k3s/postgres/restore.sh`, `scripts/k3s/postgres/lib.sh` | restore helper |

## Safety confirmations

| Variable | Role | Where enforced | Notes |
| --- | --- | --- | --- |
| `ATLAS_CONFIRM_STAGING_DELETE` | explicit confirmation for staging teardown | `scripts/gitops/delete-staging.sh` and `mise run k8s-delete-staging` | Must equal `atlas-platform-staging`. |
| `ATLAS_CONFIRM_POSTGRES_RESTORE` | explicit confirmation for PostgreSQL restore | `scripts/k3s/postgres/restore.sh` | Must match the environment confirmation token, which defaults to the namespace. |
| `BACKUP_FILE` | restore source dump | `scripts/k3s/postgres/restore.sh` | Must point to an existing `.dump` file. |

These variables are intentionally awkward. They exist to slow down destructive
actions and force the operator to re-read the target environment.

## Default endpoints and surfaces

| Surface | URL or port |
| --- | --- |
| Compose web | `http://localhost:8080` |
| Compose backend docs | `http://localhost:8000/docs` |
| Compose backend readiness | `http://localhost:8000/readyz` |
| k3s dev web | `http://atlas.local` |
| k3s dev API | `http://api.atlas.local` |
| staging-local HTTP NodePort | `32080` by default |
| staging-local HTTPS NodePort | `32443` by default |
| staging web | `https://staging.atlas.example.com` after HTTPS is enabled, otherwise helper scripts default to `http` |
| staging API | `https://api.staging.atlas.example.com` after HTTPS is enabled, otherwise helper scripts default to `http` |

## Read next

- [Command reference](commands.md)
- [Tool ownership matrix](tool-ownership-matrix.md)
- [Troubleshooting](troubleshooting.md)
