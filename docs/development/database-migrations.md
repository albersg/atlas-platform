# Database And Migrations

Atlas Platform uses Alembic for schema changes in `services/inventory-service`.
If a persistent model changes, the repository expects an explicit migration.

## Why this matters

- it keeps schema history visible,
- it makes local, k3s, and staging environments converge the same way,
- it keeps the migration job aligned with the backend image.

## Main command

```bash
mise run backend-migrate
```

- Purpose: apply all pending Alembic migrations.
- When to run it: after pulling a change with schema updates or while validating a new migration locally.
- Under the hood: runs `alembic upgrade head` inside `services/inventory-service`.
- Expected output: Alembic logs showing the target revision reached.

## Create a new migration manually

```bash
cd services/inventory-service
uv run --extra dev alembic revision -m "describe-your-change"
```

Use this after updating the relevant models or persistence logic.

## Preview the generated SQL

```bash
cd services/inventory-service
uv run --extra dev alembic upgrade head --sql
```

Use this when you want to inspect what Alembic plans to execute.

## Where migration files live

- migrations: `services/inventory-service/alembic/versions/`
- current baseline example: `services/inventory-service/alembic/versions/20260306_0001_create_products_table.py`

## How migrations behave in Kubernetes

- `dev` and `staging` both rely on the migration job in the rendered manifests.
- smoke checks assume the migration job completed successfully.
- backend deployment and migration job should stay aligned with the same image version or digest.

## Read next

- [Backend development](backend-development.md)
- [k3s dev environment](../operations/k3s-dev.md)
- [Backup and restore](../operations/backup-restore.md)
