# First-Day Setup

Use this guide when you are starting from zero and want a working local checkout.

If the tool names still feel unfamiliar, read the
[tooling primer](tooling-primer.md) first and come back here.

## Goal

By the end of this page you should be able to:

- install the pinned toolchain,
- install project dependencies,
- run the standard validation path,
- choose your first local development loop.

## Prerequisites

You need these base tools on your machine before the repo can help you further:

- `git`
- `mise`
- `docker` for the Compose workflow
- `kubectl` and `k3s` only if you plan to use the local Kubernetes flows

## Tool primer before you start

If these names are new, use this cheat sheet while reading the rest of the docs:

| Tool | Plain-language meaning in this repo |
| --- | --- |
| `mise` | installs pinned tool versions and exposes the canonical `mise run ...` tasks so everyone uses the same commands |
| `uv` | Python dependency manager and runner used for the FastAPI backend |
| `npm` | Node package manager used for the React and Vite frontend |
| Docker | builds and runs containers for local full-stack work and image publishing |
| Docker Compose | starts the local multi-container app stack with frontend, backend, and PostgreSQL |
| `kubectl` | command-line client for talking to Kubernetes clusters |
| k3s | lightweight Kubernetes distribution used for the local `dev` and `staging-local` labs |
| Helm | reusable packaging layer for Atlas workload bases and platform add-ons |
| Kustomize | environment overlay layer that adapts shared manifests for `dev`, `staging-local`, and `staging` |
| Argo CD | GitOps controller that continuously reconciles repo state into the cluster |

You do not need to memorize every tool now. The [glossary](../reference/glossary.md),
[tooling primer](tooling-primer.md), and [learning path](learning-path.md) explain
when each one matters.

## Step 1: Install the pinned toolchain

```bash
mise install
```

- What it is for: installs the versions pinned in `mise.toml`.
- When to run it: first clone, after `mise.toml` changes, or after a clean machine setup.
- What it does under the hood: downloads tools like Python, Node, `uv`, `ruff`, `pre-commit`, and other pinned CLI helpers.
- Expected output: `mise` shows each tool being installed or confirms it is already present.
- Run next: `mise run bootstrap`.

## Step 2: Install Git hooks

```bash
mise run bootstrap
```

- What it is for: sets up the repository hooks that enforce formatting, linting, and security checks.
- When to run it: after `mise install`, or again if hooks look broken.
- What it does under the hood: runs `pre-commit install --install-hooks` for both `pre-commit` and `pre-push`.
- Expected output: `pre-commit installed at ...` plus hook installation logs.
- Run next: `mise run app-bootstrap`.

## Step 3: Install app dependencies

```bash
mise run app-bootstrap
```

- What it is for: prepares the backend and frontend workspaces.
- When to run it: first setup and after dependency changes.
- What it does under the hood: runs `uv sync --extra dev` in `services/inventory-service` for Python packages and `npm install` in `apps/web` for frontend packages.
- Expected output: Python dependencies sync first, then Node packages install.
- Run next: `mise run check`.

## Step 4: Prove the repo works on your machine

```bash
mise run check
mise run docs-build
```

- `mise run check`
  - What it is for: the standard local validation bundle.
  - Under the hood: runs `lint`, `typecheck`, `frontend-build`, and `test`.
  - Good outcome: all tasks finish successfully with no diff left behind.
- `mise run docs-build`
  - What it is for: confirms the docs site builds in strict mode.
  - Under the hood: runs MkDocs Material through `uvx`.
  - Good outcome: a successful `mkdocs build --strict` with no broken links or nav errors.

## Step 5: Choose your first loop

### Full stack with containers

```bash
mise run compose-up
```

Use this when you want the backend, frontend, and PostgreSQL together with the
least manual coordination.

Tooling behind this path: Docker runs the containers and Docker Compose defines
how the three services start together.

Next reads: [Local Compose](../operations/local-compose.md).

### Backend only

```bash
mise run backend-dev
```

Use this when you are focused on API or persistence changes.

Tooling behind this path: FastAPI serves the HTTP API, `uvicorn` provides the
reload server, `uv` manages the Python environment, and PostgreSQL is the main
database when your change touches persistence.

Next reads: [Backend development](../development/backend-development.md).

### Frontend only

```bash
mise run frontend-dev
```

Use this when you are focused on UI work and do not need Compose.

Tooling behind this path: `npm` starts the Vite development server for the
React frontend.

Next reads: [Frontend development](../development/frontend-development.md).

## What to read next

1. [Repository tour](repository-map.md)
2. [Glossary](../reference/glossary.md)
3. [Architecture overview](../architecture/overview.md)
4. [Daily workflow and change lifecycle](../development/END_TO_END_WORKFLOW.md)
5. [Local development](../development/local-development.md)
