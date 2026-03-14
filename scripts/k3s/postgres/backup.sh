#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"

resolve_postgres_environment

TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
ATLAS_POSTGRES_JOB_NAME="postgres-backup-${ATLAS_POSTGRES_ENV}-${TIMESTAMP,,}"
ATLAS_POSTGRES_REMOTE_BACKUP_PATH="/backup/${ATLAS_POSTGRES_ENV}-${TIMESTAMP}.dump"
BACKUP_FILE="$ATLAS_POSTGRES_BACKUP_DIR/${ATLAS_POSTGRES_ENV}-${TIMESTAMP}.dump"
TEMPLATE_PATH="$ROOT_DIR/platform/k8s/components/in-cluster-postgres/workloads/postgres-backup-job.yaml"
MANIFEST_PATH="$(mktemp)"
trap 'rm -f "$MANIFEST_PATH"; cleanup_job' EXIT

if ! ensure_backup_workspace; then
  echo "No se pudo preparar el workspace de backups en $ATLAS_POSTGRES_BACKUP_DIR." >&2
  exit 1
fi

require_command kubectl "Instala kubectl antes de operar backups no productivos."

if [[ "$ATLAS_POSTGRES_DRY_RUN" != "1" ]]; then
  kubectl cluster-info >/dev/null
  wait_for_statefulset_ready
fi

export \
  ATLAS_POSTGRES_JOB_NAME \
  ATLAS_POSTGRES_NAMESPACE \
  ATLAS_POSTGRES_IMAGE \
  ATLAS_POSTGRES_HOST \
  ATLAS_POSTGRES_SECRET_NAME \
  ATLAS_POSTGRES_REMOTE_BACKUP_PATH
render_template "$TEMPLATE_PATH" "$MANIFEST_PATH"

echo "Creando backup PostgreSQL de ${ATLAS_POSTGRES_ENV} en ${ATLAS_POSTGRES_BACKUP_DIR}"

if [[ "$ATLAS_POSTGRES_TRANSPORT" = "exec" ]]; then
  POSTGRES_POD_NAME="$(get_postgres_pod_name)"
  ATLAS_POSTGRES_REMOTE_BACKUP_PATH="/tmp/${ATLAS_POSTGRES_ENV}-${TIMESTAMP}.dump"

  if [[ "$ATLAS_POSTGRES_DRY_RUN" = "1" ]]; then
    echo "DRY_RUN: kubectl -n $ATLAS_POSTGRES_NAMESPACE exec $POSTGRES_POD_NAME -- sh -ec 'pg_dump -h 127.0.0.1 -U \"\$POSTGRES_USER\" -d \"\$POSTGRES_DB\" -Fc -f \"$ATLAS_POSTGRES_REMOTE_BACKUP_PATH\"'"
    echo "DRY_RUN: kubectl cp $ATLAS_POSTGRES_NAMESPACE/$POSTGRES_POD_NAME:$ATLAS_POSTGRES_REMOTE_BACKUP_PATH $BACKUP_FILE"
    echo "DRY_RUN: kubectl -n $ATLAS_POSTGRES_NAMESPACE exec $POSTGRES_POD_NAME -- rm -f $ATLAS_POSTGRES_REMOTE_BACKUP_PATH"
    print_restore_hint "$BACKUP_FILE"
    exit 0
  fi

  wait_for_postgres_pod_ready
  POSTGRES_POD_NAME="$(get_postgres_pod_name)"
  # shellcheck disable=SC2016
  if ! kubectl -n "$ATLAS_POSTGRES_NAMESPACE" exec "$POSTGRES_POD_NAME" -- \
    sh -ec 'pg_dump -h 127.0.0.1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc -f "$1"' -- \
    "$ATLAS_POSTGRES_REMOTE_BACKUP_PATH"; then
    log_postgres_diagnostics
    exit 1
  fi

  if ! kubectl cp \
    "$ATLAS_POSTGRES_NAMESPACE/$POSTGRES_POD_NAME:$ATLAS_POSTGRES_REMOTE_BACKUP_PATH" \
    "$BACKUP_FILE" >/dev/null; then
    log_postgres_diagnostics
    exit 1
  fi

  kubectl -n "$ATLAS_POSTGRES_NAMESPACE" exec "$POSTGRES_POD_NAME" -- rm -f "$ATLAS_POSTGRES_REMOTE_BACKUP_PATH" >/dev/null 2>&1 || true
  print_restore_hint "$BACKUP_FILE"
  exit 0
fi

if [[ "$ATLAS_POSTGRES_DRY_RUN" = "1" ]]; then
  echo "DRY_RUN: kubectl -n $ATLAS_POSTGRES_NAMESPACE apply -f $MANIFEST_PATH"
  print_restore_hint "$BACKUP_FILE"
  exit 0
fi

if [[ "$ATLAS_POSTGRES_TRANSPORT" != "job" ]]; then
  echo "ATLAS_POSTGRES_TRANSPORT no soportado: $ATLAS_POSTGRES_TRANSPORT" >&2
  exit 1
fi

kubectl -n "$ATLAS_POSTGRES_NAMESPACE" apply -f "$MANIFEST_PATH" >/dev/null
wait_for_job_pod "$ATLAS_POSTGRES_POD_WAIT_TIMEOUT_SECONDS"
wait_for_job_completion "$ATLAS_POSTGRES_BACKUP_JOB_TIMEOUT_SECONDS"

JOB_POD_NAME="$(get_job_pod_name)"
if ! kubectl cp \
  "$ATLAS_POSTGRES_NAMESPACE/$JOB_POD_NAME:$ATLAS_POSTGRES_REMOTE_BACKUP_PATH" \
  "$BACKUP_FILE" >/dev/null; then
  log_job_diagnostics
  exit 1
fi

print_restore_hint "$BACKUP_FILE"
