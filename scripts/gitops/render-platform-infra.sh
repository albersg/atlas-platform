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
HELM_HOME_DIR="$ROOT_DIR/.gitops-local/helm"

case "$ENVIRONMENT" in
  staging-local | staging) ;;
  *)
    echo "Unsupported environment: ${ENVIRONMENT}" >&2
    exit 1
    ;;
esac

"$ROOT_DIR/scripts/gitops/bootstrap/install-tools.sh" >/dev/null

mkdir -p "$HELM_HOME_DIR/cache" "$HELM_HOME_DIR/config" "$HELM_HOME_DIR/data"

if [[ ! -x "$HELM_BIN" ]]; then
  echo "Missing local Helm helper. Run 'mise run gitops-install-tools'." >&2
  exit 1
fi

ensure_helm_repos() {
  PATH="$TOOLS_DIR:$PATH" \
    HELM_CACHE_HOME="$HELM_HOME_DIR/cache" \
    HELM_CONFIG_HOME="$HELM_HOME_DIR/config" \
    HELM_DATA_HOME="$HELM_HOME_DIR/data" \
    "$HELM_BIN" repo add atlas-istio https://istio-release.storage.googleapis.com/charts --force-update >/dev/null
  PATH="$TOOLS_DIR:$PATH" \
    HELM_CACHE_HOME="$HELM_HOME_DIR/cache" \
    HELM_CONFIG_HOME="$HELM_HOME_DIR/config" \
    HELM_DATA_HOME="$HELM_HOME_DIR/data" \
    "$HELM_BIN" repo add atlas-prometheus https://prometheus-community.github.io/helm-charts --force-update >/dev/null
}

ensure_helm_repos

platform_infra_inventory() {
  printf '%s\n' \
    'atlas-platform-istio-base|platform/helm/istio/base|istio-system' \
    'atlas-platform-istiod|platform/helm/istio/istiod|istio-system' \
    'atlas-platform-istio-ingress|platform/helm/istio/gateway|istio-system' \
    'atlas-platform-prometheus|platform/helm/prometheus/kube-prometheus-stack|monitoring'
}

render_chart() {
  local release_name="$1"
  local chart_path="$2"
  local namespace="$3"
  local chart_dir="$ROOT_DIR/$chart_path"
  local temp_dir

  temp_dir="$(mktemp -d)"
  cp -R "$chart_dir/." "$temp_dir/"
  PATH="$TOOLS_DIR:$PATH" \
    HELM_CACHE_HOME="$HELM_HOME_DIR/cache" \
    HELM_CONFIG_HOME="$HELM_HOME_DIR/config" \
    HELM_DATA_HOME="$HELM_HOME_DIR/data" \
    "$HELM_BIN" dependency build "$temp_dir" >/dev/null
  PATH="$TOOLS_DIR:$PATH" \
    HELM_CACHE_HOME="$HELM_HOME_DIR/cache" \
    HELM_CONFIG_HOME="$HELM_HOME_DIR/config" \
    HELM_DATA_HOME="$HELM_HOME_DIR/data" \
    "$HELM_BIN" template "$release_name" "$temp_dir" \
    --namespace "$namespace" \
    --include-crds \
    -f "$temp_dir/values-common.yaml" \
    -f "$temp_dir/values-${ENVIRONMENT}.yaml"
  rm -rf "$temp_dir"
}

first_chart=1
while IFS='|' read -r release_name chart_path namespace; do
  if [[ "$first_chart" -eq 0 ]]; then
    printf '\n'
  fi
  render_chart "$release_name" "$chart_path" "$namespace"
  first_chart=0
done < <(platform_infra_inventory)
