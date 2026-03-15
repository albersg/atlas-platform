#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${1:-atlas-platform-dev}"
FRONTEND_HOST="${2:-atlas.local}"
API_HOST="${3:-api.atlas.local}"
NODE_IP="$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')"
STAGING_INGRESS_SCHEME="${ATLAS_STAGING_INGRESS_SCHEME:-http}"
STAGING_LOCAL_INGRESS_SCHEME="${ATLAS_STAGING_LOCAL_INGRESS_SCHEME:-http}"
STAGING_LOCAL_HTTP_PORT="${ATLAS_STAGING_LOCAL_HTTP_PORT:-32080}"
STAGING_LOCAL_HTTPS_PORT="${ATLAS_STAGING_LOCAL_HTTPS_PORT:-32443}"

lookup_node_port() {
  local port_name="$1"

  kubectl -n istio-system get service atlas-platform-istio-ingress -o jsonpath="{.spec.ports[?(@.name=='${port_name}')].nodePort}" 2>/dev/null
}

if [ "$NAMESPACE" = "atlas-platform-staging" ]; then
  HTTP_NODE_PORT="$(lookup_node_port http2)"
  HTTPS_NODE_PORT="$(lookup_node_port https)"

  if [ -n "$HTTP_NODE_PORT" ] || [ -n "$HTTPS_NODE_PORT" ]; then
    FRONTEND_SCHEME="$STAGING_LOCAL_INGRESS_SCHEME"
    API_SCHEME="$STAGING_LOCAL_INGRESS_SCHEME"
    if [ "$FRONTEND_SCHEME" = "https" ]; then
      FRONTEND_PORT="${HTTPS_NODE_PORT:-$STAGING_LOCAL_HTTPS_PORT}"
      API_PORT="$FRONTEND_PORT"
    else
      FRONTEND_PORT="${HTTP_NODE_PORT:-$STAGING_LOCAL_HTTP_PORT}"
      API_PORT="$FRONTEND_PORT"
    fi
  else
    FRONTEND_SCHEME="$STAGING_INGRESS_SCHEME"
    API_SCHEME="$STAGING_INGRESS_SCHEME"
    FRONTEND_PORT=""
    API_PORT=""
  fi
else
  FRONTEND_SCHEME="http"
  API_SCHEME="http"
  FRONTEND_PORT=""
  API_PORT=""
fi

format_url() {
  local scheme="$1"
  local host="$2"
  local port="$3"
  local suffix="$4"

  if [ -n "$port" ]; then
    printf '%s://%s:%s%s\n' "$scheme" "$host" "$port" "$suffix"
  else
    printf '%s://%s%s\n' "$scheme" "$host" "$suffix"
  fi
}

echo "Node IP detectada: ${NODE_IP}"
echo
echo "Agrega estas entradas en /etc/hosts (o equivalente):"
echo "${NODE_IP} ${FRONTEND_HOST} ${API_HOST}"
echo
echo "URLs esperadas tras desplegar:"
echo "- Frontend: $(format_url "$FRONTEND_SCHEME" "$FRONTEND_HOST" "$FRONTEND_PORT" "")"
echo "- API: $(format_url "$API_SCHEME" "$API_HOST" "$API_PORT" "/api/v1/inventory/products")"
echo "- API docs por port-forward: kubectl -n ${NAMESPACE} port-forward svc/inventory-service 8000:8000"

if [ -n "$FRONTEND_PORT" ]; then
  echo "- Modelo local de exposicion: NodePort del gateway Istio (sin competir con Traefik en 80/443)."
fi
echo
echo "Fallback con port-forward si Ingress no esta disponible:"
echo "kubectl -n ${NAMESPACE} port-forward svc/web 8080:80"
echo "kubectl -n ${NAMESPACE} port-forward svc/inventory-service 8000:8000"
