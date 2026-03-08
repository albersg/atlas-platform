#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${1:-atlas-platform-dev}"

echo "== Workloads =="
kubectl -n "${NAMESPACE}" get deploy,sts,po,job,pvc,hpa

echo
echo "== Services/Ingress =="
kubectl -n "${NAMESPACE}" get svc,ingress
