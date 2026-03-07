# Contributing

## Ground rules

- Start every change with `git status`.
- Keep changes small and scoped.
- Do not bypass hooks or CI.
- Do not commit secrets.

## Local workflow

1. `mise install`
2. `mise run bootstrap`
3. Implement the change.
4. Run `mise run fix` when safe auto-fixes are needed.
5. Run `mise run check`.
6. Run `mise run security`.
7. Run `mise run ci` before opening a pull request.

## Pull request requirements

- CI must be green.
- Security and dependency workflows must pass.
- Action references in workflows must remain pinned by full SHA.
- At least one CODEOWNER review is required.
- Include risk notes for security-relevant changes.

## Commit quality

- One logical change per commit.
- Message must explain intent and impact.
- Never use `git commit --no-verify`.
