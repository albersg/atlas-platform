#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TOOLS_DIR="$ROOT_DIR/.gitops-local/bin"
PLUGIN_DIR="$ROOT_DIR/.gitops-local/xdg/kustomize/plugin/viaduct.ai/v1/ksops"
AGE_VERSION="v1.2.1"
SOPS_VERSION="v3.10.2"
ARGOCD_VERSION="v2.13.3"
KUSTOMIZE_VERSION="v5.4.3"
KSOPS_VERSION="v4.4.0"

mkdir -p "$TOOLS_DIR" "$PLUGIN_DIR"

download() {
  local url="$1"
  local output="$2"
  if [ -x "$output" ]; then
    return 0
  fi
  curl -fsSL "$url" -o "$output"
  chmod +x "$output"
}

download_archive_binary() {
  local url="$1"
  local binary_name="$2"
  local output="$3"
  if [ -x "$output" ]; then
    return 0
  fi
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  curl -fsSL "$url" -o "$tmp_dir/archive.tgz"
  tar -xzf "$tmp_dir/archive.tgz" -C "$tmp_dir"
  cp -f "$tmp_dir/$binary_name" "$output"
  chmod +x "$output"
  rm -rf "$tmp_dir"
}

download_archive_binary "https://github.com/FiloSottile/age/releases/download/${AGE_VERSION}/age-${AGE_VERSION}-linux-amd64.tar.gz" "age/age" "$TOOLS_DIR/age"
download_archive_binary "https://github.com/FiloSottile/age/releases/download/${AGE_VERSION}/age-${AGE_VERSION}-linux-amd64.tar.gz" "age/age-keygen" "$TOOLS_DIR/age-keygen"
download "https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.amd64" "$TOOLS_DIR/sops"
download "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-amd64" "$TOOLS_DIR/argocd"
download_archive_binary "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" "kustomize" "$TOOLS_DIR/kustomize"
download_archive_binary "https://github.com/viaduct-ai/kustomize-sops/releases/download/${KSOPS_VERSION}/ksops_${KSOPS_VERSION#v}_Linux_x86_64.tar.gz" "ksops" "$TOOLS_DIR/ksops"

ln -sf "$TOOLS_DIR/ksops" "$PLUGIN_DIR/ksops"

echo "GitOps tools installed in $TOOLS_DIR"
