# Agent-First DevSecOps Playbook

This document explains how this repository works as an enterprise-grade, agent-first engineering system with `mise` as the only command interface.

## 1. Tooling model

The stack is intentionally opinionated:

- `Codex CLI` is the agent execution layer.
- `mise` is the source of truth for tools and task orchestration.
- `pre-commit` is the policy and quality gate.
- `GitHub Actions` enforces the same gates in remote CI and security workflows.

Result:

- developers and agents run the same `mise run <task>` commands,
- quality and security checks are mandatory,
- behavior is reproducible across machines and CI.

## 2. Core control files

- `AGENTS.md`: operational contract for Codex CLI.
- `mise.toml`: pinned tools and canonical task graph.
- `mise.lock`: lock metadata for deterministic installs.
- `.pre-commit-config.yaml`: hooks and policy checks.
- `.secrets.baseline`: secret scan baseline for detect-secrets.
- `.github/workflows/*.yml`: CI, security, dependency, and automation workflows.
- `.github/CODEOWNERS`: mandatory ownership and review boundaries.
- `tests/test_repo_policy.py`: tests that enforce repository policy.

## 3. Design principles

1. Single source of truth: `mise.toml` defines tools and tasks.
2. Stable interface: humans and agents use canonical `mise run` tasks.
3. Policy as code: format/lint/security checks are codified.
4. Shift-left security: checks run locally before CI.
5. Reproducibility: tool versions are pinned and locked.
6. Defense in depth: hooks + tests + CI + security workflows.

## 4. Canonical tasks

Primary tasks:

- `mise run bootstrap`
- `mise run fmt`
- `mise run lint`
- `mise run security`
- `mise run test`
- `mise run check`
- `mise run fix`
- `mise run ci`

Extended tasks:

- `mise run fmt-check`
- `mise run hooks-update`
- `mise run lock`
- `mise run doctor`
- `mise run app-bootstrap`
- `mise run backend-dev`
- `mise run backend-migrate`
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

## 5. End-to-end workflow

Local:

1. `mise install`
2. `mise run bootstrap`
3. `mise run fix`
4. `mise run check`
5. `mise run ci`

Remote:

1. Pull request triggers CI workflows.
2. CI executes the same canonical task path (`mise run ci`).
3. Security workflows add dedicated gates (CodeQL, dependency review, security checks).

## 6. CI strategy

- Main workflow: `.github/workflows/ci.yml`
- Security workflow: `.github/workflows/security.yml`
- Dependency review: `.github/workflows/dependency-review.yml`
- CodeQL: `.github/workflows/codeql.yml`
- Pre-commit autoupdate: `.github/workflows/pre-commit-autoupdate.yml`

Hardening rules:

- actions pinned by full SHA,
- minimal permissions,
- `persist-credentials: false` on checkout.

## 7. Operational playbooks

First day setup:

1. Clone repo.
2. Ensure shell has `mise` activation.
3. Run `mise install`.
4. Run `mise run bootstrap`.
5. Run `mise run ci`.

Feature development:

1. `git status`
2. Implement change.
3. `mise run fix`
4. `mise run check`
5. `mise run ci`

Security-sensitive change:

1. Implement minimal scoped change.
2. `mise run security`
3. `mise run ci`
4. Document threat impact and rollback plan in PR.

## 8. Policy tests

`tests/test_repo_policy.py` enforces:

1. required governance/security files exist,
2. core tools are pinned in `mise.toml`,
3. canonical tasks exist in `mise.toml`,
4. required hooks exist in `.pre-commit-config.yaml`,
5. GitHub Actions are pinned by SHA.

## 9. Troubleshooting

`mise: command not found`

- initialize `mise` in shell and restart terminal.
- run `mise install`.

Hook failures:

- run `pre-commit clean`.
- run `mise run bootstrap`.
- rerun `mise run lint` and `mise run security`.

`fmt-check` fails due to diff:

- run `mise run fix`.
- stage changes.
- rerun `mise run ci`.

## 10. Extension rules

When adding a new language/tool:

1. pin tool in `mise.toml`,
2. add hooks in `.pre-commit-config.yaml`,
3. add/extend tasks in `mise.toml`,
4. update policy tests if needed,
5. run `mise run lock`,
6. run `mise run ci`.

When adding workflows:

1. pin actions by SHA,
2. minimize permissions,
3. keep checkout hardening,
4. ensure workflow is covered by existing lint/security hooks.
