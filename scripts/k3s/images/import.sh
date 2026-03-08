#!/usr/bin/env bash
set -euo pipefail

CONTAINER_CLI="${CONTAINER_CLI:-docker}"

if ! command -v "${CONTAINER_CLI}" >/dev/null 2>&1; then
  echo "${CONTAINER_CLI} no esta instalado o no esta en PATH" >&2
  exit 1
fi

if ! command -v k3s >/dev/null 2>&1; then
  echo "k3s no esta instalado en este host o no esta en PATH" >&2
  exit 1
fi

if [ "${CONTAINER_CLI}" = "docker" ] && ! docker info >/dev/null 2>&1; then
  cat >&2 <<'EOF'
No se puede conectar a Docker daemon.
Opciones:
  1) Levantar Docker:
     sudo systemctl enable --now docker
  2) Ejecutar con Podman:
     CONTAINER_CLI=podman mise run k8s-import-images
EOF
  exit 1
fi

import_image() {
  local image="$1"
  local tar_file
  tar_file="$(mktemp -t atlas-image-XXXXXX.tar)"

  echo "Exportando ${image} a ${tar_file}..."
  "${CONTAINER_CLI}" save -o "${tar_file}" "${image}"

  echo "Importando ${image} en containerd de k3s..."
  sudo k3s ctr images import "${tar_file}"

  rm -f "${tar_file}"
}

import_image "atlas-inventory-service:dev"
import_image "atlas-web:dev"

echo "Importacion completada."
