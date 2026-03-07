# AGENTS Guide

## Purpose

Operating contract for agentic coding in this repository.
Goals: secure changes, clear rationale, reproducible validation, and minimal surprises.

## Agent Philosophy (Generic)

- Be helpful first: solve the task directly, then explain tradeoffs.
- Be evidence-driven: verify technical claims in code/docs before asserting.
- Be respectful and direct: no sarcasm, no condescension.
- Be pragmatic: challenge weak assumptions only when it changes outcomes.
- Be transparent: if uncertain, say so and investigate.

## Non-Negotiable Rules

- Never add AI attribution to commits (no `Co-Authored-By`).
- Never use `git commit --no-verify`.
- Never run destructive git commands unless explicitly requested.
- Never push from agent sessions unless explicitly requested.
- Never access files outside this repository.
- Never touch secrets, credentials, tokens, certificates, or key material.
- Do not bypass branch protections, hooks, or CI gates.

## Working Agreement

- Start each task with `git status` and a quick repository scan.
- Keep changes minimal, reversible, and in-scope.
- Do not reformat unrelated files.
- Treat all modifications as potentially production-impacting.
- If a question is necessary, ask one precise question and wait.

## Tooling Preferences

- Prefer modern CLI tools when available: `rg` over `grep`, `fd` over `find`, `bat` over `cat`, `eza` over `ls`, `sd` over `sed`.
- Use repository-provided tasks via `mise run ...` before custom command chains.

## Repo Map

- `.github/workflows/`: CI, security, and dependency policy workflows.
- `.github/CODEOWNERS`: mandatory review ownership.
- `.pre-commit-config.yaml`: local and CI lint/security hooks.
- `mise.toml`: pinned tools and shared tasks.
- `scripts/k3s`: deployment scripts for local k3s operation.
- `apps/web`: frontend application.
- `services/inventory-service`: backend microservice (FastAPI + SQLAlchemy).
- `services/billing-service`: future bounded-context scaffold.
- `platform/k8s`: k3s-ready manifests.
- `docs/adr`: architecture decision records.
- `docs/deployment`: deployment and operations runbooks.
- `tests/`: repository policy tests.

## Canonical Commands

Primary day-to-day commands:

- `mise run bootstrap`
- `mise run fmt`
- `mise run lint`
- `mise run typecheck`
- `mise run test`
- `mise run docs-build`
- `mise run check`
- `mise run fix`
- `mise run ci`

Extended commands:

- `mise run security`
- `mise run fmt-check`
- `mise run hooks-update`
- `mise run lock`
- `mise run doctor`
- `mise run app-bootstrap`
- `mise run backend-migrate`
- `mise run backend-dev`
- `mise run backend-test`
- `mise run frontend-dev`
- `mise run frontend-build`
- `mise run compose-up`
- `mise run compose-down`
- `mise run compose-logs`
- `mise run k8s-preflight`
- `mise run k8s-build-images`
- `mise run k8s-import-images`
- `mise run k8s-deploy-dev`
- `mise run k8s-status`
- `mise run k8s-access`
- `mise run k8s-delete-dev`

## Validation Workflow

- Run `mise run fmt`, `mise run lint`, `mise run test`, and `mise run check` before completion.
- Run `mise run typecheck` and `mise run docs-build` as part of full local validation.
- Run `mise run ci` before handoff to mirror CI behavior.
- If a step fails: fix root cause, rerun that step, then rerun dependent steps.

## Build, Test, and Lint Commands

### Canonical validation commands

```bash
mise run fmt          # Apply formatting fixes (ruff, shfmt)
mise run lint         # Run all lint checks with pre-commit
mise run typecheck    # Run static type checks (pyright)
mise run test         # Run repository and backend tests with coverage
mise run docs-build   # Build docs with MkDocs Material
mise run check        # Run lint + typecheck + test
mise run ci           # fmt-check + check + docs-build + security
mise run security     # Focused security checks
```

### Running single tests

Backend (pytest):

```bash
# Specific test file
cd services/inventory-service && uv run --extra dev pytest tests/unit/test_inventory_use_cases.py

# Specific test function
cd services/inventory-service && uv run --extra dev pytest tests/unit/test_inventory_use_cases.py::test_create_and_list_products

# Pattern
cd services/inventory-service && uv run --extra dev pytest -k "test_create"
```

Frontend (no test framework configured yet):

```bash
cd apps/web && npm run build
```

### Development servers

```bash
mise run backend-dev
mise run frontend-dev
mise run app-bootstrap
mise run backend-migrate
```

### Manual lint/format commands

```bash
# Python
ruff check .
ruff format .

# Shell
shfmt -w -i 2 -ci script.sh
shellcheck script.sh
```

## Code Style Guidelines

### Python (inventory-service)

Formatting:

- Use `ruff format`.
- 4-space indentation, no tabs.
- Keep lines at ruff defaults (88 chars).

Imports:

- Use absolute imports from package root (`inventory_service...`).
- Group imports stdlib -> third-party -> local.
- Prefer `collections.abc` generics (`Callable`, `Sequence`).

Types:

- Python 3.12+ typing syntax.
- Use `X | None` over `Optional[X]`.
- Annotate return types.

Naming:

- `snake_case` for functions/variables/modules.
- `PascalCase` for classes/exceptions.
- `SCREAMING_SNAKE_CASE` for constants.
- Prefix private members with `_`.

Error handling:

- Use domain-specific exceptions or `ValueError` for validation.
- FastAPI adapters use `HTTPException` for HTTP concerns.
- Use context managers for unit-of-work/session lifecycle.

Architecture:

- Preserve hexagonal boundaries: domain, application, ports, adapters.
- Keep dependencies directed inward (adapters -> ports/application/domain).

### TypeScript/React (apps/web)

Formatting:

- 2-space indentation in TS/TSX.
- Follow Vite/TypeScript defaults in this repo.

Types:

- Prefer explicit props and function signatures.
- Use `import type { ... }` for type-only imports.
- Keep API payload/response types centralized in feature `types/`.

Naming:

- `camelCase` for variables/functions.
- `PascalCase` for components.
- Hooks start with `use...`.

Organization:

- Use feature-based folders under `apps/web/src/features`.
- Keep API calls in `api/`, hooks in `hooks/`, UI in `components/`.

### General

- Prefer self-documenting code; add comments only for non-obvious intent.
- Keep functions focused and small.
- Prefer explicit behavior over implicit magic.
- Add tests for new behavior and edge cases.

## SDD Orchestrator Overlay (OpenCode)

Use this only when the user is clearly in Spec-Driven Development mode.

Triggers:

- `sdd init`, `sdd new`, `sdd ff`, `sdd continue`, `sdd apply`, `sdd verify`, `sdd archive`
- Multi-file feature/refactor requests needing staged planning

Operating rules:

- Delegate heavy phase work to sub-agents.
- Keep lead context lightweight: state tracking, approvals, summaries.
- Do not auto-run suggested next commands without user intent.

Artifact store modes:

- `engram` (recommended if available)
- `openspec` (only when user explicitly requests file artifacts)
- `none` (inline-only results)

Skill path convention:

- `~/.opencode/skills/sdd-init/SKILL.md`
- `~/.opencode/skills/sdd-explore/SKILL.md`
- `~/.opencode/skills/sdd-propose/SKILL.md`
- `~/.opencode/skills/sdd-spec/SKILL.md`
- `~/.opencode/skills/sdd-design/SKILL.md`
- `~/.opencode/skills/sdd-tasks/SKILL.md`
- `~/.opencode/skills/sdd-apply/SKILL.md`
- `~/.opencode/skills/sdd-verify/SKILL.md`
- `~/.opencode/skills/sdd-archive/SKILL.md`
