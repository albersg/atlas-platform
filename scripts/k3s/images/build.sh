#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"

CONTAINER_CLI="${CONTAINER_CLI:-docker}"
MAX_TRIES="${MAX_TRIES:-4}"
IMAGE_TAG="${IMAGE_TAG:-dev-$(date +%Y%m%d%H%M%S)}"
BACKEND_IMAGE="atlas-inventory-service:${IMAGE_TAG}"
WEB_IMAGE="atlas-web:${IMAGE_TAG}"

if ! command -v "${CONTAINER_CLI}" >/dev/null 2>&1; then
  echo "${CONTAINER_CLI} no esta instalado o no esta en PATH" >&2
  exit 1
fi

if [ "${CONTAINER_CLI}" = "docker" ] && ! docker info >/dev/null 2>&1; then
  cat >&2 <<'EOF'
No se puede conectar a Docker daemon.
Opciones:
  1) Levantar Docker:
     sudo systemctl enable --now docker
  2) Ejecutar con Podman:
     CONTAINER_CLI=podman mise run k8s-build-images
EOF
  exit 1
fi

retry() {
  local description="$1"
  shift
  local attempt=1
  while [ "$attempt" -le "$MAX_TRIES" ]; do
    echo "${description} (intento ${attempt}/${MAX_TRIES})..."
    if "$@"; then
      return 0
    fi
    if [ "$attempt" -eq "$MAX_TRIES" ]; then
      echo "Fallo definitivo en: ${description}" >&2
      return 1
    fi
    sleep 3
    attempt=$((attempt + 1))
  done
}

echo "Construyendo imagen backend..."
retry "Build backend" "${CONTAINER_CLI}" build \
  -t "${BACKEND_IMAGE}" \
  -f services/inventory-service/Dockerfile \
  services/inventory-service

echo "Construyendo imagen frontend..."
retry "Build frontend" "${CONTAINER_CLI}" build \
  -t "${WEB_IMAGE}" \
  -f apps/web/Dockerfile \
  apps/web

ensure_k3s_image_state_dir
cat >"${K3S_IMAGE_STATE_FILE}" <<EOF
ATLAS_IMAGE_TAG=${IMAGE_TAG}
ATLAS_BACKEND_IMAGE=${BACKEND_IMAGE}
ATLAS_WEB_IMAGE=${WEB_IMAGE}
EOF

echo "Imagenes locales listas: ${BACKEND_IMAGE} y ${WEB_IMAGE}"
echo "Estado guardado en ${K3S_IMAGE_STATE_FILE}"
