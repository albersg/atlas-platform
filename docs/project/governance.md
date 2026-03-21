# Project Governance

Atlas Platform combines collaboration rules, security requirements, and automation
so the workflow stays predictable for both humans and agents.

## Governance documents

- `AGENTS.md`: operating contract for agent sessions.
- `CONTRIBUTING.md`: local workflow, PR expectations, and commit quality rules.
- `SECURITY.md`: reporting channel and secure-development requirements.
- `.github/CODEOWNERS`: required review ownership.
- `.github/pull_request_template.md`: base pull request structure.

## Collaboration rules

Summary of `CONTRIBUTING.md`:

- start each change with `git status`,
- keep changes small and in scope,
- do not bypass hooks or CI,
- never commit sensitive material,
- run `mise run check`, `mise run security`, and `mise run ci` before a PR.

## Agent rules

Summary of `AGENTS.md`:

- do not use `git commit --no-verify`,
- do not run destructive actions without explicit request,
- do not touch credentials or sensitive material,
- use `mise run ...` as the primary operational interface,
- keep changes minimal, reversible, and in scope.

## Security policy

Summary of `SECURITY.md`:

- do not open public issues with exploit details,
- report vulnerabilities privately to maintainers,
- include impact, reproduction, and affected files,
- maintain least privilege, secret scanning, and validation before merge.

## Ownership and review

- at least one CODEOWNER should review relevant changes,
- workflows and automation should stay pinned by full SHA where required,
- security-sensitive changes should describe risk and rollback in the pull request.

## GitHub references

- [AGENTS.md](https://github.com/albersg/atlas-platform/blob/main/AGENTS.md)
- [CONTRIBUTING.md](https://github.com/albersg/atlas-platform/blob/main/CONTRIBUTING.md)
- [SECURITY.md](https://github.com/albersg/atlas-platform/blob/main/SECURITY.md)
- [CODEOWNERS](https://github.com/albersg/atlas-platform/blob/main/.github/CODEOWNERS)
