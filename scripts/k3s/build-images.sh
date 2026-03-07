#!/usr/bin/env bash
set -euo pipefail

CONTAINER_CLI="${CONTAINER_CLI:-docker}"
MAX_TRIES="${MAX_TRIES:-4}"

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
  -t atlas-inventory-service:dev \
  -f services/inventory-service/Dockerfile \
  services/inventory-service

echo "Construyendo imagen frontend..."
retry "Build frontend" "${CONTAINER_CLI}" build \
  -t atlas-web:dev \
  -f apps/web/Dockerfile \
  apps/web

echo "Imagenes locales listas: atlas-inventory-service:dev y atlas-web:dev"
