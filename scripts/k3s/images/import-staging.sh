#!/usr/bin/env bash
set -euo pipefail

REGISTRY_OWNER="${ATLAS_REGISTRY_OWNER:-albersg}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ATLAS_BACKEND_IMAGE="ghcr.io/${REGISTRY_OWNER}/atlas-inventory-service:main" \
  ATLAS_WEB_IMAGE="ghcr.io/${REGISTRY_OWNER}/atlas-web:main" \
  "$SCRIPT_DIR/import.sh"
