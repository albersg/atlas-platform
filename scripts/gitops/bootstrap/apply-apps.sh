#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

ARGOCD_APP_REVISION="${ARGOCD_APP_REVISION:-}"
ARGOCD_APP_PATH="${ARGOCD_APP_PATH:-}"

apply_staging_application() {
  local source_file="$ROOT_DIR/platform/argocd/apps/atlas-platform-staging.yaml"

  if [[ -z "$ARGOCD_APP_PATH" && -z "$ARGOCD_APP_REVISION" ]]; then
    kubectl apply -f "$source_file"
    return
  fi

  local tmp_file
  tmp_file="$(mktemp)"
  trap 'rm -f "$tmp_file"' RETURN

  python - "$source_file" "$tmp_file" "$ARGOCD_APP_PATH" "$ARGOCD_APP_REVISION" <<'PY'
from pathlib import Path
import sys

source_path = Path(sys.argv[1])
target_path = Path(sys.argv[2])
app_path = sys.argv[3]
app_revision = sys.argv[4]

content = source_path.read_text()

if app_path:
    content = content.replace(
        "    path: platform/k8s/overlays/staging",
        f"    path: {app_path}",
    )

if app_revision:
    content = content.replace(
        "    targetRevision: main",
        f"    targetRevision: {app_revision}",
    )

target_path.write_text(content)
PY

  kubectl apply -f "$tmp_file"
}

if [[ -z "$ARGOCD_APP_PATH" && -z "$ARGOCD_APP_REVISION" ]]; then
  kubectl apply -k "$ROOT_DIR/platform/argocd/apps"
else
  kubectl apply -f "$ROOT_DIR/platform/argocd/apps/project-atlas-platform.yaml"
  apply_staging_application
fi

kubectl -n argocd delete application atlas-platform-dev --ignore-not-found >/dev/null 2>&1 || true

if [[ -n "$ARGOCD_APP_PATH" ]]; then
  echo "Argo CD staging application patched to source path: ${ARGOCD_APP_PATH}"
fi

if [[ -n "$ARGOCD_APP_REVISION" ]]; then
  echo "Argo CD applications patched to target revision: ${ARGOCD_APP_REVISION}"
fi

echo "Argo CD staging application bundle applied. Use argocd UI or CLI to inspect sync status."
