#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"

CONTAINER_CLI="${CONTAINER_CLI:-docker}"
HELPER_NAMESPACE="${HELPER_NAMESPACE:-default}"
HELPER_POD_NAME="${HELPER_POD_NAME:-atlas-image-import-helper}"

if [ -z "${ATLAS_BACKEND_IMAGE:-}" ] || [ -z "${ATLAS_WEB_IMAGE:-}" ]; then
  load_k3s_dev_images
fi

if ! command -v "${CONTAINER_CLI}" >/dev/null 2>&1; then
  echo "${CONTAINER_CLI} no esta instalado o no esta en PATH" >&2
  exit 1
fi

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl no esta instalado o no esta en PATH" >&2
  exit 1
fi

if ! command -v k3s >/dev/null 2>&1; then
  echo "k3s no esta instalado en este host o no esta en PATH" >&2
  exit 1
fi

NODE_COUNT="$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')"
if [ "$NODE_COUNT" -ne 1 ] && [ "${ALLOW_MULTI_NODE_IMAGE_IMPORT:-0}" != "1" ]; then
  cat >&2 <<'EOF'
La importacion local de imagenes soporta solo clusters k3s de un nodo por defecto.
Si realmente quieres continuar en un cluster multinodo, exporta ALLOW_MULTI_NODE_IMAGE_IMPORT=1
y asume la responsabilidad de importar las imagenes manualmente en todos los nodos.
EOF
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

import_image_with_sudo() {
  local image="$1"
  local tar_file
  tar_file="$(mktemp -t atlas-image-XXXXXX.tar)"

  echo "Exportando ${image} a ${tar_file}..."
  "${CONTAINER_CLI}" save -o "${tar_file}" "${image}"

  echo "Importando ${image} en containerd de k3s..."
  sudo k3s ctr images import "${tar_file}"

  rm -f "${tar_file}"
}

import_images_with_helper_pod() {
  echo "No hay sudo no interactivo disponible; usando pod auxiliar para importar imagenes..."

  local node_name
  node_name="$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')"

  kubectl -n "${HELPER_NAMESPACE}" delete pod "${HELPER_POD_NAME}" --ignore-not-found >/dev/null 2>&1 || true

  kubectl -n "${HELPER_NAMESPACE}" apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${HELPER_POD_NAME}
spec:
  nodeName: ${node_name}
  restartPolicy: Never
  initContainers:
    - name: export-images
      image: alpine:3.20
      command:
        - /bin/sh
        - -ec
        - |
          apk add --no-cache docker-cli
          docker -H unix:///var/run/docker.sock save -o /workspace/atlas-inventory-service-dev.tar ${ATLAS_BACKEND_IMAGE}
          docker -H unix:///var/run/docker.sock save -o /workspace/atlas-web-dev.tar ${ATLAS_WEB_IMAGE}
      volumeMounts:
        - name: workspace
          mountPath: /workspace
        - name: docker-sock
          mountPath: /var/run/docker.sock
  containers:
    - name: import-images
      image: rancher/k3s:v1.34.5-k3s1
      command:
        - /bin/sh
        - -ec
        - |
          ctr -a /run/k3s/containerd/containerd.sock -n k8s.io images import /workspace/atlas-inventory-service-dev.tar
          ctr -a /run/k3s/containerd/containerd.sock -n k8s.io images import /workspace/atlas-web-dev.tar
      securityContext:
        privileged: true
      volumeMounts:
        - name: workspace
          mountPath: /workspace
        - name: containerd-sock
          mountPath: /run/k3s/containerd/containerd.sock
  volumes:
    - name: workspace
      emptyDir: {}
    - name: docker-sock
      hostPath:
        path: /var/run/docker.sock
        type: Socket
    - name: containerd-sock
      hostPath:
        path: /run/k3s/containerd/containerd.sock
        type: Socket
EOF

  kubectl -n "${HELPER_NAMESPACE}" wait --for=jsonpath='{.status.phase}'=Succeeded "pod/${HELPER_POD_NAME}" --timeout=300s
  kubectl -n "${HELPER_NAMESPACE}" logs "${HELPER_POD_NAME}"
  kubectl -n "${HELPER_NAMESPACE}" delete pod "${HELPER_POD_NAME}" --ignore-not-found >/dev/null 2>&1 || true
}

if sudo -n true >/dev/null 2>&1; then
  import_image_with_sudo "${ATLAS_BACKEND_IMAGE}"
  import_image_with_sudo "${ATLAS_WEB_IMAGE}"
else
  import_images_with_helper_pod
fi

echo "Importacion completada para ${ATLAS_BACKEND_IMAGE} y ${ATLAS_WEB_IMAGE}."
