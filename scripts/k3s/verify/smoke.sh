#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ] || [ "$#" -gt 4 ]; then
  echo "Uso: $0 <dev|staging> <namespace> [frontend-host] [api-host]" >&2
  exit 1
fi

ENVIRONMENT="$1"
NAMESPACE="$2"
FRONTEND_HOST="${3:-}"
API_HOST="${4:-}"

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
    INGRESS_SCHEME="https"
    CURL_TLS_ARGS=(-k)
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
kubectl -n "$NAMESPACE" wait --for=condition=complete job/inventory-migration --timeout=120s >/dev/null

NODE_IP="$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')"

kubectl -n "$NAMESPACE" port-forward svc/inventory-service "${API_PORT}:8000" >"$TMP_DIR/api-port-forward.log" 2>&1 &
API_PID=$!

kubectl -n "$NAMESPACE" port-forward svc/web "${WEB_PORT}:80" >"$TMP_DIR/web-port-forward.log" 2>&1 &
WEB_PID=$!

wait_for_http "API readiness ${ENVIRONMENT}" "http://127.0.0.1:${API_PORT}/readyz" "$TMP_DIR/api-port-forward.log"
wait_for_http "API list ${ENVIRONMENT}" "http://127.0.0.1:${API_PORT}/api/v1/inventory/products" "$TMP_DIR/api-port-forward.log"
wait_for_http "Frontend ${ENVIRONMENT}" "http://127.0.0.1:${WEB_PORT}/" "$TMP_DIR/web-port-forward.log"
wait_for_http \
  "Ingress frontend ${ENVIRONMENT}" \
  "${INGRESS_SCHEME}://${FRONTEND_HOST}/" \
  "$TMP_DIR/web-port-forward.log" \
  "${CURL_TLS_ARGS[@]}" \
  --resolve "${FRONTEND_HOST}:$([ "$INGRESS_SCHEME" = "https" ] && printf '443' || printf '80'):${NODE_IP}"
wait_for_http \
  "Ingress API ${ENVIRONMENT}" \
  "${INGRESS_SCHEME}://${API_HOST}/api/v1/inventory/products" \
  "$TMP_DIR/api-port-forward.log" \
  "${CURL_TLS_ARGS[@]}" \
  --resolve "${API_HOST}:$([ "$INGRESS_SCHEME" = "https" ] && printf '443' || printf '80'):${NODE_IP}"

echo "Smoke checks ${ENVIRONMENT} completados."
