#!/usr/bin/env bash

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ATLAS_POSTGRES_ENV="${ATLAS_POSTGRES_ENV:-staging}"
ATLAS_POSTGRES_DRY_RUN="${ATLAS_POSTGRES_DRY_RUN:-0}"
ATLAS_POSTGRES_IMAGE="${ATLAS_POSTGRES_IMAGE:-postgres:16-alpine}"
ATLAS_POSTGRES_SECRET_NAME="${ATLAS_POSTGRES_SECRET_NAME:-postgres-secret}"
ATLAS_POSTGRES_HOST="${ATLAS_POSTGRES_HOST:-postgres}"
ATLAS_POSTGRES_STATEFULSET="${ATLAS_POSTGRES_STATEFULSET:-postgres}"
ATLAS_POSTGRES_BACKUP_ROOT="${ATLAS_POSTGRES_BACKUP_ROOT:-$ROOT_DIR/.gitops-local/backups}"
ATLAS_POSTGRES_KEEP_JOBS="${ATLAS_POSTGRES_KEEP_JOBS:-0}"
ATLAS_POSTGRES_TRANSPORT="${ATLAS_POSTGRES_TRANSPORT:-job}"
ATLAS_POSTGRES_POD_WAIT_TIMEOUT_SECONDS="${ATLAS_POSTGRES_POD_WAIT_TIMEOUT_SECONDS:-120}"
ATLAS_POSTGRES_BACKUP_JOB_TIMEOUT_SECONDS="${ATLAS_POSTGRES_BACKUP_JOB_TIMEOUT_SECONDS:-600}"
ATLAS_POSTGRES_RESTORE_JOB_TIMEOUT_SECONDS="${ATLAS_POSTGRES_RESTORE_JOB_TIMEOUT_SECONDS:-900}"
ATLAS_POSTGRES_STATEFULSET_TIMEOUT_SECONDS="${ATLAS_POSTGRES_STATEFULSET_TIMEOUT_SECONDS:-300}"

resolve_postgres_environment() {
  case "$ATLAS_POSTGRES_ENV" in
    dev)
      ATLAS_POSTGRES_NAMESPACE="${ATLAS_POSTGRES_NAMESPACE:-atlas-platform-dev}"
      ATLAS_POSTGRES_OVERLAY_PATH="${ATLAS_POSTGRES_OVERLAY_PATH:-platform/k8s/overlays/dev}"
      ;;
    staging)
      ATLAS_POSTGRES_NAMESPACE="${ATLAS_POSTGRES_NAMESPACE:-atlas-platform-staging}"
      ATLAS_POSTGRES_OVERLAY_PATH="${ATLAS_POSTGRES_OVERLAY_PATH:-platform/k8s/overlays/staging-local}"
      ;;
    *)
      echo "Entorno PostgreSQL no soportado: $ATLAS_POSTGRES_ENV" >&2
      return 1
      ;;
  esac

  ATLAS_POSTGRES_CONFIRMATION_TOKEN="${ATLAS_POSTGRES_CONFIRMATION_TOKEN:-$ATLAS_POSTGRES_NAMESPACE}"
  ATLAS_POSTGRES_BACKUP_DIR="${ATLAS_POSTGRES_BACKUP_DIR:-$ATLAS_POSTGRES_BACKUP_ROOT/$ATLAS_POSTGRES_ENV}"
}

require_command() {
  local tool_name="$1"
  local hint="$2"

  if ! command -v "$tool_name" >/dev/null 2>&1; then
    echo "Falta ${tool_name}. ${hint}" >&2
    return 1
  fi
}

ensure_backup_workspace() {
  mkdir -p "$ATLAS_POSTGRES_BACKUP_DIR" || return 1

  local probe_file
  probe_file="$ATLAS_POSTGRES_BACKUP_DIR/.atlas-write-test"
  : >"$probe_file" || return 1
  rm -f "$probe_file"
}

run_or_print() {
  if [[ "$ATLAS_POSTGRES_DRY_RUN" = "1" ]]; then
    printf 'DRY_RUN: '
    printf '%q ' "$@"
    printf '\n'
    return 0
  fi

  "$@"
}

render_template() {
  local template_path="$1"
  local output_path="$2"

  python - "$template_path" "$output_path" <<'PY'
from __future__ import annotations

import os
import pathlib
import sys

template = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
replacements = {
    "__JOB_NAME__": os.environ["ATLAS_POSTGRES_JOB_NAME"],
    "__NAMESPACE__": os.environ["ATLAS_POSTGRES_NAMESPACE"],
    "__POSTGRES_IMAGE__": os.environ["ATLAS_POSTGRES_IMAGE"],
    "__POSTGRES_HOST__": os.environ["ATLAS_POSTGRES_HOST"],
    "__POSTGRES_SECRET_NAME__": os.environ["ATLAS_POSTGRES_SECRET_NAME"],
    "__BACKUP_PATH__": os.environ.get("ATLAS_POSTGRES_REMOTE_BACKUP_PATH", ""),
    "__RESTORE_PATH__": os.environ.get("ATLAS_POSTGRES_REMOTE_RESTORE_PATH", ""),
    "__RESTORE_WAIT_SECONDS__": os.environ.get("ATLAS_POSTGRES_RESTORE_WAIT_SECONDS", "300"),
}

for needle, value in replacements.items():
    template = template.replace(needle, value)

pathlib.Path(sys.argv[2]).write_text(template, encoding="utf-8")
PY
}

wait_for_job_pod() {
  local timeout_seconds="${1:-120}"
  local start_seconds

  start_seconds="$(date +%s)"

  while true; do
    if kubectl -n "$ATLAS_POSTGRES_NAMESPACE" get pod -l "job-name=$ATLAS_POSTGRES_JOB_NAME" -o name 2>/dev/null | grep -q .; then
      return 0
    fi

    if (($(date +%s) - start_seconds >= timeout_seconds)); then
      echo "No aparecio un pod para el job ${ATLAS_POSTGRES_JOB_NAME}." >&2
      return 1
    fi

    sleep 2
  done
}

get_job_pod_name() {
  kubectl -n "$ATLAS_POSTGRES_NAMESPACE" get pod -l "job-name=$ATLAS_POSTGRES_JOB_NAME" \
    -o jsonpath='{.items[0].metadata.name}'
}

get_postgres_pod_name() {
  kubectl -n "$ATLAS_POSTGRES_NAMESPACE" get pod -l "app=$ATLAS_POSTGRES_STATEFULSET" \
    -o jsonpath='{.items[0].metadata.name}'
}

wait_for_statefulset_ready() {
  kubectl -n "$ATLAS_POSTGRES_NAMESPACE" rollout status \
    "statefulset/$ATLAS_POSTGRES_STATEFULSET" --timeout="${ATLAS_POSTGRES_STATEFULSET_TIMEOUT_SECONDS}s" >/dev/null
}

wait_for_postgres_pod_ready() {
  local postgres_pod_name

  postgres_pod_name="$(get_postgres_pod_name)"
  if [[ -z "$postgres_pod_name" ]]; then
    echo "No se encontro un pod de PostgreSQL en $ATLAS_POSTGRES_NAMESPACE." >&2
    return 1
  fi

  kubectl -n "$ATLAS_POSTGRES_NAMESPACE" wait --for=condition=Ready "pod/$postgres_pod_name" \
    --timeout="${ATLAS_POSTGRES_POD_WAIT_TIMEOUT_SECONDS}s" >/dev/null
}

log_job_diagnostics() {
  echo "Diagnostico del job ${ATLAS_POSTGRES_JOB_NAME} en ${ATLAS_POSTGRES_NAMESPACE}:" >&2
  kubectl -n "$ATLAS_POSTGRES_NAMESPACE" get job "$ATLAS_POSTGRES_JOB_NAME" -o wide >&2 || true
  kubectl -n "$ATLAS_POSTGRES_NAMESPACE" get pods -l "job-name=$ATLAS_POSTGRES_JOB_NAME" -o wide >&2 || true

  pod_name="$(get_job_pod_name 2>/dev/null || true)"
  if [[ -n "$pod_name" ]]; then
    kubectl -n "$ATLAS_POSTGRES_NAMESPACE" describe pod "$pod_name" >&2 || true
    kubectl -n "$ATLAS_POSTGRES_NAMESPACE" logs "$pod_name" --all-containers=true >&2 || true
  fi
}

log_postgres_diagnostics() {
  local postgres_pod_name

  postgres_pod_name="$(get_postgres_pod_name 2>/dev/null || true)"
  echo "Diagnostico de PostgreSQL en ${ATLAS_POSTGRES_NAMESPACE}:" >&2
  kubectl -n "$ATLAS_POSTGRES_NAMESPACE" get statefulset "$ATLAS_POSTGRES_STATEFULSET" -o wide >&2 || true
  if [[ -n "$postgres_pod_name" ]]; then
    kubectl -n "$ATLAS_POSTGRES_NAMESPACE" get pod "$postgres_pod_name" -o wide >&2 || true
    kubectl -n "$ATLAS_POSTGRES_NAMESPACE" describe pod "$postgres_pod_name" >&2 || true
    kubectl -n "$ATLAS_POSTGRES_NAMESPACE" logs "$postgres_pod_name" >&2 || true
  fi
}

wait_for_job_completion() {
  local timeout_seconds="$1"

  if ! kubectl -n "$ATLAS_POSTGRES_NAMESPACE" wait --for=condition=complete "job/$ATLAS_POSTGRES_JOB_NAME" --timeout="${timeout_seconds}s" >/dev/null; then
    log_job_diagnostics
    return 1
  fi
}

cleanup_job() {
  if [[ "$ATLAS_POSTGRES_KEEP_JOBS" = "1" ]]; then
    return 0
  fi

  kubectl -n "$ATLAS_POSTGRES_NAMESPACE" delete job "$ATLAS_POSTGRES_JOB_NAME" --ignore-not-found >/dev/null 2>&1 || true
}

print_restore_hint() {
  local backup_file="$1"

  cat <<EOF
Backup listo: $backup_file
Restore sugerido:
BACKUP_FILE=$backup_file ATLAS_CONFIRM_POSTGRES_RESTORE=$ATLAS_POSTGRES_CONFIRMATION_TOKEN mise run k8s-restore-postgres-staging
EOF
}
