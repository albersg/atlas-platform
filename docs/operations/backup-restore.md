# Backup And Restore

These commands protect and recover the non-production PostgreSQL data used by staging.

## Backup

```bash
mise run k8s-backup-postgres-staging
```

- Purpose: create a timestamped PostgreSQL dump for staging.
- Under the hood: runs `ATLAS_POSTGRES_ENV=staging ./scripts/k3s/postgres/backup.sh`.
- Expected result: a `.dump` file under `.gitops-local/backups/staging/` and a printed restore command.
- Safe rehearsal: set `ATLAS_POSTGRES_DRY_RUN=1` to inspect the flow without creating a real dump.

## Restore

```bash
BACKUP_FILE=.gitops-local/backups/staging/<timestamp>.dump \
ATLAS_CONFIRM_POSTGRES_RESTORE=atlas-platform-staging \
mise run k8s-restore-postgres-staging
```

- Purpose: restore staging PostgreSQL from a chosen dump.
- Why it is guarded: this is destructive and must be explicit.
- Under the hood: validates the backup file, loads it into the cluster workflow, reapplies the overlay, waits for the migration job, and runs smoke checks.
- Expected result: a successful restore plus post-restore validation.

## Required guardrails

- `BACKUP_FILE` must point to a real dump.
- `ATLAS_CONFIRM_POSTGRES_RESTORE` must exactly equal `atlas-platform-staging`.
- dry-run mode is available through `ATLAS_POSTGRES_DRY_RUN=1`.

## When to use these commands

- before risky staging data changes,
- while rehearsing recovery,
- when validating that a backup can be restored locally.

## Read next

- [Canonical staging](canonical-staging.md)
- [Troubleshooting](../reference/troubleshooting.md)
