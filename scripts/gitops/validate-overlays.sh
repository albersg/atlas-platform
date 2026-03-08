#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v docker >/dev/null 2>&1; then
  echo "docker es obligatorio para validar manifests con kubeconform y kyverno" >&2
  exit 1
fi

"$ROOT_DIR/scripts/gitops/bootstrap/install-tools.sh" >/dev/null

"$ROOT_DIR/scripts/gitops/render-overlay.sh" platform/k8s/overlays/dev >"$TMP_DIR/dev.yaml"
"$ROOT_DIR/scripts/gitops/render-overlay.sh" platform/k8s/overlays/staging >"$TMP_DIR/staging.yaml"
"$ROOT_DIR/scripts/gitops/render-overlay.sh" platform/k8s/overlays/staging-local >"$TMP_DIR/staging-local.yaml"
chmod 755 "$TMP_DIR"
chmod 644 "$TMP_DIR/dev.yaml" "$TMP_DIR/staging.yaml" "$TMP_DIR/staging-local.yaml"

docker run --rm \
  -v "$TMP_DIR:/rendered:ro" \
  ghcr.io/yannh/kubeconform:v0.6.7 \
  -strict \
  -ignore-missing-schemas \
  /rendered/dev.yaml /rendered/staging.yaml /rendered/staging-local.yaml

docker run --rm \
  -v "$ROOT_DIR:/workdir:ro" \
  -v "$TMP_DIR:/rendered:ro" \
  -w /workdir \
  ghcr.io/kyverno/kyverno-cli:v1.15.0 \
  apply platform/policy/kyverno \
  --resource /rendered/dev.yaml \
  --resource /rendered/staging.yaml \
  --resource /rendered/staging-local.yaml
