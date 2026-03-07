#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
AGE_KEY_FILE="$ROOT_DIR/.gitops-local/age/keys.txt"

if [ ! -f "$AGE_KEY_FILE" ]; then
  echo "Age key not found. Run scripts/gitops/bootstrap/generate-age-key.sh first." >&2
  exit 1
fi

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl -n argocd create secret generic argocd-sops-age-key \
  --from-file=keys.txt="$AGE_KEY_FILE" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Installed argocd-sops-age-key secret in namespace argocd"
