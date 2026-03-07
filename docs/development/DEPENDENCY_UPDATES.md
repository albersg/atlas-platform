# Automatic Dependency Updates

This repository uses Dependabot for automated dependency updates.

## What is automated

- GitHub Actions dependencies (`.github/workflows/*`)
- Python dependencies for `services/inventory-service`
- npm dependencies for `apps/web`

Dependabot configuration lives in `/.github/dependabot.yml`.

## Dependabot update policy

- Weekly schedule (Monday, Europe/Madrid).
- Patch/minor updates are grouped by ecosystem.
- Cooldown is configured to reduce noisy PR churn.
- PR labels identify update origin (`deps:ci`, `deps:python`, `deps:frontend`).

## How to enable in GitHub

1. Go to `Settings -> Security & analysis`.
2. Enable `Dependency graph`.
3. Enable `Dependabot alerts`.
4. Keep `Dependabot security updates` enabled.

## Recommended review flow

1. Let Dependabot open PRs automatically.
2. Validate each PR with CI checks.
3. Merge patch/minor updates quickly when checks pass.
4. Review major updates manually and test behavior before merge.

## Manual refresh (optional batch update)

Use this when you want to proactively refresh everything:

```bash
# Backend Python
cd services/inventory-service
uv lock --upgrade
uv sync --extra dev
uv run --extra dev pytest tests
cd ../..

# Frontend npm
cd apps/web
npx npm-check-updates -u
npm install
npm run build
cd ../..

# Tooling
pre-commit autoupdate
mise lock

# Full validation
mise run lint
mise run check
mise run docs-build
mise run security
```

## Container vulnerabilities (Trivy)

Dependabot does not fully solve OS-level image CVEs by itself.
Keep a periodic base-image refresh routine and verify with Trivy scans.
