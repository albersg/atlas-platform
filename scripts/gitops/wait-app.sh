#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ] || [ "$#" -gt 3 ]; then
  echo "Uso: $0 <application-name> [argocd-namespace] [timeout-seconds]" >&2
  exit 1
fi

APP_NAME="$1"
ARGOCD_NAMESPACE="${2:-argocd}"
TIMEOUT_SECONDS="${3:-600}"

deadline=$((SECONDS + TIMEOUT_SECONDS))

while [ "$SECONDS" -lt "$deadline" ]; do
  sync_status="$(kubectl -n "$ARGOCD_NAMESPACE" get application "$APP_NAME" -o jsonpath='{.status.sync.status}' 2>/dev/null || true)"
  health_status="$(kubectl -n "$ARGOCD_NAMESPACE" get application "$APP_NAME" -o jsonpath='{.status.health.status}' 2>/dev/null || true)"
  operation_phase="$(kubectl -n "$ARGOCD_NAMESPACE" get application "$APP_NAME" -o jsonpath='{.status.operationState.phase}' 2>/dev/null || true)"

  echo "Aplicacion ${APP_NAME}: sync=${sync_status:-Unknown} health=${health_status:-Unknown} operation=${operation_phase:-Idle}"

  if [ "$sync_status" = "Synced" ] && [ "$health_status" = "Healthy" ]; then
    echo "Aplicacion ${APP_NAME} sincronizada y saludable."
    exit 0
  fi

  sleep 5
done

echo "Timeout esperando a la aplicacion ${APP_NAME}. Estado final:" >&2
kubectl -n "$ARGOCD_NAMESPACE" get application "$APP_NAME" -o yaml >&2
exit 1
