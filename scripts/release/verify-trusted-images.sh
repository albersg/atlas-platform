#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TARGET_FILE="${1:-$ROOT_DIR/platform/k8s/components/images/staging/kustomization.yaml}"
TOOLS_DIR="$ROOT_DIR/.gitops-local/bin"
COSIGN_BIN="$TOOLS_DIR/cosign"
REGISTRY_OWNER="${ATLAS_REGISTRY_OWNER:-albersg}"
GITHUB_REPOSITORY="${ATLAS_GITHUB_REPOSITORY:-${REGISTRY_OWNER}/atlas-platform}"
WORKFLOW_PATH="${ATLAS_TRUST_WORKFLOW_PATH:-.github/workflows/release-images.yml}"
OIDC_ISSUER="${ATLAS_TRUST_OIDC_ISSUER:-https://token.actions.githubusercontent.com}"
WORKFLOW_PATH_REGEX="${WORKFLOW_PATH//./\\.}"
IDENTITY_REGEX="^https://github.com/${GITHUB_REPOSITORY}/${WORKFLOW_PATH_REGEX}@refs/heads/main$"
DRY_RUN="${ATLAS_TRUST_VERIFY_DRY_RUN:-0}"
PLACEHOLDER_DIGESTS=(
  "sha256:0000000000000000000000000000000000000000000000000000000000000000"
  "sha256:1111111111111111111111111111111111111111111111111111111111111111"
)

if [[ ! -f "$TARGET_FILE" ]]; then
  echo "No existe el archivo de imagenes canonicas: $TARGET_FILE" >&2
  exit 1
fi

IMAGE_REFS_OUTPUT="$({
  python - "$TARGET_FILE" "$REGISTRY_OWNER" "${PLACEHOLDER_DIGESTS[@]}" <<'PY'
from __future__ import annotations

import pathlib
import sys

allowed = {
    f"ghcr.io/{sys.argv[2]}/atlas-inventory-service",
    f"ghcr.io/{sys.argv[2]}/atlas-web",
}
placeholders = set(sys.argv[3:])
entries: list[str] = []
current_name: str | None = None
current_digest: str | None = None

for raw_line in pathlib.Path(sys.argv[1]).read_text(encoding="utf-8").splitlines():
    line = raw_line.strip()
    if line.startswith("newName: "):
        current_name = line.split(": ", 1)[1]
    elif line.startswith("digest: "):
        current_digest = line.split(": ", 1)[1]

    if current_name and current_digest:
        if current_name not in allowed:
            raise SystemExit(f"image fuera de la allowlist de staging canonico: {current_name}")
        if current_digest in placeholders:
            raise SystemExit(
                "staging canonico todavia usa digests placeholder; primero publica imagenes reales y firmadas con "
                "release-images.yml y luego vuelve a promover staging"
            )
        entries.append(f"{current_name}@{current_digest}")
        current_name = None
        current_digest = None

if len(entries) != 2:
    raise SystemExit(f"se esperaban 2 imagenes canonicas para staging y se obtuvieron {len(entries)}")

for entry in entries:
    print(entry)
PY
})"
mapfile -t IMAGE_REFS <<<"$IMAGE_REFS_OUTPUT"

"$ROOT_DIR/scripts/gitops/bootstrap/install-tools.sh" >/dev/null

if [[ ! -x "$COSIGN_BIN" ]]; then
  echo "Falta cosign en $COSIGN_BIN. Ejecuta 'mise run gitops-install-tools'." >&2
  exit 1
fi

for image_ref in "${IMAGE_REFS[@]}"; do
  echo "Verificando firma Cosign para ${image_ref}"

  if [[ "$DRY_RUN" = "1" ]]; then
    echo "DRY_RUN: $COSIGN_BIN verify --certificate-oidc-issuer $OIDC_ISSUER --certificate-identity-regexp $IDENTITY_REGEX $image_ref"
    continue
  fi

  verify_output_file="$(mktemp)"
  if ! "$COSIGN_BIN" verify \
    --certificate-oidc-issuer "$OIDC_ISSUER" \
    --certificate-identity-regexp "$IDENTITY_REGEX" \
    "$image_ref" >/dev/null 2>"$verify_output_file"; then
    cat "$verify_output_file" >&2
    rm -f "$verify_output_file"
    cat >&2 <<EOF
No se pudo verificar ${image_ref}.
Prerequisito externo faltante: el digest debe existir en GHCR y tener una firma Cosign disponible para ${GITHUB_REPOSITORY}.
Si GHCR devuelve acceso denegado, publica la imagen con release-images.yml o usa credenciales con acceso de lectura a paquetes GHCR antes de reintentar.
EOF
    exit 1
  fi
  rm -f "$verify_output_file"
done

echo "Validacion de confianza: las imagenes canonicas de staging tienen firmas verificables."
