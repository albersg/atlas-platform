#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

ARGOCD_APP_REVISION="${ARGOCD_APP_REVISION:-}"
ARGOCD_APP_PATH="${ARGOCD_APP_PATH:-}"
ARGOCD_ENVIRONMENT="${ARGOCD_ENVIRONMENT:-}"

if [[ -z "$ARGOCD_ENVIRONMENT" ]]; then
  if [[ "$ARGOCD_APP_PATH" = *"staging-local"* ]]; then
    ARGOCD_ENVIRONMENT="staging-local"
  else
    ARGOCD_ENVIRONMENT="staging"
  fi
fi

patch_application() {
  local source_file="$1"
  local app_name="$2"
  local tmp_file

  tmp_file="$(mktemp)"
  trap 'rm -f "$tmp_file"' RETURN

  python - "$source_file" "$tmp_file" "$app_name" "$ARGOCD_APP_PATH" "$ARGOCD_APP_REVISION" "$ARGOCD_ENVIRONMENT" <<'PY'
from pathlib import Path
import sys

source_path = Path(sys.argv[1])
target_path = Path(sys.argv[2])
app_name = sys.argv[3]
app_path = sys.argv[4]
app_revision = sys.argv[5]
environment = sys.argv[6]

content = source_path.read_text(encoding="utf-8")

if app_name == "atlas-platform-staging" and app_path:
    content = content.replace(
        "    path: platform/k8s/overlays/staging",
        f"    path: {app_path}",
    )

if app_revision:
    content = content.replace(
        "    targetRevision: main",
        f"    targetRevision: {app_revision}",
    )

if app_name != "atlas-platform-staging":
    content = content.replace(
        "        - values-staging-local.yaml",
        f"        - values-{environment}.yaml",
    )

target_path.write_text(content, encoding="utf-8")
PY

  kubectl apply -f "$tmp_file"
}

kubectl apply -f "$ROOT_DIR/platform/argocd/apps/project-atlas-platform.yaml"
kubectl apply -f "$ROOT_DIR/platform/argocd/apps/project-atlas-platform-infra.yaml"

for app_name in atlas-platform-istio-base atlas-platform-istiod atlas-platform-istio-ingress atlas-platform-staging; do
  patch_application "$ROOT_DIR/platform/argocd/apps/${app_name}.yaml" "$app_name"
done

kubectl -n argocd delete application atlas-platform-dev --ignore-not-found >/dev/null 2>&1 || true

if [[ -n "$ARGOCD_APP_PATH" ]]; then
  echo "Argo CD staging application patched to source path: ${ARGOCD_APP_PATH}"
fi

if [[ -n "$ARGOCD_APP_REVISION" ]]; then
  echo "Argo CD applications patched to target revision: ${ARGOCD_APP_REVISION}"
fi

echo "Argo CD infra values target: ${ARGOCD_ENVIRONMENT}"

echo "Argo CD staging topology bundle applied. Use argocd UI or CLI to inspect infra and workload sync status."
