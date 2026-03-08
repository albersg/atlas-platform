#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

ARGOCD_APP_REVISION="${ARGOCD_APP_REVISION:-}"

kubectl apply -k "$ROOT_DIR/platform/argocd/apps"
kubectl -n argocd delete application atlas-platform-dev --ignore-not-found >/dev/null 2>&1 || true

if [[ -n "$ARGOCD_APP_REVISION" ]]; then
  kubectl -n argocd patch application atlas-platform-staging \
    --type merge \
    --patch "{\"spec\":{\"source\":{\"targetRevision\":\"${ARGOCD_APP_REVISION}\"}}}"

  echo "Argo CD applications patched to target revision: ${ARGOCD_APP_REVISION}"
fi

echo "Argo CD staging application bundle applied. Use argocd UI or CLI to inspect sync status."
