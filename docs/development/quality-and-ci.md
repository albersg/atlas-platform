# Quality And CI

Atlas Platform uses one validation story across local work and GitHub Actions.
The goal is simple: the commands you run locally should explain what CI will do
later, and the security/release story should feel like an extension of that same
contract.

## The quality stack at a glance

| Layer | Main tools | What they protect | Repo ownership |
| --- | --- | --- | --- |
| formatting and basic hygiene | `pre-commit`, `ruff`, `shfmt`, whitespace hooks | readable source and low-noise diffs | `.pre-commit-config.yaml`, `mise.toml` |
| lint and policy | `pre-commit`, YAML/Markdown checks, shell checks | repo consistency and policy safety | `.pre-commit-config.yaml` |
| static analysis | `pyright`, TypeScript typecheck | type-safety regressions | `mise.toml`, app configs |
| tests | `unittest`, `pytest` | repository and backend behavior | `tests/`, `services/inventory-service/tests/` |
| docs validation | MkDocs strict build | broken links and nav drift | `mkdocs.yml`, docs tree |
| platform validation | Kustomize, KSOPS, Helm, Kyverno, kubeconform, `istioctl` | invalid manifests, policy drift, mesh mistakes | `platform/**`, `scripts/gitops/validate-overlays.sh` |
| security and supply chain | `detect-secrets`, `gitleaks`, `zizmor`, Trivy, Syft, Cosign | secrets leaks, unsafe workflows, vulnerable or untrusted images | hooks plus release workflows |

## Recommended local order

| Command | Why you run it |
| --- | --- |
| `mise run fmt` | apply safe auto-fixes first |
| `mise run lint` | catch hook-level style, docs, policy, and security issues |
| `mise run typecheck` | validate backend and frontend static types |
| `mise run test` | run repo policy tests and backend unit tests |
| `mise run docs-build` | prove docs nav and links still work |
| `mise run check` | rerun the grouped code-quality path |
| `mise run ci` | rehearse the full CI-grade path, including platform and security checks |

## What each grouped command really means

### `mise run fmt`

- Runs selected manual `pre-commit` hooks, not the whole hook set.
- Fixes whitespace, line endings, shell formatting, and Python formatting.
- Exists so low-risk formatting changes happen before more serious lint feedback.

### `mise run lint`

- Validates `.pre-commit-config.yaml`, then runs the entire hook set with retries.
- Is the main integration point for `ruff`, Markdown linting, YAML checks, shell checks, workflow linting, and repo policy checks.
- Uses `MISE_LINT_MAX_TRIES` because some hooks legitimately make sequential edits.

### `mise run test`

- Runs two different suites on purpose:
  - `tests/` for repository policy tests,
  - `services/inventory-service/tests/unit` for backend behavior.
- Uses `uv` so backend tests always run on the pinned Python environment.

### `mise run check`

- Re-runs the core development path: `lint`, `typecheck`, `frontend-build`, `test`.
- Is the standard "code is locally safe" checkpoint.
- Does not include docs build or full platform validation.

### `mise run ci`

- Adds the missing repo-wide surfaces on top of `check`:
  - formatting cleanliness via `fmt-check`,
  - manifest and policy validation via `k8s-validate-overlays`,
  - docs validation via `docs-build`,
  - focused security checks via `security`.
- Is the closest local approximation to what CI expects.

## The platform and DevSecOps part of validation

The most important beginner insight is this: quality in Atlas Platform is not only
about Python and TypeScript.

`mise run k8s-validate-overlays` is part of the quality story because the repo owns
deployable platform state, not only source code.

That command:

- renders the workload overlays for `dev`, `staging`, and `staging-local`,
- renders the staged platform-infra charts for Istio and Prometheus,
- combines staged workload and infra outputs,
- applies Kyverno policy bundles,
- asserts the staged monitoring contract still includes a `ServiceMonitor` and `/metrics`,
- verifies trusted canonical staging images with Cosign,
- schema-checks rendered output with kubeconform,
- runs `istioctl analyze` on the combined staged surfaces.

So a failing platform validation is not a side quest. It is part of the same
quality contract as a failing unit test.

## How GitHub Actions maps to local work

Main workflows:

- `.github/workflows/ci.yml`: core validation on pushes and pull requests.
- `.github/workflows/security.yml`: focused security scanning.
- `.github/workflows/codeql.yml`: CodeQL analysis.
- `.github/workflows/dependency-review.yml`: blocks risky runtime dependency changes on pull requests.
- `.github/workflows/release-images.yml`: builds, scans, signs, and publishes images.
- `.github/workflows/promote-staging.yml`: rewrites staging digests, validates overlays, and creates or updates the promotion pull request.

## Release and promotion as the final quality gates

Release and promotion extend the same validation story instead of replacing it.

- `release-images.yml` builds the backend and web images from `main`.
- Trivy scans those published images for high and critical vulnerabilities.
- Syft generates SBOMs so the image contents are inspectable.
- Cosign signs the digests and attaches attestations.
- `promote-staging.yml` rewrites canonical staging digests, revalidates overlays, and creates the promotion PR.
- canonical staging deployment then verifies the promoted digests again before trusting them.

This means the repo's DevSecOps story has three layers:

1. local and CI checks stop bad source or manifest changes early,
2. release hardens the produced images,
3. promotion and canonical staging only trust signed immutable digests.

## Common failure patterns

| Failure | What it usually means | First response |
| --- | --- | --- |
| `fmt-check` fails | formatters still want to edit files | run `mise run fmt` |
| `lint` fails after a hook edit | a later hook now sees new input | inspect the failing hook, then rerun `mise run lint` |
| `docs-build` fails | nav, link, or file references drifted | inspect `mkdocs.yml` and the referenced docs paths |
| `k8s-validate-overlays` fails early | render or decryption problem | rerun the relevant render command and verify SOPS or helper tooling |
| `k8s-validate-overlays` fails late | policy, schema, trust, or mesh problem | identify whether Kyverno, Cosign, kubeconform, or `istioctl` failed |
| release workflow fails | published image did not pass scan, SBOM, or signing steps | inspect `.github/workflows/release-images.yml` behavior |
| promotion workflow fails | digest rewrite, overlay validation, or SOPS materialization failed | inspect `.github/workflows/promote-staging.yml` and `scripts/release/promote-by-digest.sh` |

## Read next

- [Command reference](../reference/commands.md)
- [Configuration and environment variables](../reference/configuration.md)
- [Release workflow](../operations/release-workflow.md)
- [Troubleshooting](../reference/troubleshooting.md)
