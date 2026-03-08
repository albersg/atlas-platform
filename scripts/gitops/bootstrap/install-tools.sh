#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TOOLS_DIR="$ROOT_DIR/.gitops-local/bin"
PLUGIN_DIR="$ROOT_DIR/.gitops-local/xdg/kustomize/plugin/viaduct.ai/v1/ksops"
AGE_VERSION="v1.2.1"
AGE_SHA256="7df45a6cc87d4da11cc03a539a7470c15b1041ab2b396af088fe9990f7c79d50" # pragma: allowlist secret
SOPS_VERSION="v3.10.2"
SOPS_SHA256="79b0f844237bd4b0446e4dc884dbc1765fc7dedc3968f743d5949c6f2e701739" # pragma: allowlist secret
ARGOCD_VERSION="v2.13.3"
ARGOCD_SHA256="24699b29efe24ef7cce463b54fc0341f6496d97a7c54c9fccaa737e8eb99296f" # pragma: allowlist secret
KUSTOMIZE_VERSION="v5.4.3"
KUSTOMIZE_SHA256="3669470b454d865c8184d6bce78df05e977c9aea31c30df3c669317d43bcc7a7" # pragma: allowlist secret
KSOPS_VERSION="v4.4.0"
KSOPS_SHA256="72973ce5a97d7ad0318c9f6ae4df2aa94a4a564c45fdf71772b759dff4df0cb4" # pragma: allowlist secret

mkdir -p "$TOOLS_DIR" "$PLUGIN_DIR"

verify_sha256() {
  local expected_sha256="$1"
  local file_path="$2"

  if command -v sha256sum >/dev/null 2>&1; then
    printf '%s  %s\n' "$expected_sha256" "$file_path" | sha256sum -c - >/dev/null
    return 0
  fi

  if command -v shasum >/dev/null 2>&1; then
    printf '%s  %s\n' "$expected_sha256" "$file_path" | shasum -a 256 -c - >/dev/null
    return 0
  fi

  python - "$expected_sha256" "$file_path" <<'PY'
from __future__ import annotations

import hashlib
import pathlib
import sys

expected = sys.argv[1]
actual = hashlib.sha256(pathlib.Path(sys.argv[2]).read_bytes()).hexdigest()
if actual != expected:
    raise SystemExit(f"sha256 mismatch: expected {expected}, got {actual}")
PY
}

download() {
  local url="$1"
  local output="$2"
  local expected_sha256="$3"
  if [ -x "$output" ]; then
    return 0
  fi

  local tmp_file
  tmp_file="$(mktemp)"
  curl --retry 5 --retry-delay 2 --retry-all-errors -fsSL "$url" -o "$tmp_file"
  verify_sha256 "$expected_sha256" "$tmp_file"
  mv "$tmp_file" "$output"
  chmod +x "$output"
}

download_archive_binary() {
  local url="$1"
  local binary_name="$2"
  local output="$3"
  local expected_sha256="$4"
  if [ -x "$output" ]; then
    return 0
  fi
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  curl --retry 5 --retry-delay 2 --retry-all-errors -fsSL "$url" -o "$tmp_dir/archive.tgz"
  verify_sha256 "$expected_sha256" "$tmp_dir/archive.tgz"
  tar -xzf "$tmp_dir/archive.tgz" -C "$tmp_dir"
  cp -f "$tmp_dir/$binary_name" "$output"
  chmod +x "$output"
  rm -rf "$tmp_dir"
}

download_archive_binary "https://github.com/FiloSottile/age/releases/download/${AGE_VERSION}/age-${AGE_VERSION}-linux-amd64.tar.gz" "age/age" "$TOOLS_DIR/age" "$AGE_SHA256"
download_archive_binary "https://github.com/FiloSottile/age/releases/download/${AGE_VERSION}/age-${AGE_VERSION}-linux-amd64.tar.gz" "age/age-keygen" "$TOOLS_DIR/age-keygen" "$AGE_SHA256"
download "https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.amd64" "$TOOLS_DIR/sops" "$SOPS_SHA256"
download "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-amd64" "$TOOLS_DIR/argocd" "$ARGOCD_SHA256"
download_archive_binary "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" "kustomize" "$TOOLS_DIR/kustomize" "$KUSTOMIZE_SHA256"
download_archive_binary "https://github.com/viaduct-ai/kustomize-sops/releases/download/${KSOPS_VERSION}/ksops_${KSOPS_VERSION#v}_Linux_x86_64.tar.gz" "ksops" "$TOOLS_DIR/ksops" "$KSOPS_SHA256"

ln -sf "$TOOLS_DIR/ksops" "$PLUGIN_DIR/ksops"

echo "GitOps tools installed in $TOOLS_DIR"
