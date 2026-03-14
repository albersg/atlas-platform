#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
COMMON_POLICY_BUNDLE="platform/policy/kyverno/common"
STAGING_POLICY_BUNDLE="platform/policy/kyverno/staging"
TOOLS_DIR="$ROOT_DIR/.gitops-local/bin"
KUSTOMIZE_BIN="$TOOLS_DIR/kustomize"
KYVERNO_BIN="$TOOLS_DIR/kyverno"
PREFLIGHT_ONLY="${ATLAS_VALIDATE_PREFLIGHT:-0}"

render_overlay() {
  local overlay_name="$1"

  "$ROOT_DIR/scripts/gitops/render-overlay.sh" "platform/k8s/overlays/${overlay_name}" >"$TMP_DIR/${overlay_name}.yaml"
}

apply_policy_bundle() {
  local bundle_path="$1"
  local overlay_name="$2"
  local bundle_label="$3"
  local rendered_bundle_path="$TMP_DIR/${overlay_name}-${bundle_label}-policies.yaml"

  echo "Validando overlay ${overlay_name} con bundle ${bundle_label}..."
  PATH="$TOOLS_DIR:$PATH" \
    "$KUSTOMIZE_BIN" build "$ROOT_DIR/$bundle_path" >"$rendered_bundle_path"

  if [[ "$PREFLIGHT_ONLY" = "1" ]]; then
    return 0
  fi

  "$KYVERNO_BIN" apply "$rendered_bundle_path" --resource "$TMP_DIR/${overlay_name}.yaml"
}

if ! command -v docker >/dev/null 2>&1; then
  echo "docker es obligatorio para validar manifests con kubeconform y kyverno" >&2
  exit 1
fi

"$ROOT_DIR/scripts/gitops/bootstrap/install-tools.sh" >/dev/null

if [[ ! -x "$KUSTOMIZE_BIN" || ! -x "$KYVERNO_BIN" ]]; then
  echo "Faltan helpers GitOps locales. Ejecuta 'mise run gitops-install-tools'." >&2
  exit 1
fi

render_overlay dev
render_overlay staging
render_overlay staging-local
chmod 755 "$TMP_DIR"
chmod 644 "$TMP_DIR/dev.yaml" "$TMP_DIR/staging.yaml" "$TMP_DIR/staging-local.yaml"

apply_policy_bundle "$COMMON_POLICY_BUNDLE" dev common
apply_policy_bundle "$COMMON_POLICY_BUNDLE" staging common
apply_policy_bundle "$COMMON_POLICY_BUNDLE" staging-local common
apply_policy_bundle "$STAGING_POLICY_BUNDLE" staging staging-only

if [[ "$PREFLIGHT_ONLY" = "1" ]]; then
  echo "Preflight de render y bundles de politica completado."
  exit 0
fi

"$ROOT_DIR/scripts/release/verify-trusted-images.sh"

docker run --rm \
  -v "$TMP_DIR:/rendered:ro" \
  ghcr.io/yannh/kubeconform:v0.6.7 \
  -strict \
  -ignore-missing-schemas \
  /rendered/dev.yaml /rendered/staging.yaml /rendered/staging-local.yaml
