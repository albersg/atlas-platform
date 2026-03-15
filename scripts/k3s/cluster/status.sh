#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${1:-atlas-platform-dev}"

echo "== Workloads =="
kubectl -n "${NAMESPACE}" get deploy,sts,po,job,pvc,hpa

echo
echo "== Services/Ingress =="
kubectl -n "${NAMESPACE}" get svc,ingress

if [[ "$NAMESPACE" = "atlas-platform-staging" ]]; then
  echo
  echo "== Mesh Runtime =="
  kubectl -n istio-system get deploy,svc,pod

  if kubectl api-resources --verbs=list --namespaced -o name 2>/dev/null | grep -qx 'applications.argoproj.io'; then
    echo
    echo "== Argo CD Applications =="
    kubectl -n argocd get application \
      atlas-platform-istio-base \
      atlas-platform-istiod \
      atlas-platform-istio-ingress \
      atlas-platform-staging
  fi
fi
