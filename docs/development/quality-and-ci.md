# Quality And CI

Atlas Platform uses one validation story across local work and GitHub Actions.
The goal is simple: the commands you run locally should explain what CI will do later.

If you are a beginner, treat this page as the answer to: "How do I know my change
is safe before I open a pull request?"

## Which quality tools matter here

| Tool | What it protects |
| --- | --- |
| `pre-commit` | one place to run formatting, linting, policy, and secret-scanning hooks |
| `ruff` | Python style and formatting correctness |
| `pyright` | backend type safety |
| `pytest` | backend unit and service behavior |
| `gitleaks` and `detect-secrets` | accidental secrets in the repo |
| GitHub Actions | repeatable CI, security, and release automation |
| Dependabot | routine dependency update pull requests |
| dependency review | blocks risky dependency changes on pull requests |

## Recommended command order

| Command | Why you run it |
| --- | --- |
| `mise run fmt` | apply safe formatting fixes first |
| `mise run lint` | catch style, policy, and security issues |
| `mise run typecheck` | validate backend and frontend static types |
| `mise run test` | run repo policy tests and backend unit tests |
| `mise run docs-build` | make sure docs navigation and links still work |
| `mise run check` | rerun the standard grouped local validation path |
| `mise run ci` | approximate the full CI pipeline locally |

## Key commands explained

### `mise run fmt`

- Purpose: apply safe auto-fixes.
- Under the hood: runs selected `pre-commit` hooks for whitespace, line endings, shell formatting, and Python formatting.
- Run next: `mise run lint`.

### `mise run lint`

- Purpose: run lint and policy checks.
- Under the hood: validates the pre-commit config, then runs the full hook set with bounded retries.
- Tooling detail: this is where `ruff`, Markdown linting, shell checks, YAML validation, and repository policy hooks usually run.
- Useful detail: `MISE_LINT_MAX_TRIES` controls the retry cap and defaults to `3`.
- Run next: `mise run typecheck` or inspect any hook-modified files.

### `mise run test`

- Purpose: run both repository-level policy tests and backend unit tests.
- Under the hood: runs `python -m unittest discover` in `tests/` and backend `pytest` unit tests through `uv`.
- Tooling detail: `uv` ensures the backend test command uses the pinned Python environment.

### `mise run check`

- Purpose: grouped local validation.
- Under the hood: runs `lint`, `typecheck`, `frontend-build`, and `test`.
- Important detail: it does not include `docs-build`; run that separately when docs change.

### `mise run ci`

- Purpose: closest local reproduction of the CI path.
- Under the hood: runs `fmt-check`, `check`, `k8s-validate-overlays`, `docs-build`, and `security`.
- When to run it: before a pull request or whenever you changed platform or docs behavior.

## Security and policy tools in the pipeline

- `detect-secrets` and `gitleaks` look for committed secrets.
- `check-github-workflows` and `zizmor` look for unsafe GitHub Actions patterns.
- `k8s-validate-overlays` renders manifests, applies Kyverno policy bundles, verifies trusted images, and schema-checks the result.
- `istioctl analyze` checks staged mesh configuration before rollout.
- The image release path later adds Trivy scanning, Syft SBOM generation, and Cosign signing.

This means validation is not only about code style. It also checks deployment
correctness, secrets safety, mesh configuration, and supply-chain trust.

## What GitHub Actions does

Main workflows:

- `.github/workflows/ci.yml`: core validation on pushes and pull requests.
- `.github/workflows/security.yml`: focused security scanning.
- `.github/workflows/codeql.yml`: CodeQL analysis.
- `.github/workflows/dependency-review.yml`: blocks risky new runtime dependencies in pull requests.
- `.github/workflows/release-images.yml`: build, scan, sign, and publish images.
- `.github/workflows/promote-staging.yml`: open or update the digest-promotion pull request.

## Automated dependency maintenance

- `.github/dependabot.yml` keeps GitHub Actions, Python, npm, and Docker inputs moving.
- Dependency update PRs still go through the same local and CI checks as any other change.

## Common failure patterns

- `fmt-check` fails because a formatter wants to change files: run `mise run fmt`.
- `lint` fails after tool changes: run `mise run bootstrap` to refresh hooks.
- `docs-build` fails: inspect nav changes, links, and missing files.
- `k8s-validate-overlays` fails: treat it as a platform or secrets-rendering problem, not just a docs problem.

## Read next

- [Command reference](../reference/commands.md)
- [Troubleshooting](../reference/troubleshooting.md)
