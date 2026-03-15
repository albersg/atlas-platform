# Configuration And Environment Variables

This page lists the most important runtime and workflow variables used by the repo.
It is not a replacement for reading the scripts, but it gives contributors a safe starting point.

## Backend runtime

Defined by `services/inventory-service/src/inventory_service/shared/config.py`.

| Variable | Default or role | Notes |
| --- | --- | --- |
| `INVENTORY_APP_NAME` | `inventory-service` | Backend app name |
| `INVENTORY_APP_ENV` | `dev` | Backend environment label |
| `INVENTORY_DATABASE_URL` | local PostgreSQL URL | Main backend database connection |
| `INVENTORY_SENTRY_DSN` | optional | Enables Sentry reporting |
| `INVENTORY_SENTRY_TRACES_SAMPLE_RATE` | `0.0` | Sentry tracing sample rate |

## Frontend runtime

Defined by `apps/web/src/vite-env.d.ts` and Sentry setup.

| Variable | Role | Notes |
| --- | --- | --- |
| `VITE_SENTRY_DSN` | optional Sentry DSN | Enables frontend error reporting |
| `VITE_SENTRY_ENVIRONMENT` | environment label | Defaults to the Vite mode when unset |
| `VITE_SENTRY_TRACES_SAMPLE_RATE` | tracing sample rate | Parsed as a number |

## GitOps and staging flow

| Variable | Role | Notes |
| --- | --- | --- |
| `ARGOCD_APP_REVISION` | target branch or commit | Useful to validate a pushed branch before merge |
| `STAGING_LOCAL_IMAGES` | choose local staging-local vs canonical staging behavior | Set `0` to avoid the local-image wrapper |
| `SOPS_AGE_KEY` | key material for encrypted overlay validation | Needed in some CI and promotion paths |

## Safety confirmations

| Variable | Role | Notes |
| --- | --- | --- |
| `ATLAS_CONFIRM_STAGING_DELETE` | required confirmation for staging teardown | Must equal `atlas-platform-staging` |
| `ATLAS_CONFIRM_POSTGRES_RESTORE` | required confirmation for staging PostgreSQL restore | Must equal `atlas-platform-staging` |
| `BACKUP_FILE` | restore source dump | Must point to an existing `.dump` file |

## Diagnostic and dry-run helpers

| Variable | Role | Notes |
| --- | --- | --- |
| `ATLAS_DOCTOR_SCOPE` | relax doctor checks for local-only work | `dev` gives a lighter readiness check |
| `ATLAS_POSTGRES_DRY_RUN` | inspect backup/restore flow without changing the cluster | Set `1` for dry-run behavior |
| `MISE_LINT_MAX_TRIES` | retry cap for `mise run lint` | Defaults to `3` |

## Default local endpoints

| Surface | URL |
| --- | --- |
| Compose web | `http://localhost:8080` |
| Compose/backend docs | `http://localhost:8000/docs` |
| Compose/backend readiness | `http://localhost:8000/readyz` |
| k3s dev web | `http://atlas.local` |
| k3s dev API | `http://api.atlas.local` |
| staging web | `https://staging.atlas.example.com` |
| staging API | `https://api.staging.atlas.example.com` |
