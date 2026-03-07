# ADR-0001: Monorepo vs Multirepo for Microservice Evolution

## Status

Accepted

## Context

The platform is intended to evolve toward multiple independently deployable microservices on k3s.
At the same time, the current phase requires fast iteration, strong architecture governance, and low coordination overhead.

## Decision

Use a **modular monorepo** as the initial and medium-term strategy.

## Rationale

### Why monorepo now

1. Shared standards are easier to enforce.
   One `pre-commit`, one CI policy, one security baseline, one coding contract.
2. Cross-service refactors are cheaper.
   API contracts, shared docs, and deployment changes can evolve atomically.
3. DevEx and onboarding are simpler.
   One clone, one bootstrap path, one command surface.
4. Stronger architectural governance.
   Hexagonal and screaming constraints can be tested and reviewed globally.

### Why not multirepo now

1. Higher operational overhead too early.
   Many repos imply duplicated governance, duplicated CI, and policy drift risk.
2. More brittle cross-cutting changes.
   Service boundary and platform changes become slow and coordination-heavy.
3. Platform complexity before product complexity.
   It optimizes for organizational scale before technical need is proven.

## Consequences

### Positive

- Faster end-to-end delivery and architecture learning.
- Better consistency in quality, security, and operations.
- Easier move from modular monolith to service extraction.

### Negative

- Single repository growth requires discipline.
- CI scope management becomes important as services grow.

## Evolution plan to multirepo (if needed)

Extract to multirepo only when at least two of these conditions hold:

1. Independent team ownership per service is stable.
2. Release cadence differs significantly between services.
3. Cross-service changes are rare and mostly contract-based.
4. CI time or repository scale materially hurts productivity.

At extraction time:

1. Preserve domain boundaries already encoded in screaming architecture.
2. Keep shared API contracts versioned and explicit.
3. Keep platform/deployment repo separated from service repos if needed.
4. Keep governance templates standardized across repos.
