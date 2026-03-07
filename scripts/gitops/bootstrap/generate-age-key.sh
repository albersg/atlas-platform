#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
AGE_KEY_FILE="$ROOT_DIR/.gitops-local/age/keys.txt"

"$ROOT_DIR/scripts/gitops/bootstrap/install-tools.sh" >/dev/null
mkdir -p "$(dirname "$AGE_KEY_FILE")"

if [ -f "$AGE_KEY_FILE" ]; then
  echo "Age key already exists at $AGE_KEY_FILE"
else
  "$ROOT_DIR/.gitops-local/bin/age-keygen" -o "$AGE_KEY_FILE"
fi

echo "Public key: $("$ROOT_DIR/.gitops-local/bin/age-keygen" -y "$AGE_KEY_FILE")"
