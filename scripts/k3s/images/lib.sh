#!/usr/bin/env bash

K3S_IMAGE_STATE_DIR="${K3S_IMAGE_STATE_DIR:-.gitops-local/k3s}"
K3S_IMAGE_STATE_FILE="${K3S_IMAGE_STATE_FILE:-${K3S_IMAGE_STATE_DIR}/dev-images.env}"

ensure_k3s_image_state_dir() {
  mkdir -p "${K3S_IMAGE_STATE_DIR}"
}

load_k3s_dev_images() {
  if [ ! -f "${K3S_IMAGE_STATE_FILE}" ]; then
    cat >&2 <<EOF
Missing ${K3S_IMAGE_STATE_FILE}.
Run 'mise run k8s-build-images' before importing or deploying dev images.
EOF
    return 1
  fi

  # shellcheck disable=SC1090
  . "${K3S_IMAGE_STATE_FILE}"

  : "${ATLAS_BACKEND_IMAGE:?Missing ATLAS_BACKEND_IMAGE in ${K3S_IMAGE_STATE_FILE}}"
  : "${ATLAS_WEB_IMAGE:?Missing ATLAS_WEB_IMAGE in ${K3S_IMAGE_STATE_FILE}}"
}
