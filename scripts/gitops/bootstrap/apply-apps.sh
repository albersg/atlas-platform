#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

ARGOCD_APP_REVISION="${ARGOCD_APP_REVISION:-}"

kubectl apply -k "$ROOT_DIR/platform/argocd/apps"

if [[ -n "$ARGOCD_APP_REVISION" ]]; then
  for app in atlas-platform-dev atlas-platform-prod; do
    kubectl -n argocd patch application "$app" \
      --type merge \
      --patch "{\"spec\":{\"source\":{\"targetRevision\":\"${ARGOCD_APP_REVISION}\"}}}"
  done

  echo "Argo CD applications patched to target revision: ${ARGOCD_APP_REVISION}"
fi

echo "Argo CD applications applied. Use argocd UI or CLI to inspect sync status."
