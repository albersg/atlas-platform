#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"

resolve_postgres_environment

BACKUP_FILE="${BACKUP_FILE:-${1:-}}"
CONFIRMATION_TOKEN="${ATLAS_CONFIRM_POSTGRES_RESTORE:-}"
ATLAS_POSTGRES_RESTORE_WAIT_SECONDS="${ATLAS_POSTGRES_RESTORE_WAIT_SECONDS:-300}"
TIMESTAMP="$(date -u +%Y%m%d%H%M%S)"
ATLAS_POSTGRES_JOB_NAME="postgres-restore-${ATLAS_POSTGRES_ENV}-${TIMESTAMP}"
ATLAS_POSTGRES_REMOTE_RESTORE_PATH="/restore/input.dump"
TEMPLATE_PATH="$ROOT_DIR/platform/k8s/components/in-cluster-postgres/workloads/postgres-restore-job.yaml"
MANIFEST_PATH="$(mktemp)"
trap 'rm -f "$MANIFEST_PATH"; cleanup_job' EXIT

if [[ -z "$BACKUP_FILE" ]]; then
  echo "Define BACKUP_FILE con un dump existente antes de restaurar." >&2
  exit 1
fi

if [[ ! -f "$BACKUP_FILE" ]]; then
  echo "BACKUP_FILE no existe: $BACKUP_FILE" >&2
  exit 1
fi

if [[ "$CONFIRMATION_TOKEN" != "$ATLAS_POSTGRES_CONFIRMATION_TOKEN" ]]; then
  echo "Restore destructivo rechazado." >&2
  echo "Exporta ATLAS_CONFIRM_POSTGRES_RESTORE=$ATLAS_POSTGRES_CONFIRMATION_TOKEN para continuar." >&2
  exit 1
fi

require_command kubectl "Instala kubectl antes de operar restores no productivos."

if [[ "$ATLAS_POSTGRES_DRY_RUN" != "1" ]]; then
  kubectl cluster-info >/dev/null
  wait_for_statefulset_ready
  "$ROOT_DIR/scripts/gitops/render-overlay.sh" "$ATLAS_POSTGRES_OVERLAY_PATH" >/dev/null
fi

export \
  ATLAS_POSTGRES_JOB_NAME \
  ATLAS_POSTGRES_NAMESPACE \
  ATLAS_POSTGRES_IMAGE \
  ATLAS_POSTGRES_HOST \
  ATLAS_POSTGRES_SECRET_NAME \
  ATLAS_POSTGRES_REMOTE_RESTORE_PATH \
  ATLAS_POSTGRES_RESTORE_WAIT_SECONDS
render_template "$TEMPLATE_PATH" "$MANIFEST_PATH"

echo "Restaurando PostgreSQL de ${ATLAS_POSTGRES_ENV} desde ${BACKUP_FILE}"

if [[ "$ATLAS_POSTGRES_TRANSPORT" = "exec" ]]; then
  POSTGRES_POD_NAME="$(get_postgres_pod_name)"
  ATLAS_POSTGRES_REMOTE_RESTORE_PATH="/tmp/$(basename "$BACKUP_FILE")"

  if [[ "$ATLAS_POSTGRES_DRY_RUN" = "1" ]]; then
    echo "DRY_RUN: kubectl cp $BACKUP_FILE $ATLAS_POSTGRES_NAMESPACE/$POSTGRES_POD_NAME:$ATLAS_POSTGRES_REMOTE_RESTORE_PATH"
    echo "DRY_RUN: kubectl -n $ATLAS_POSTGRES_NAMESPACE exec $POSTGRES_POD_NAME -- sh -ec 'pg_restore -h 127.0.0.1 -U \"\$POSTGRES_USER\" -d \"\$POSTGRES_DB\" --clean --if-exists --no-owner --no-privileges \"$ATLAS_POSTGRES_REMOTE_RESTORE_PATH\"'"
    echo "DRY_RUN: kubectl -n $ATLAS_POSTGRES_NAMESPACE exec $POSTGRES_POD_NAME -- rm -f $ATLAS_POSTGRES_REMOTE_RESTORE_PATH"
    echo "DRY_RUN: kubectl -n $ATLAS_POSTGRES_NAMESPACE delete job inventory-migration --ignore-not-found"
    echo "DRY_RUN: $ROOT_DIR/scripts/gitops/render-overlay.sh $ATLAS_POSTGRES_OVERLAY_PATH | kubectl apply -f -"
    echo "DRY_RUN: $ROOT_DIR/scripts/k3s/verify/smoke.sh $ATLAS_POSTGRES_ENV $ATLAS_POSTGRES_NAMESPACE"
    exit 0
  fi

  wait_for_postgres_pod_ready
  POSTGRES_POD_NAME="$(get_postgres_pod_name)"
  if ! kubectl cp "$BACKUP_FILE" "$ATLAS_POSTGRES_NAMESPACE/$POSTGRES_POD_NAME:$ATLAS_POSTGRES_REMOTE_RESTORE_PATH" >/dev/null; then
    log_postgres_diagnostics
    exit 1
  fi

  # shellcheck disable=SC2016
  if ! kubectl -n "$ATLAS_POSTGRES_NAMESPACE" exec "$POSTGRES_POD_NAME" -- \
    sh -ec 'pg_restore -h 127.0.0.1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" --clean --if-exists --no-owner --no-privileges "$1"' -- \
    "$ATLAS_POSTGRES_REMOTE_RESTORE_PATH"; then
    log_postgres_diagnostics
    exit 1
  fi

  kubectl -n "$ATLAS_POSTGRES_NAMESPACE" exec "$POSTGRES_POD_NAME" -- rm -f "$ATLAS_POSTGRES_REMOTE_RESTORE_PATH" >/dev/null 2>&1 || true

  kubectl -n "$ATLAS_POSTGRES_NAMESPACE" delete job inventory-migration --ignore-not-found >/dev/null 2>&1 || true
  "$ROOT_DIR/scripts/gitops/render-overlay.sh" "$ATLAS_POSTGRES_OVERLAY_PATH" | kubectl apply -f - >/dev/null
  kubectl -n "$ATLAS_POSTGRES_NAMESPACE" wait --for=condition=complete job/inventory-migration --timeout=300s >/dev/null
  "$ROOT_DIR/scripts/k3s/verify/smoke.sh" "$ATLAS_POSTGRES_ENV" "$ATLAS_POSTGRES_NAMESPACE"

  echo "Restore PostgreSQL completado y validado con migraciones + smoke checks."
  exit 0
fi

if [[ "$ATLAS_POSTGRES_DRY_RUN" = "1" ]]; then
  echo "DRY_RUN: kubectl -n $ATLAS_POSTGRES_NAMESPACE apply -f $MANIFEST_PATH"
  echo "DRY_RUN: kubectl cp $BACKUP_FILE $ATLAS_POSTGRES_NAMESPACE/<restore-pod>:$ATLAS_POSTGRES_REMOTE_RESTORE_PATH"
  echo "DRY_RUN: kubectl -n $ATLAS_POSTGRES_NAMESPACE delete job inventory-migration --ignore-not-found"
  echo "DRY_RUN: $ROOT_DIR/scripts/gitops/render-overlay.sh $ATLAS_POSTGRES_OVERLAY_PATH | kubectl apply -f -"
  echo "DRY_RUN: $ROOT_DIR/scripts/k3s/verify/smoke.sh $ATLAS_POSTGRES_ENV $ATLAS_POSTGRES_NAMESPACE"
  exit 0
fi

if [[ "$ATLAS_POSTGRES_TRANSPORT" != "job" ]]; then
  echo "ATLAS_POSTGRES_TRANSPORT no soportado: $ATLAS_POSTGRES_TRANSPORT" >&2
  exit 1
fi

kubectl -n "$ATLAS_POSTGRES_NAMESPACE" apply -f "$MANIFEST_PATH" >/dev/null
wait_for_job_pod "$ATLAS_POSTGRES_POD_WAIT_TIMEOUT_SECONDS"

RESTORE_POD_NAME="$(get_job_pod_name)"
if ! kubectl cp "$BACKUP_FILE" "$ATLAS_POSTGRES_NAMESPACE/$RESTORE_POD_NAME:$ATLAS_POSTGRES_REMOTE_RESTORE_PATH" >/dev/null; then
  log_job_diagnostics
  exit 1
fi
wait_for_job_completion "$ATLAS_POSTGRES_RESTORE_JOB_TIMEOUT_SECONDS"

kubectl -n "$ATLAS_POSTGRES_NAMESPACE" delete job inventory-migration --ignore-not-found >/dev/null 2>&1 || true
"$ROOT_DIR/scripts/gitops/render-overlay.sh" "$ATLAS_POSTGRES_OVERLAY_PATH" | kubectl apply -f - >/dev/null
kubectl -n "$ATLAS_POSTGRES_NAMESPACE" wait --for=condition=complete job/inventory-migration --timeout=300s >/dev/null
"$ROOT_DIR/scripts/k3s/verify/smoke.sh" "$ATLAS_POSTGRES_ENV" "$ATLAS_POSTGRES_NAMESPACE"

echo "Restore PostgreSQL completado y validado con migraciones + smoke checks."
