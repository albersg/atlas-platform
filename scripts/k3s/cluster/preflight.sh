#!/usr/bin/env bash
set -euo pipefail

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl no esta instalado o no esta en PATH" >&2
  exit 1
fi

kubectl cluster-info >/dev/null

echo "Cluster alcanzable: OK"
if kubectl get ingressclass traefik >/dev/null 2>&1; then
  echo "IngressClass traefik detectada: OK"
else
  echo "Aviso: no se detecta IngressClass 'traefik'. Ajusta ingressClassName si usas otro controlador."
fi

if kubectl -n kube-system get deployment metrics-server >/dev/null 2>&1; then
  echo "metrics-server detectado: HPA funcional"
else
  echo "Aviso: metrics-server no detectado. Los HPA no escalaran por CPU."
fi
