#!/usr/bin/env bash
set -euo pipefail

"$(dirname "$0")/nonprod.sh" dev atlas-platform-dev platform/k8s/overlays/dev
