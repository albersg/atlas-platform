# Daily Workflow And Change Lifecycle

This is the standard path for taking a change from idea to validated repository
state. It is the safest default workflow if you are unsure what to do next.

## 1. Start a change safely

```bash
git status
```

- What it is for: shows your current branch and uncommitted work before you begin.
- When to run it: at the start of every change.
- What it tells you: whether you are building on a clean state or need to account for existing changes.
- Run next: choose the development loop you need.

## 2. Build in the smallest useful loop

Choose one of these:

- backend only: `mise run backend-dev`
- frontend only: `mise run frontend-dev`
- full stack: `mise run compose-up`
- Kubernetes lab: `mise run k8s-deploy-dev`

Pick the smallest loop that proves the change. Do not jump into GitOps or staging
workflows unless the change actually needs them.

Read more in [Local development](local-development.md) and
[Operations overview](../operations/overview.md).

## 3. Make the code and doc changes together

For a normal feature or fix, the expected order is:

1. update the application code,
2. add or update tests,
3. add a migration if persistence changes,
4. update documentation if behavior, commands, or workflows change,
5. inspect the diff before validation.

If the change affects platform architecture, environment behavior, monitoring,
release, or troubleshooting, update the docs in the same branch.

## 4. Run the normal validation path

```bash
mise run fmt
mise run lint
mise run typecheck
mise run test
mise run docs-build
mise run check
```

Why this order matters:

- `fmt` resolves safe formatting issues first.
- `lint` catches policy, style, and security issues early.
- `typecheck` validates backend and frontend static types.
- `test` validates repo policy and backend behavior.
- `docs-build` catches broken docs navigation or links.
- `check` reruns the core grouped path that CI expects locally.

## 5. Reproduce the CI path before a pull request

```bash
mise run ci
```

- What it is for: the closest local equivalent to the main CI path.
- Under the hood: runs `fmt-check`, `check`, `k8s-validate-overlays`, `docs-build`, and `security`.
- Good outcome: you can expect fewer surprises from GitHub Actions.

## 6. Move beyond local only when needed

- Use [k3s dev environment](../operations/k3s-dev.md) when you need Kubernetes-specific validation.
- Use [Staging-local](../operations/staging-local.md) when you want to rehearse the GitOps topology locally.
- Use [Canonical staging](../operations/canonical-staging.md) and
  [Staging promotion](../operations/staging-promotion.md) when the change is ready for the real staging path.

Helpful rule:

- local proves app behavior,
- `dev` proves Kubernetes behavior,
- `staging-local` proves the GitOps topology locally,
- canonical `staging` proves the release-like contract.

## 7. Pull request readiness checklist

- The right local loop worked for the change.
- Validation commands passed.
- Docs changed if behavior or workflow changed.
- No secrets or sensitive material entered the diff.
- The rollback or operational risk is understood for platform-affecting changes.

## Related guides

- [Local development](local-development.md)
- [Backend development](backend-development.md)
- [Frontend development](frontend-development.md)
- [Database and migrations](database-migrations.md)
- [Quality and CI](quality-and-ci.md)
