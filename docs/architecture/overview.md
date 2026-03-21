# Architecture Overview

Atlas Platform is a monorepo that teaches and validates the full path from local
application development to non-production platform delivery.

## The short version

- The frontend lives in `apps/web`.
- The active backend lives in `services/inventory-service`.
- Helm defines reusable workload and platform add-on bases under `platform/helm/`.
- Kustomize adapts those shared pieces for each environment under `platform/k8s/`.
- Argo CD reconciles the Git-defined staging state into the cluster.
- SOPS plus age plus KSOPS keep encrypted secrets in Git without storing them in
  plain text.
- Kyverno validates the rendered manifests before they are trusted.
- Istio owns the staged service-mesh path.
- Prometheus owns the first monitoring slice.

## Why the architecture is split this way

Different problems need different tools:

- Helm is good at packaging reusable bases and upstream-chart wrappers.
- Kustomize is good at environment-specific overlays and patches.
- Argo CD is good at continuously reconciling Git state into a cluster.
- Kyverno is good at enforcing deployment rules over rendered YAML.
- Istio is good at staged traffic management and mesh-aware routing.
- Prometheus is good at collecting metrics from cluster services and workloads.

Using one tool for every concern would make the repo harder to teach and harder to
change safely.

## Main architecture decisions

### Application architecture

- Each service follows hexagonal architecture internally.
- Business capabilities are organized as screaming architecture boundaries.
- The repo stays a modular monorepo until a real need justifies extraction.

### Platform architecture

- `platform/helm/` owns reusable bases and add-ons.
- `platform/k8s/` owns environment overlays, environment patches, and workload-side
  resources such as the first `ServiceMonitor`.
- `platform/argocd/` owns GitOps bootstrap and Argo CD applications.
- `platform/policy/kyverno/` owns policy-as-code validation.

### Environment architecture

- Local is for the fastest app loop.
- `dev` is the first Kubernetes layer and stays simpler than staged environments.
- `staging-local` rehearses the real GitOps topology on local k3s.
- Canonical `staging` is the real pre-production contract and uses registry images
  pinned by digest.

## What changed in the final architecture

The repo no longer treats all Kubernetes concerns the same way.

- Helm now owns reusable bases and platform add-ons.
- Kustomize now owns environment overlays and workload adaptation.
- Argo CD now manages both workload and infra application boundaries.
- Istio now owns staged ingress and mesh behavior for `staging-local` and `staging`.
- Prometheus now runs as a dedicated infra add-on in the `monitoring` namespace.

## Read next

1. [Platform delivery architecture](platform-delivery-architecture.md)
2. [Deployment topology](deployment-topology.md)
3. [Operations overview](../operations/overview.md)
