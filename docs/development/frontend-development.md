# Frontend Development

The frontend lives in `apps/web` and uses React, Vite, and TypeScript.

## Tooling explained

- `npm` installs frontend dependencies and runs the package scripts.
- Vite provides the local dev server and the production build pipeline.
- TypeScript adds static checking to the frontend codebase.

## What you usually change here

- page and component UI
- API integration for inventory flows
- client-side types and hooks
- frontend build behavior

## Primary commands

```bash
mise run frontend-dev
mise run frontend-build
mise run frontend-typecheck
```

## Run the frontend locally

```bash
mise run frontend-dev
```

- Purpose: starts the Vite dev server with hot reload.
- Prerequisites: `mise run app-bootstrap`.
- Under the hood: runs `npm run dev` in `apps/web`.
- Expected output: a local development server, usually on Vite's default port.
- Run next: `mise run frontend-build` before handoff.

## Build the frontend

```bash
mise run frontend-build
```

- Purpose: prove the production bundle still compiles.
- When to run it: before opening a PR, and inside grouped validation through `mise run check`.
- Under the hood: runs `vite build`.
- Good outcome: a successful bundle with no TypeScript or import errors.

## Type checking

```bash
mise run frontend-typecheck
```

- Purpose: catch static type issues without building.
- Under the hood: runs `tsc --noEmit`.

## How it connects to the rest of the repo

- In Compose, the web app is served on `http://localhost:8080`.
- In local Vite development, API traffic is proxied by `vite.config.ts`.
- The frontend follows the same validation and release flow as the backend.

## Optional observability variables

- `VITE_SENTRY_DSN`
- `VITE_SENTRY_ENVIRONMENT`
- `VITE_SENTRY_TRACES_SAMPLE_RATE`

See [Configuration and environment variables](../reference/configuration.md).
