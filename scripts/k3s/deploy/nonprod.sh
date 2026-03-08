#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
. "$(dirname "$0")/../images/lib.sh"

if [ "$#" -ne 3 ]; then
  echo "Uso: $0 <dev|staging> <namespace> <overlay-path>" >&2
  exit 1
fi

ENVIRONMENT="$1"
NAMESPACE="$2"
OVERLAY="$3"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RENDER_SCRIPT="$SCRIPT_DIR/../../gitops/render-overlay.sh"
SMOKE_SCRIPT="$SCRIPT_DIR/../verify/smoke.sh"

prepare_overlay_path() {
  if [ "$ENVIRONMENT" != "dev" ]; then
    EFFECTIVE_OVERLAY="$OVERLAY"
    return
  fi

  ensure_k3s_image_state_dir

  local render_dir="${K3S_IMAGE_STATE_DIR}/render-dev"
  mkdir -p "${render_dir}"

  cat >"${render_dir}/kustomization.yaml" <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../../${OVERLAY}

images:
  - name: atlas-inventory-service
    newName: atlas-inventory-service
    newTag: ${ATLAS_IMAGE_TAG}
  - name: atlas-web
    newName: atlas-web
    newTag: ${ATLAS_IMAGE_TAG}
EOF

  EFFECTIVE_OVERLAY="${render_dir}"
}

apply_overlay() {
  "$RENDER_SCRIPT" "$EFFECTIVE_OVERLAY" | kubectl apply -f -
}

"$SCRIPT_DIR/../cluster/preflight.sh"

if [ "$ENVIRONMENT" = "dev" ]; then
  load_k3s_dev_images
fi

prepare_overlay_path

if [ "$ENVIRONMENT" = "dev" ]; then
  kubectl -n argocd delete application atlas-platform-dev --ignore-not-found >/dev/null 2>&1 || true
fi

echo "Eliminando job de migracion previo (si existe)..."
kubectl -n "$NAMESPACE" delete job inventory-migration --ignore-not-found
kubectl -n "$NAMESPACE" wait --for=delete job/inventory-migration --timeout=120s >/dev/null 2>&1 || true

echo "Eliminando deployment legacy de Postgres si existe..."
kubectl -n "$NAMESPACE" delete deployment postgres --ignore-not-found >/dev/null 2>&1 || true

echo "Aplicando overlay ${ENVIRONMENT}..."
apply_overlay
kubectl -n "$NAMESPACE" delete pod -l app=postgres --ignore-not-found >/dev/null 2>&1 || true

echo "Esperando disponibilidad de Postgres..."
kubectl -n "$NAMESPACE" rollout status statefulset/postgres --timeout=300s

echo "Recreando job de migracion para ejecutarlo con Postgres ya listo..."
kubectl -n "$NAMESPACE" delete job inventory-migration --ignore-not-found
kubectl -n "$NAMESPACE" wait --for=delete job/inventory-migration --timeout=120s >/dev/null 2>&1 || true
apply_overlay

echo "Esperando finalizacion de migraciones..."
kubectl -n "$NAMESPACE" wait --for=condition=complete job/inventory-migration --timeout=300s

echo "Esperando backend..."
kubectl -n "$NAMESPACE" rollout status deployment/inventory-service --timeout=300s

echo "Esperando frontend..."
kubectl -n "$NAMESPACE" rollout status deployment/web --timeout=300s

echo "Ejecutando smoke checks ${ENVIRONMENT}..."
"$SMOKE_SCRIPT" "$ENVIRONMENT" "$NAMESPACE"

echo "Despliegue ${ENVIRONMENT} completado."
