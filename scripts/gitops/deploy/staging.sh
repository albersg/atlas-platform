#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ARGOCD_REPO_SECRET_NAME="${ARGOCD_REPO_SECRET_NAME:-argocd-repo-atlas-platform}"
STAGING_LOCAL_IMAGES="${STAGING_LOCAL_IMAGES:-1}"
ARGOCD_WAIT_TIMEOUT_SECONDS="${ARGOCD_WAIT_TIMEOUT_SECONDS:-600}"

if [[ "$STAGING_LOCAL_IMAGES" = "1" ]]; then
  : "${ARGOCD_APP_PATH:=platform/k8s/overlays/staging-local}"
  : "${ARGOCD_ENVIRONMENT:=staging-local}"

  echo "Modo staging-local: wrapper local con tags mutables solo para aprendizaje y validacion en k3s."
  echo "Preparando imagenes locales para staging..."
  "$ROOT_DIR/scripts/k3s/images/build-staging.sh"
  "$ROOT_DIR/scripts/k3s/images/import-staging.sh"
else
  : "${ARGOCD_APP_PATH:=platform/k8s/overlays/staging}"
  : "${ARGOCD_ENVIRONMENT:=staging}"
  echo "Modo staging canonico: overlay GitOps con imagenes inmutables por digest desde registry."
fi

export ARGOCD_APP_PATH
export ARGOCD_ENVIRONMENT

ATLAS_DOCTOR_SCOPE=staging "$ROOT_DIR/scripts/k3s/cluster/doctor.sh"

if [[ "$STAGING_LOCAL_IMAGES" != "1" ]]; then
  "$ROOT_DIR/scripts/release/verify-trusted-images.sh"
fi

if ! kubectl -n argocd get deployment argocd-server >/dev/null 2>&1; then
  echo "Argo CD no parece instalado. Ejecuta primero: mise run gitops-bootstrap-core" >&2
  exit 1
fi

if ! kubectl -n argocd get secret argocd-sops-age-key >/dev/null 2>&1; then
  echo "Falta argocd-sops-age-key en argocd. Ejecuta primero: mise run gitops-install-age-key" >&2
  exit 1
fi

if ! kubectl -n argocd get secret "$ARGOCD_REPO_SECRET_NAME" >/dev/null 2>&1; then
  echo "Falta la credential del repositorio en argocd. Ejecuta primero: mise run gitops-install-repo-credential" >&2
  exit 1
fi

"$ROOT_DIR/scripts/gitops/bootstrap/apply-apps.sh"
"$ROOT_DIR/scripts/gitops/wait-app.sh" atlas-platform-istio-base argocd "$ARGOCD_WAIT_TIMEOUT_SECONDS"
"$ROOT_DIR/scripts/gitops/wait-app.sh" atlas-platform-istiod argocd "$ARGOCD_WAIT_TIMEOUT_SECONDS"
"$ROOT_DIR/scripts/gitops/wait-app.sh" atlas-platform-istio-ingress argocd "$ARGOCD_WAIT_TIMEOUT_SECONDS"
"$ROOT_DIR/scripts/gitops/wait-app.sh" atlas-platform-staging argocd "$ARGOCD_WAIT_TIMEOUT_SECONDS"
"$ROOT_DIR/scripts/k3s/cluster/status.sh" atlas-platform-staging
"$ROOT_DIR/scripts/k3s/verify/smoke.sh" staging atlas-platform-staging staging.atlas.example.com api.staging.atlas.example.com

echo "Despliegue staging via Argo CD completado."
