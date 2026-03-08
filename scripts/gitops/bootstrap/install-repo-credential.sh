#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
KEY_FILE="$ROOT_DIR/.gitops-local/ssh/argocd-repo"
GITOPS_REPO_URL="${GITOPS_REPO_URL:-git@github.com:albersg/atlas-platform.git}"
ARGOCD_REPO_SECRET_NAME="${ARGOCD_REPO_SECRET_NAME:-argocd-repo-atlas-platform}"

if [ ! -f "$KEY_FILE" ]; then
  echo "Deploy key not found. Run scripts/gitops/bootstrap/generate-repo-deploy-key.sh first." >&2
  exit 1
fi

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${ARGOCD_REPO_SECRET_NAME}
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: ${GITOPS_REPO_URL}
  sshPrivateKey: |
$(sed 's/^/    /' "$KEY_FILE")
EOF

echo "Installed Argo CD repository credential secret for ${GITOPS_REPO_URL}"
