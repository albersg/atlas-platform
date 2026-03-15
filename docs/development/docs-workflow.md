# Docs Workflow

Documentation is part of the deliverable in this repo, not an afterthought.

## When you should update docs

Update docs when a change affects:

- setup steps,
- command behavior,
- contributor workflow,
- backend or frontend contracts,
- deployment or promotion procedures,
- environment variables or operational guardrails.

## Main command

```bash
mise run docs-build
```

- Purpose: verify that the documentation site still builds in strict mode.
- When to run it: every time you edit docs; also before opening a PR that changes workflows.
- Under the hood: runs `mkdocs build --strict` through `uvx` with MkDocs Material.
- Expected output: a successful site build with no broken nav entries or bad links.

## Optional live preview

```bash
mise run docs-serve
```

- Purpose: preview the docs locally in a browser.
- Under the hood: runs `mkdocs serve -a 0.0.0.0:8001`.
- Expected output: a local docs server on port `8001`.

## Writing guidance for this repo

- Prefer overview pages that link to deep runbooks instead of duplicating them.
- Keep commands faithful to `mise.toml` and the scripts it calls.
- Explain commands in plain language for first-time readers.
- Update `README.md`, `docs/index.md`, and `mkdocs.yml` when the reading path changes.

## Read next

- [Command reference](../reference/commands.md)
- [Troubleshooting](../reference/troubleshooting.md)
