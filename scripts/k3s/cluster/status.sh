#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="atlas-platform"

echo "== Workloads =="
kubectl -n "${NAMESPACE}" get deploy,po,job,pvc,hpa

echo
echo "== Services/Ingress =="
kubectl -n "${NAMESPACE}" get svc,ingress
