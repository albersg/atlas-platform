#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
KEY_FILE="$ROOT_DIR/.gitops-local/ssh/argocd-repo"

if [ ! -f "$KEY_FILE" ]; then
  echo "Deploy key not found. Run scripts/gitops/bootstrap/generate-repo-deploy-key.sh first." >&2
  exit 1
fi

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: argocd-repo-agent-first-codex
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: git@github.com:albersg/agent-first-codex.git
  sshPrivateKey: |
$(sed 's/^/    /' "$KEY_FILE")
EOF

echo "Installed Argo CD repository credential secret for git@github.com:albersg/agent-first-codex.git"
