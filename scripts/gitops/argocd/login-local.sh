#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

"$ROOT_DIR/scripts/gitops/bootstrap/install-tools.sh" >/dev/null
kubectl -n argocd port-forward svc/argocd-server 8081:80 >/tmp/argocd-port-forward.log 2>&1 &
PORT_FORWARD_PID=$!
trap 'kill "$PORT_FORWARD_PID" >/dev/null 2>&1 || true' EXIT
sleep 5

PASSWORD="$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
"$ROOT_DIR/.gitops-local/bin/argocd" login localhost:8081 --username admin --password "$PASSWORD" --insecure

echo "Argo CD logged in on localhost:8081"
