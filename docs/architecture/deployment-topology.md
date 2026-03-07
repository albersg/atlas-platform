# Deployment Topology

## Local environment

Local stack runs with Docker Compose:

- `postgres` for persistence,
- `inventory-service` as API,
- `web` as UI.

## k3s target topology

Kubernetes base manifests provide:

- namespace isolation,
- database, API, and frontend deployments,
- dedicated Alembic migration job,
- services and ingress,
- startup/readiness/liveness probes,
- PDB and HPA controls for app tiers.

Overlay strategy:

- `platform/k8s/base`: hardened default manifests.
- `platform/k8s/overlays/dev`: local k3s overlay with local image tags.
- `platform/k8s/overlays/prod`: production host patching template.

## Future hardening roadmap

1. Replace inline DB secret with sealed secrets or external secret store.
2. Move DB to managed service in production.
3. Add Helm chart packaging and environment overlays.
4. Add autoscaling and resource policies.
5. Add policy-as-code (Kyverno or OPA Gatekeeper).
