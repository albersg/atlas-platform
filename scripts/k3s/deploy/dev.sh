#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="atlas-platform"
OVERLAY="platform/k8s/overlays/dev"

"$(dirname "$0")/../cluster/preflight.sh"

echo "Eliminando job de migracion previo (si existe)..."
kubectl -n "${NAMESPACE}" delete job inventory-migration --ignore-not-found

echo "Aplicando overlay dev..."
kubectl apply -k "${OVERLAY}"

echo "Esperando disponibilidad de Postgres..."
kubectl -n "${NAMESPACE}" rollout status deployment/postgres --timeout=300s

echo "Recreando job de migracion para ejecutarlo con Postgres ya listo..."
kubectl -n "${NAMESPACE}" delete job inventory-migration --ignore-not-found
kubectl apply -k "${OVERLAY}"

echo "Esperando finalizacion de migraciones..."
kubectl -n "${NAMESPACE}" wait --for=condition=complete job/inventory-migration --timeout=300s

echo "Esperando backend..."
kubectl -n "${NAMESPACE}" rollout status deployment/inventory-service --timeout=300s

echo "Esperando frontend..."
kubectl -n "${NAMESPACE}" rollout status deployment/web --timeout=300s

echo "Despliegue dev completado."
