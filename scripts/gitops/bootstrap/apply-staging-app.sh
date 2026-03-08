#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

ARGOCD_APP_REVISION="${ARGOCD_APP_REVISION:-}"
ARGOCD_APP_PATH="${ARGOCD_APP_PATH:-}"

kubectl apply -f "$ROOT_DIR/platform/argocd/apps/project-atlas-platform.yaml"
kubectl apply -f "$ROOT_DIR/platform/argocd/apps/atlas-platform-staging.yaml"
kubectl -n argocd delete application atlas-platform-dev --ignore-not-found >/dev/null 2>&1 || true

if [[ -n "$ARGOCD_APP_PATH" ]]; then
  kubectl -n argocd patch application atlas-platform-staging \
    --type merge \
    --patch "{\"spec\":{\"source\":{\"path\":\"${ARGOCD_APP_PATH}\"}}}"

  echo "Argo CD staging application patched to source path: ${ARGOCD_APP_PATH}"
fi

if [[ -n "$ARGOCD_APP_REVISION" ]]; then
  kubectl -n argocd patch application atlas-platform-staging \
    --type merge \
    --patch "{\"spec\":{\"source\":{\"targetRevision\":\"${ARGOCD_APP_REVISION}\"}}}"

  echo "Argo CD staging application patched to target revision: ${ARGOCD_APP_REVISION}"
fi

echo "Argo CD staging application applied. Use argocd UI or CLI to inspect sync status."
