#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ] || [ "$#" -gt 4 ]; then
  echo "Uso: $0 <dev|staging|staging-local> <namespace> [frontend-host] [api-host]" >&2
  exit 1
fi

ENVIRONMENT="$1"
NAMESPACE="$2"
FRONTEND_HOST="${3:-}"
API_HOST="${4:-}"
STAGING_INGRESS_SCHEME="${ATLAS_STAGING_INGRESS_SCHEME:-http}"
STAGING_LOCAL_INGRESS_SCHEME="${ATLAS_STAGING_LOCAL_INGRESS_SCHEME:-http}"
STAGING_LOCAL_HTTP_PORT="${ATLAS_STAGING_LOCAL_HTTP_PORT:-32080}"
STAGING_LOCAL_HTTPS_PORT="${ATLAS_STAGING_LOCAL_HTTPS_PORT:-32443}"

case "$ENVIRONMENT" in
  dev)
    FRONTEND_HOST="${FRONTEND_HOST:-atlas.local}"
    API_HOST="${API_HOST:-api.atlas.local}"
    INGRESS_SCHEME="http"
    CURL_TLS_ARGS=()
    ;;
  staging)
    FRONTEND_HOST="${FRONTEND_HOST:-staging.atlas.example.com}"
    API_HOST="${API_HOST:-api.staging.atlas.example.com}"
    INGRESS_SCHEME="$STAGING_INGRESS_SCHEME"
    INGRESS_PORT="$([ "$INGRESS_SCHEME" = "https" ] && printf '443' || printf '80')"
    if [ "$INGRESS_SCHEME" = "https" ]; then
      CURL_TLS_ARGS=(-k)
    else
      CURL_TLS_ARGS=()
    fi
    ;;
  staging-local)
    FRONTEND_HOST="${FRONTEND_HOST:-staging.atlas.example.com}"
    API_HOST="${API_HOST:-api.staging.atlas.example.com}"
    INGRESS_SCHEME="$STAGING_LOCAL_INGRESS_SCHEME"
    INGRESS_PORT="$([ "$INGRESS_SCHEME" = "https" ] && printf '%s' "$STAGING_LOCAL_HTTPS_PORT" || printf '%s' "$STAGING_LOCAL_HTTP_PORT")"
    if [ "$INGRESS_SCHEME" = "https" ]; then
      CURL_TLS_ARGS=(-k)
    else
      CURL_TLS_ARGS=()
    fi
    ;;
  *)
    echo "Entorno no soportado: $ENVIRONMENT" >&2
    exit 1
    ;;
esac

if ! command -v curl >/dev/null 2>&1; then
  echo "curl es obligatorio para ejecutar smoke checks locales" >&2
  exit 1
fi

mapfile -t PORTS < <(
  python - <<'PY'
import socket

for _ in range(2):
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        print(sock.getsockname()[1])
PY
)

API_PORT="${PORTS[0]}"
WEB_PORT="${PORTS[1]}"
TMP_DIR="$(mktemp -d)"

cleanup() {
  if [ -n "${API_PID:-}" ]; then
    kill "$API_PID" >/dev/null 2>&1 || true
    wait "$API_PID" >/dev/null 2>&1 || true
  fi

  if [ -n "${WEB_PID:-}" ]; then
    kill "$WEB_PID" >/dev/null 2>&1 || true
    wait "$WEB_PID" >/dev/null 2>&1 || true
  fi

  rm -rf "$TMP_DIR"
}

wait_for_sidecar_ready() {
  local selector="$1"
  local description="$2"

  for _ in $(seq 1 30); do
    local pods
    pods="$(kubectl -n "$NAMESPACE" get pods -l "$selector" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')"
    if [[ -n "$pods" ]]; then
      local ready=1
      while IFS= read -r pod_name; do
        [[ -z "$pod_name" ]] && continue
        local proxy_ready
        proxy_ready="$(kubectl -n "$NAMESPACE" get pod "$pod_name" -o jsonpath='{.status.containerStatuses[?(@.name=="istio-proxy")].ready}')"
        if [[ "$proxy_ready" != "true" ]]; then
          ready=0
          break
        fi
      done <<<"$pods"

      if [[ "$ready" = "1" ]]; then
        echo "${description}: sidecar listo"
        return 0
      fi
    fi
    sleep 2
  done

  echo "No se pudo verificar sidecar listo para ${description}" >&2
  kubectl -n "$NAMESPACE" get pods -l "$selector" >&2 || true
  exit 1
}

require_sidecar_injection() {
  local selector="$1"
  local description="$2"

  local pods
  pods="$(kubectl -n "$NAMESPACE" get pods -l "$selector" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')"
  if [[ -z "$pods" ]]; then
    echo "No se encontraron pods para verificar sidecar en ${description}" >&2
    exit 1
  fi

  while IFS= read -r pod_name; do
    [[ -z "$pod_name" ]] && continue
    local proxy_present
    proxy_present="$(kubectl -n "$NAMESPACE" get pod "$pod_name" -o jsonpath='{.spec.containers[?(@.name=="istio-proxy")].name}')"
    if [[ "$proxy_present" != "istio-proxy" ]]; then
      echo "El pod ${pod_name} no tiene sidecar istio-proxy en ${description}" >&2
      exit 1
    fi
  done <<<"$pods"

  echo "${description}: sidecar inyectado"
}

wait_for_http() {
  local name="$1"
  local url="$2"
  local log_file="$3"
  shift 3

  for _ in $(seq 1 30); do
    if curl -fsS "$@" "$url" >/dev/null 2>&1; then
      echo "${name}: OK"
      return 0
    fi
    sleep 2
  done

  echo "No se pudo verificar ${name} en ${url}" >&2
  if [ -f "$log_file" ]; then
    cat "$log_file" >&2
  fi
  exit 1
}

trap cleanup EXIT

kubectl -n "$NAMESPACE" wait --for=condition=available deployment/inventory-service --timeout=120s >/dev/null
kubectl -n "$NAMESPACE" wait --for=condition=available deployment/web --timeout=120s >/dev/null

if [[ "$ENVIRONMENT" = "staging" || "$ENVIRONMENT" = "staging-local" ]]; then
  kubectl -n istio-system wait --for=condition=available deployment/istiod --timeout=120s >/dev/null
  kubectl -n istio-system wait --for=condition=available deployment/atlas-platform-istio-ingress --timeout=120s >/dev/null
  wait_for_sidecar_ready "app=inventory-service" "inventory-service ${ENVIRONMENT}"
  wait_for_sidecar_ready "app=web" "web ${ENVIRONMENT}"
fi

if kubectl -n "$NAMESPACE" get job inventory-migration >/dev/null 2>&1; then
  if [[ "$ENVIRONMENT" = "staging" || "$ENVIRONMENT" = "staging-local" ]]; then
    require_sidecar_injection "job-name=inventory-migration" "inventory-migration ${ENVIRONMENT}"
  fi
  kubectl -n "$NAMESPACE" wait --for=condition=complete job/inventory-migration --timeout=120s >/dev/null
else
  echo "Migration job ${ENVIRONMENT}: no presente (hook ya limpiado o despliegue sin job persistente)"
fi

NODE_IP="$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')"

kubectl -n "$NAMESPACE" port-forward svc/inventory-service "${API_PORT}:8000" >"$TMP_DIR/api-port-forward.log" 2>&1 &
API_PID=$!

kubectl -n "$NAMESPACE" port-forward svc/web "${WEB_PORT}:80" >"$TMP_DIR/web-port-forward.log" 2>&1 &
WEB_PID=$!

wait_for_http "API readiness ${ENVIRONMENT}" "http://127.0.0.1:${API_PORT}/readyz" "$TMP_DIR/api-port-forward.log"
wait_for_http "API list ${ENVIRONMENT}" "http://127.0.0.1:${API_PORT}/api/v1/inventory/products" "$TMP_DIR/api-port-forward.log"
wait_for_http "API metrics ${ENVIRONMENT}" "http://127.0.0.1:${API_PORT}/metrics" "$TMP_DIR/api-port-forward.log"
wait_for_http "Frontend ${ENVIRONMENT}" "http://127.0.0.1:${WEB_PORT}/" "$TMP_DIR/web-port-forward.log"
wait_for_http \
  "Ingress frontend ${ENVIRONMENT}" \
  "${INGRESS_SCHEME}://${FRONTEND_HOST}:${INGRESS_PORT}/" \
  "$TMP_DIR/web-port-forward.log" \
  "${CURL_TLS_ARGS[@]}" \
  --resolve "${FRONTEND_HOST}:${INGRESS_PORT}:${NODE_IP}"
wait_for_http \
  "Ingress API ${ENVIRONMENT}" \
  "${INGRESS_SCHEME}://${API_HOST}:${INGRESS_PORT}/api/v1/inventory/products" \
  "$TMP_DIR/api-port-forward.log" \
  "${CURL_TLS_ARGS[@]}" \
  --resolve "${API_HOST}:${INGRESS_PORT}:${NODE_IP}"

echo "Smoke checks ${ENVIRONMENT} completados."
