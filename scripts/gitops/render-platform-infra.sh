#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -ne 1 ]]; then
  echo "Usage: $0 <staging-local|staging>" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENVIRONMENT="$1"
TOOLS_DIR="$ROOT_DIR/.gitops-local/bin"
HELM_BIN="$TOOLS_DIR/helm"

case "$ENVIRONMENT" in
  staging-local | staging) ;;
  *)
    echo "Unsupported environment: ${ENVIRONMENT}" >&2
    exit 1
    ;;
esac

"$ROOT_DIR/scripts/gitops/bootstrap/install-tools.sh" >/dev/null

if [[ ! -x "$HELM_BIN" ]]; then
  echo "Missing local Helm helper. Run 'mise run gitops-install-tools'." >&2
  exit 1
fi

render_chart() {
  local chart_name="$1"
  local release_name="$2"
  local chart_dir="$ROOT_DIR/platform/helm/istio/${chart_name}"
  local temp_dir

  temp_dir="$(mktemp -d)"
  cp -R "$chart_dir/." "$temp_dir/"
  PATH="$TOOLS_DIR:$PATH" "$HELM_BIN" dependency build "$temp_dir" >/dev/null
  PATH="$TOOLS_DIR:$PATH" "$HELM_BIN" template "$release_name" "$temp_dir" \
    --namespace istio-system \
    --include-crds \
    -f "$temp_dir/values-common.yaml" \
    -f "$temp_dir/values-${ENVIRONMENT}.yaml"
  rm -rf "$temp_dir"
}

render_chart base atlas-platform-istio-base
printf '\n---\n'
render_chart istiod atlas-platform-istiod
printf '\n---\n'
render_chart gateway atlas-platform-istio-ingress
