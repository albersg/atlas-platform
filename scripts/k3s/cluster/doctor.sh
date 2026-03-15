#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PATH="$ROOT_DIR/.gitops-local/bin:$PATH"
DOCTOR_SCOPE="${ATLAS_DOCTOR_SCOPE:-staging}"
required_tools=(kubectl docker)
staging_tools=(argocd sops age kustomize ksops kyverno cosign)
failures=0

check_tool() {
  local tool_name="$1"
  local install_hint="$2"

  if command -v "$tool_name" >/dev/null 2>&1; then
    echo "[ok] herramienta disponible: ${tool_name}"
  else
    echo "[fail] falta ${tool_name}. ${install_hint}" >&2
    failures=$((failures + 1))
  fi
}

record_failure() {
  local message="$1"

  echo "$message" >&2
  failures=$((failures + 1))
}

check_file() {
  local file_path="$1"
  local hint="$2"
  local relative_path

  relative_path="${file_path#"$ROOT_DIR"/}"

  if [[ -f "$file_path" ]]; then
    echo "[ok] archivo disponible: ${relative_path}"
  else
    record_failure "[fail] falta ${relative_path}. ${hint}"
  fi
}

check_kubectl_resource() {
  local description="$1"
  shift

  if kubectl "$@" >/dev/null 2>&1; then
    echo "[ok] ${description}"
  else
    record_failure "[fail] ${description}. Revisa el bootstrap GitOps del cluster actual."
  fi
}

for tool_name in "${required_tools[@]}"; do
  check_tool "$tool_name" "Instalala antes de operar el cluster."
done

if [[ "$DOCTOR_SCOPE" = "staging" || "$DOCTOR_SCOPE" = "all" ]]; then
  for tool_name in "${staging_tools[@]}"; do
    check_tool "$tool_name" "Ejecuta 'mise run gitops-install-tools' para instalar helpers GitOps locales."
  done
fi

if kubectl cluster-info >/dev/null 2>&1; then
  echo "[ok] cluster alcanzable con kubectl"
else
  record_failure "[fail] kubectl no puede alcanzar el cluster actual. Revisa el contexto activo y vuelve a intentar."
fi

if kubectl get ingressclass traefik >/dev/null 2>&1; then
  echo "[ok] IngressClass traefik detectada"
else
  echo "[warn] no se detecta IngressClass 'traefik'. Ajusta ingressClassName si usas otro controlador." >&2
fi

if [[ "$DOCTOR_SCOPE" = "staging" || "$DOCTOR_SCOPE" = "all" ]]; then
  check_file \
    "$ROOT_DIR/.gitops-local/age/keys.txt" \
    "Genera la clave local y luego ejecuta 'mise run gitops-install-age-key'."
  check_kubectl_resource "Argo CD server disponible" -n argocd get deployment argocd-server
  check_kubectl_resource "secreto argocd-sops-age-key presente" -n argocd get secret argocd-sops-age-key

  if kubectl -n argocd get secret argocd-repo-atlas-platform >/dev/null 2>&1; then
    echo "[ok] credential del repositorio presente en argocd"
  else
    record_failure "[fail] falta la credential del repositorio en argocd. Ejecuta 'mise run gitops-install-repo-credential'."
  fi

  if ATLAS_VALIDATE_PREFLIGHT=1 "$ROOT_DIR/scripts/gitops/validate-overlays.sh" >/dev/null; then
    echo "[ok] render de overlays y bundles de politica listo para staging endurecido"
  else
    record_failure "[fail] el render o los bundles de politica no estan listos. Ejecuta 'mise run k8s-validate-overlays' para ver el error completo."
  fi
fi

if [[ "$failures" -gt 0 ]]; then
  echo "Doctor detecto ${failures} fallo(s) bloqueantes." >&2
  exit 1
fi

echo "Doctor Kubernetes: listo para el alcance '${DOCTOR_SCOPE}'."
