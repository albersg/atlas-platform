#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="atlas-platform-dev"
NODE_IP="$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')"

echo "Node IP detectada: ${NODE_IP}"
echo
echo "Agrega estas entradas en /etc/hosts (o equivalente):"
echo "${NODE_IP} atlas.local api.atlas.local"
echo
echo "URLs esperadas tras desplegar:"
echo "- Frontend: http://atlas.local"
echo "- API docs: http://api.atlas.local/docs"
echo "- API health: http://api.atlas.local/healthz"
echo
echo "Fallback con port-forward si Ingress no esta disponible:"
echo "kubectl -n ${NAMESPACE} port-forward svc/web 8080:80"
echo "kubectl -n ${NAMESPACE} port-forward svc/inventory-service 8000:8000"
