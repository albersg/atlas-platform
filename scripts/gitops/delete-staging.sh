#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RENDER_OVERLAY_SCRIPT="${ATLAS_RENDER_OVERLAY_SCRIPT:-$ROOT_DIR/scripts/gitops/render-overlay.sh}"
ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"
APP_NAME="${APP_NAME:-atlas-platform-staging}"
STAGING_NAMESPACE="${STAGING_NAMESPACE:-atlas-platform-staging}"
EXPECTED_CONFIRMATION="${EXPECTED_CONFIRMATION:-atlas-platform-staging}"
CONFIRMATION_TOKEN="${ATLAS_CONFIRM_STAGING_DELETE:-}"
PRESERVE_POSTGRES_PVC="${PRESERVE_POSTGRES_PVC:-1}"
DRY_RUN="${ATLAS_STAGING_DELETE_DRY_RUN:-0}"
DELETE_MANIFEST_PATH="$(mktemp)"

cleanup() {
  rm -f "$DELETE_MANIFEST_PATH"
}

trap cleanup EXIT

run_or_print() {
  if [[ "$DRY_RUN" = "1" ]]; then
    printf 'DRY_RUN: '
    printf '%q ' "$@"
    printf '\n'
    return 0
  fi

  "$@"
}

print_resource_group() {
  local description="$1"
  shift

  echo
  echo "$description"
  if ! kubectl "$@"; then
    echo "  (sin recursos o no accessible)"
  fi
}

render_delete_manifest() {
  local output_path="$1"

  if [[ "$PRESERVE_POSTGRES_PVC" = "1" ]]; then
    "$RENDER_OVERLAY_SCRIPT" platform/k8s/overlays/staging | python -c '
from __future__ import annotations

import pathlib
import re
import sys

documents = re.split(r"^---\s*$", sys.stdin.read(), flags=re.MULTILINE)
kept: list[str] = []

for document in documents:
    stripped = document.strip()
    if not stripped:
        continue
    if re.search(r"^kind:\s*(Namespace|PersistentVolumeClaim)\s*$", stripped, flags=re.MULTILINE):
        continue
    kept.append(stripped)

payload = "\n---\n".join(kept)
if payload:
    payload += "\n"

pathlib.Path(sys.argv[1]).write_text(payload, encoding="utf-8")
' "$output_path"
    return
  fi

  "$RENDER_OVERLAY_SCRIPT" platform/k8s/overlays/staging >"$output_path"
}

disable_and_delete_application() {
  if ! kubectl -n "$ARGOCD_NAMESPACE" get application "$APP_NAME" >/dev/null 2>&1; then
    return 0
  fi

  echo
  echo "Deshabilitando auto-sync y quitando finalizers antes de borrar ${APP_NAME} sin cascada..."
  run_or_print kubectl -n "$ARGOCD_NAMESPACE" patch application "$APP_NAME" --type merge -p '{"metadata":{"finalizers":null},"spec":{"syncPolicy":{"automated":null}}}'

  echo "Eliminando Application ${APP_NAME} sin borrar recursos huerfanos por sorpresa..."
  run_or_print kubectl -n "$ARGOCD_NAMESPACE" delete application "$APP_NAME" --ignore-not-found --cascade=orphan --wait=true

  if [[ "$DRY_RUN" != "1" ]]; then
    for _ in $(seq 1 24); do
      if ! kubectl -n "$ARGOCD_NAMESPACE" get application "$APP_NAME" >/dev/null 2>&1; then
        break
      fi
      sleep 5
    done
  fi
}

if [[ "$CONFIRMATION_TOKEN" != "$EXPECTED_CONFIRMATION" ]]; then
  echo "Operacion destructiva rechazada." >&2
  echo "Exporta ATLAS_CONFIRM_STAGING_DELETE=${EXPECTED_CONFIRMATION} para continuar." >&2
  exit 1
fi

echo "Preparando teardown GitOps-aware de staging."
echo "- Aplicacion Argo CD: ${APP_NAME}"
echo "- Namespace objetivo: ${STAGING_NAMESPACE}"
echo "- Preservar PVC de PostgreSQL: ${PRESERVE_POSTGRES_PVC}"

print_resource_group "Recursos Argo CD observados:" -n "$ARGOCD_NAMESPACE" get application "$APP_NAME" -o name
print_resource_group \
  "Recursos del namespace staging observados:" \
  -n "$STAGING_NAMESPACE" get deploy,statefulset,job,svc,ingress,pvc

disable_and_delete_application

echo
if [[ "$PRESERVE_POSTGRES_PVC" = "1" ]]; then
  echo "Eliminando recursos renderizados del overlay staging sin borrar el Namespace para preservar PVCs..."
else
  echo "Eliminando recursos renderizados del overlay staging con Namespace incluido..."
fi

if [[ "$DRY_RUN" = "1" ]]; then
  if [[ "$PRESERVE_POSTGRES_PVC" = "1" ]]; then
    echo "DRY_RUN: ./scripts/gitops/render-overlay.sh platform/k8s/overlays/staging | filtrar Namespace/PersistentVolumeClaim | kubectl delete -f - --ignore-not-found"
  else
    echo "DRY_RUN: ./scripts/gitops/render-overlay.sh platform/k8s/overlays/staging | kubectl delete -f - --ignore-not-found"
  fi
else
  render_delete_manifest "$DELETE_MANIFEST_PATH"
  if [[ -s "$DELETE_MANIFEST_PATH" ]]; then
    kubectl delete -f "$DELETE_MANIFEST_PATH" --ignore-not-found
  else
    echo "No quedaron recursos renderizados para borrar despues de preservar Namespace/PVC."
  fi
fi

if [[ "$PRESERVE_POSTGRES_PVC" = "1" ]]; then
  echo
  echo "PVC y Namespace preservados por defecto. El almacenamiento queda intacto salvo opt-in destruction."
  echo "Usa PRESERVE_POSTGRES_PVC=0 si quieres eliminar tambien el almacenamiento y el Namespace."
else
  echo
  echo "Eliminando namespace ${STAGING_NAMESPACE} con almacenamiento incluido..."
  run_or_print kubectl delete namespace "$STAGING_NAMESPACE" --ignore-not-found
fi

echo
echo "Teardown de staging completado. Revisa los recursos remanentes con:"
echo "kubectl -n ${STAGING_NAMESPACE} get all,pvc"
