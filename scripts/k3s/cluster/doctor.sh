#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PATH="$ROOT_DIR/.gitops-local/bin:$PATH"
DOCTOR_SCOPE="${ATLAS_DOCTOR_SCOPE:-staging}"
required_tools=(kubectl docker)
staging_tools=(argocd sops age kustomize ksops kyverno cosign helm istioctl)
prereq_failures=0
operational_failures=0
operational_warnings=0

check_tool() {
  local tool_name="$1"
  local install_hint="$2"

  if command -v "$tool_name" >/dev/null 2>&1; then
    echo "[ok] herramienta disponible: ${tool_name}"
  else
    echo "[fail] falta ${tool_name}. ${install_hint}" >&2
    prereq_failures=$((prereq_failures + 1))
  fi
}

record_prereq_failure() {
  local message="$1"

  echo "$message" >&2
  prereq_failures=$((prereq_failures + 1))
}

record_operational_failure() {
  local message="$1"

  echo "$message" >&2
  operational_failures=$((operational_failures + 1))
}

record_operational_warning() {
  local message="$1"

  echo "$message" >&2
  operational_warnings=$((operational_warnings + 1))
}

check_file() {
  local file_path="$1"
  local hint="$2"
  local relative_path

  relative_path="${file_path#"$ROOT_DIR"/}"

  if [[ -f "$file_path" ]]; then
    echo "[ok] archivo disponible: ${relative_path}"
  else
    record_prereq_failure "[fail] falta ${relative_path}. ${hint}"
  fi
}

check_kubectl_resource() {
  local description="$1"
  shift

  if kubectl "$@" >/dev/null 2>&1; then
    echo "[ok] ${description}"
  else
    record_prereq_failure "[fail] ${description}. Revisa el bootstrap GitOps del cluster actual."
  fi
}

check_operational_resource() {
  local description="$1"
  shift

  if kubectl "$@" >/dev/null 2>&1; then
    echo "[ok] ${description}"
  else
    record_operational_failure "[operational-fail] ${description}. Revisa el despliegue real de staging en el cluster actual."
  fi
}

print_section() {
  local title="$1"

  printf '\n== %s ==\n' "$title"
}

has_argocd_app_crd() {
  kubectl api-resources --verbs=list --namespaced -o name 2>/dev/null | grep -qx 'applications.argoproj.io'
}

platform_infra_apps() {
  printf '%s\n' \
    atlas-platform-istio-base \
    atlas-platform-istiod \
    atlas-platform-istio-ingress \
    atlas-platform-prometheus
}

check_docker_compose() {
  if docker compose version >/dev/null 2>&1; then
    echo "[ok] docker compose disponible"
  else
    record_prereq_failure "[fail] docker compose no esta disponible. Instala el plugin oficial de Docker Compose antes de usar el flujo local compose."
  fi
}

for tool_name in "${required_tools[@]}"; do
  check_tool "$tool_name" "Instalala antes de operar el cluster."
done

if command -v docker >/dev/null 2>&1; then
  check_docker_compose
fi

if [[ "$DOCTOR_SCOPE" = "staging" || "$DOCTOR_SCOPE" = "all" ]]; then
  for tool_name in "${staging_tools[@]}"; do
    check_tool "$tool_name" "Ejecuta 'mise run gitops-install-tools' para instalar helpers GitOps locales."
  done
fi

if kubectl cluster-info >/dev/null 2>&1; then
  echo "[ok] cluster alcanzable con kubectl"
else
  record_prereq_failure "[fail] kubectl no puede alcanzar el cluster actual. Revisa el contexto activo y vuelve a intentar."
fi

if kubectl get ingressclass traefik >/dev/null 2>&1; then
  echo "[ok] IngressClass traefik detectada"
else
  echo "[warn] no se detecta IngressClass 'traefik'. Ajusta ingressClassName si usas otro controlador." >&2
fi

if [[ "$DOCTOR_SCOPE" = "staging" || "$DOCTOR_SCOPE" = "all" ]]; then
  print_section "Prerequisitos staging"
  check_file \
    "$ROOT_DIR/.gitops-local/age/keys.txt" \
    "Genera la clave local y luego ejecuta 'mise run gitops-install-age-key'."
  check_kubectl_resource "Argo CD server disponible" -n argocd get deployment argocd-server
  check_kubectl_resource "secreto argocd-sops-age-key presente" -n argocd get secret argocd-sops-age-key

  if kubectl -n argocd get secret argocd-repo-atlas-platform >/dev/null 2>&1; then
    echo "[ok] credential del repositorio presente en argocd"
  else
    record_prereq_failure "[fail] falta la credential del repositorio en argocd. Ejecuta 'mise run gitops-install-repo-credential'."
  fi

  if ATLAS_VALIDATE_PREFLIGHT=1 "$ROOT_DIR/scripts/gitops/validate-overlays.sh" >/dev/null; then
    echo "[ok] render de overlays y bundles de politica listo para staging endurecido"
  else
    record_prereq_failure "[fail] el render o los bundles de politica no estan listos. Ejecuta 'mise run k8s-validate-overlays' para ver el error completo."
  fi

  print_section "Salud operativa staging"
  if kubectl get namespace atlas-platform-staging >/dev/null 2>&1; then
    echo "[ok] namespace atlas-platform-staging presente"
  else
    record_operational_failure "[operational-fail] falta el namespace atlas-platform-staging. El entorno no esta desplegado en este cluster."
  fi

  if has_argocd_app_crd; then
    while IFS= read -r app_name; do
      check_operational_resource \
        "Argo CD application ${app_name} presente" \
        -n argocd get application "$app_name"
    done < <(platform_infra_apps)

    check_operational_resource \
      "Argo CD application atlas-platform-staging presente" \
      -n argocd get application atlas-platform-staging
  else
    record_operational_warning "[operational-warn] el CRD applications.argoproj.io no esta registrado; no se pueden comprobar las Applications de Argo CD desde este cluster."
  fi

  if kubectl get namespace istio-system >/dev/null 2>&1; then
    echo "[ok] namespace istio-system presente"
    check_operational_resource \
      "deployment istiod disponible en istio-system" \
      -n istio-system get deployment istiod
    check_operational_resource \
      "deployment atlas-platform-istio-ingress disponible en istio-system" \
      -n istio-system get deployment atlas-platform-istio-ingress
    check_operational_resource \
      "service atlas-platform-istio-ingress disponible en istio-system" \
      -n istio-system get service atlas-platform-istio-ingress
  else
    record_operational_failure "[operational-fail] falta el namespace istio-system. La capa infra de Istio no esta desplegada en este cluster."
  fi

  if kubectl get namespace monitoring >/dev/null 2>&1; then
    echo "[ok] namespace monitoring presente"
    check_operational_resource \
      "statefulset prometheus-atlas-platform-prometheus-kube-prometheus-prometheus disponible en monitoring" \
      -n monitoring get statefulset prometheus-atlas-platform-prometheus-kube-prometheus-prometheus
    check_operational_resource \
      "deployment atlas-platform-prometheus-kube-prometheus-operator disponible en monitoring" \
      -n monitoring get deployment atlas-platform-prometheus-kube-prometheus-operator
    check_operational_resource \
      "service atlas-platform-prometheus-kube-prometheus-prometheus disponible en monitoring" \
      -n monitoring get service atlas-platform-prometheus-kube-prometheus-prometheus
  else
    record_operational_failure "[operational-fail] falta el namespace monitoring. La capa infra de Prometheus no esta desplegada en este cluster."
  fi

  if kubectl get namespace atlas-platform-staging >/dev/null 2>&1; then
    check_operational_resource \
      "deployment inventory-service disponible en staging" \
      -n atlas-platform-staging get deployment inventory-service
    check_operational_resource \
      "deployment web disponible en staging" \
      -n atlas-platform-staging get deployment web
  fi
fi

if [[ "$prereq_failures" -gt 0 ]]; then
  echo "Doctor prerequisitos: ${prereq_failures} fallo(s) bloqueantes." >&2
fi

if [[ "$operational_failures" -gt 0 ]]; then
  echo "Doctor operacion staging: ${operational_failures} fallo(s) detectados." >&2
fi

if [[ "$operational_warnings" -gt 0 ]]; then
  echo "Doctor operacion staging: ${operational_warnings} advertencia(s)." >&2
fi

if [[ "$prereq_failures" -gt 0 || "$operational_failures" -gt 0 ]]; then
  exit 1
fi

echo "Doctor Kubernetes: prerequisitos y operacion listos para el alcance '${DOCTOR_SCOPE}'."
