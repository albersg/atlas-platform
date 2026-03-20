#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${1:-atlas-platform-dev}"

platform_infra_apps() {
  printf '%s\n' \
    atlas-platform-istio-base \
    atlas-platform-istiod \
    atlas-platform-istio-ingress \
    atlas-platform-prometheus
}

echo "== Workloads =="
kubectl -n "${NAMESPACE}" get deploy,sts,po,job,pvc,hpa

echo
echo "== Services/Ingress =="
kubectl -n "${NAMESPACE}" get svc,ingress

if [[ "$NAMESPACE" = "atlas-platform-staging" ]]; then
  echo
  echo "== Mesh Runtime =="
  kubectl -n istio-system get deploy,svc,pod

  echo
  echo "== Monitoring Runtime =="
  kubectl -n monitoring get deploy,sts,svc,pod

  if kubectl api-resources --verbs=list --namespaced -o name 2>/dev/null | grep -qx 'applications.argoproj.io'; then
    echo
    echo "== Argo CD Applications =="
    mapfile -t infra_apps < <(platform_infra_apps)
    kubectl -n argocd get application "${infra_apps[@]}" atlas-platform-staging
  fi
fi
