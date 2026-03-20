#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <overlay-path>" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OVERLAY_PATH="$1"
HELM_HOME_DIR="$ROOT_DIR/.gitops-local/helm"

"$ROOT_DIR/scripts/gitops/bootstrap/install-tools.sh" >/dev/null

mkdir -p "$HELM_HOME_DIR/cache" "$HELM_HOME_DIR/config" "$HELM_HOME_DIR/data"

if [ ! -f "$ROOT_DIR/.gitops-local/age/keys.txt" ]; then
  echo "Missing .gitops-local/age/keys.txt. Generate/install the age key first." >&2
  exit 1
fi

PATH="$ROOT_DIR/.gitops-local/bin:$PATH" \
  XDG_CONFIG_HOME="$ROOT_DIR/.gitops-local/xdg" \
  HELM_CACHE_HOME="$HELM_HOME_DIR/cache" \
  HELM_CONFIG_HOME="$HELM_HOME_DIR/config" \
  HELM_DATA_HOME="$HELM_HOME_DIR/data" \
  SOPS_AGE_KEY_FILE="$ROOT_DIR/.gitops-local/age/keys.txt" \
  "$ROOT_DIR/.gitops-local/bin/kustomize" build --enable-alpha-plugins --enable-exec --enable-helm --load-restrictor LoadRestrictionsNone "$ROOT_DIR/$OVERLAY_PATH"
