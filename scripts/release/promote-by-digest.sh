#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  cat >&2 <<'EOF'
Uso: ./scripts/release/promote-by-digest.sh <staging> <inventory-digest> <web-digest>
Ejemplo:
  ./scripts/release/promote-by-digest.sh staging sha256:abc sha256:def
EOF
  exit 1
fi

ENVIRONMENT="$1"
INVENTORY_DIGEST="$2"
WEB_DIGEST="$3"

case "$ENVIRONMENT" in
  staging) ;;
  *)
    echo "Entorno no soportado: $ENVIRONMENT" >&2
    exit 1
    ;;
esac

for digest in "$INVENTORY_DIGEST" "$WEB_DIGEST"; do
  case "$digest" in
    sha256:*) ;;
    *)
      echo "Digest invalido: $digest" >&2
      exit 1
      ;;
  esac
done

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TARGET_FILE="$ROOT_DIR/platform/k8s/components/images/$ENVIRONMENT/kustomization.yaml"
REGISTRY_OWNER="${ATLAS_REGISTRY_OWNER:-albersg}"

python - "$TARGET_FILE" "$INVENTORY_DIGEST" "$WEB_DIGEST" "$REGISTRY_OWNER" <<'PY'
from __future__ import annotations

import pathlib
import sys

target = pathlib.Path(sys.argv[1])
inventory_digest = sys.argv[2]
web_digest = sys.argv[3]
registry_owner = sys.argv[4]

target.write_text(
    """apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component

images:
  - name: ghcr.io/{registry_owner}/atlas-inventory-service
    newName: ghcr.io/{registry_owner}/atlas-inventory-service
    digest: {inventory_digest}
  - name: ghcr.io/{registry_owner}/atlas-web
    newName: ghcr.io/{registry_owner}/atlas-web
    digest: {web_digest}
""".format(
        registry_owner=registry_owner,
        inventory_digest=inventory_digest,
        web_digest=web_digest,
    ),
    encoding="utf-8",
)
PY

echo "Actualizado ${TARGET_FILE} con digests inmutables para ${ENVIRONMENT}."
