# Local Compose

Use Docker Compose when you want the backend, frontend, and PostgreSQL together
without managing each process yourself.

## Tooling explained

- Docker is the container engine that runs the images.
- Docker Compose is the local orchestration layer that starts multiple containers as one stack.
- In this repo, Compose is the fastest path to seeing the frontend, FastAPI backend, and PostgreSQL work together.

## Main commands

```bash
mise run compose-up
mise run compose-logs
mise run compose-down
```

## `mise run compose-up`

- Purpose: start the full local stack.
- Prerequisites: Docker available on your machine.
- Under the hood: calls `./scripts/compose/require-compose.sh up --build -d`.
- Expected services: PostgreSQL, `inventory-service`, and `web`.
- Expected endpoints:
  - web: `http://localhost:8080`
  - API docs: `http://localhost:8000/docs`
  - liveness: `http://localhost:8000/healthz`
  - readiness: `http://localhost:8000/readyz`
- Run next: `mise run compose-logs` if you want to inspect startup.

## `mise run compose-logs`

- Purpose: follow logs from the running stack.
- Under the hood: calls `docker compose logs -f --tail=200` through the wrapper script.

## `mise run compose-down`

- Purpose: stop the stack when you are done.
- Under the hood: calls `docker compose down` through the wrapper script.

## What Compose is good for

- fast full-stack smoke checks,
- validating the backend against PostgreSQL,
- checking frontend-to-backend integration locally.

## When not to use it

Use separate processes if you only need one app surface. Use k3s if you need to
validate Kubernetes manifests, ingress, or GitOps behavior.
