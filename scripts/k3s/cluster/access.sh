#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${1:-atlas-platform-dev}"
FRONTEND_HOST="${2:-atlas.local}"
API_HOST="${3:-api.atlas.local}"
NODE_IP="$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')"
STAGING_INGRESS_SCHEME="${ATLAS_STAGING_INGRESS_SCHEME:-http}"

if [ "$NAMESPACE" = "atlas-platform-staging" ]; then
  FRONTEND_SCHEME="$STAGING_INGRESS_SCHEME"
  API_SCHEME="$STAGING_INGRESS_SCHEME"
else
  FRONTEND_SCHEME="http"
  API_SCHEME="http"
fi

echo "Node IP detectada: ${NODE_IP}"
echo
echo "Agrega estas entradas en /etc/hosts (o equivalente):"
echo "${NODE_IP} ${FRONTEND_HOST} ${API_HOST}"
echo
echo "URLs esperadas tras desplegar:"
echo "- Frontend: ${FRONTEND_SCHEME}://${FRONTEND_HOST}"
echo "- API: ${API_SCHEME}://${API_HOST}/api/v1/inventory/products"
echo "- API docs por port-forward: kubectl -n ${NAMESPACE} port-forward svc/inventory-service 8000:8000"
echo
echo "Fallback con port-forward si Ingress no esta disponible:"
echo "kubectl -n ${NAMESPACE} port-forward svc/web 8080:80"
echo "kubectl -n ${NAMESPACE} port-forward svc/inventory-service 8000:8000"
