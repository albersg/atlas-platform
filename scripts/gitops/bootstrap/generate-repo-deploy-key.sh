#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
KEY_FILE="$ROOT_DIR/.gitops-local/ssh/argocd-repo"

mkdir -p "$(dirname "$KEY_FILE")"

if [ ! -f "$KEY_FILE" ]; then
  ssh-keygen -t ed25519 -N "" -C "argocd-repo@atlas-platform" -f "$KEY_FILE" >/dev/null
fi

echo "Public key to register as GitHub deploy key:"
cat "$KEY_FILE.pub"
