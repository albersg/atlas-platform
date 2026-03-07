# Hexagonal + Screaming Architecture Blueprint

## Goals

- Keep business logic independent from frameworks and infrastructure.
- Organize code by business capability first (screaming architecture).
- Make future service extraction straightforward.

## Core model

Each service follows this shape:

- `<service>/<capability>/domain/`: entities, value objects, domain rules.
- `<service>/<capability>/application/`: use cases and orchestration.
- `<service>/<capability>/ports/`: interfaces required by use cases.
- `<service>/<capability>/adapters/`: infrastructure implementations.
  - `api/http/`: inbound adapters.
  - `persistence/sqlalchemy/`: outbound adapters.

Dependency direction is always inward:

- adapters -> ports/application/domain
- application -> domain/ports
- domain -> no infrastructure dependency

## Why screaming architecture here

Top-level structure should communicate business intent immediately.
When engineers enter the codebase, they should see capabilities (`inventory`, `billing`) before technical layers.

## Strategic service boundaries

Current services in this scaffold:

1. `inventory-service` (functional)
2. `billing-service` (scaffold for next extraction)

This pattern enables:

- service-per-bounded-context in the future,
- or consolidation if complexity does not justify split.

## Deployment model

- Local development: Docker Compose.
- Cluster deployment: k3s-compatible Kubernetes manifests with Kustomize overlays.
- Future hardening path: Helm charts, sealed secrets, service mesh, and policy-as-code.
