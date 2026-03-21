# Rebuild This Platform By Hand

Use this guide when your question is: "How would I rebuild a repo like Atlas
Platform from scratch without copying everything at once?"

This is an implementation roadmap, not a giant solved dump. The goal is to help
you build the same ideas in another repository phase by phase, with enough
validation and investigation at each step that you understand why the next layer
exists.

## How to use this guide

- Build one phase at a time.
- Do not add the next tool just because the final repo uses it.
- Stop at each checkpoint and prove the current layer works before adding more
  abstraction.
- Read the referenced Atlas docs and compare them with the files they mention.
- Treat every phase as a small design exercise, not a copying exercise.

## Recommended build order

1. Baseline repo and local workflow
2. Local app runtime
3. Docker images
4. First Kubernetes `dev`
5. Helm base plus Kustomize overlays
6. SOPS plus KSOPS
7. Argo CD and GitOps
8. Kyverno
9. Istio
10. Prometheus
11. Canonical staging and promotion

## Phase 1: Baseline repo and local workflow

### Phase 1 objective

Create a small monorepo with a clear developer front door, repeatable local
validation, and docs that explain how work happens.

### Phase 1 what to build

- A repo layout for app code, platform assets, scripts, and docs.
- A single command entrypoint such as `mise run ...` or an equivalent task runner.
- Formatting, lint, typecheck, test, and docs tasks.
- A short contributor workflow that says how changes are validated before merge.

### Phase 1 what to read in this repo

- [What is Atlas Platform?](what-is-atlas-platform.md)
- [Tooling primer](tooling-primer.md)
- [Repository tour](repository-map.md)
- [Daily workflow and change lifecycle](../development/END_TO_END_WORKFLOW.md)
- [Quality and CI](../development/quality-and-ci.md)
- `mise.toml`, `.pre-commit-config.yaml`, and `AGENTS.md`

### Phase 1 what to validate before moving on

- A new contributor can clone the repo, install tools, and run one bootstrap path.
- `fmt`, `lint`, `typecheck`, `test`, and docs build all have one obvious entrypoint.
- The repo structure matches the docs instead of relying on tribal knowledge.

### Phase 1 common mistakes to avoid

- Adding Kubernetes, Helm, or Argo CD before the everyday developer loop feels boring and reliable.
- Creating many custom scripts before deciding what your task runner owns.
- Writing docs that describe an ideal workflow instead of the real commands.

### Phase 1 questions to answer before continuing

- Why is this one repo instead of several repos?
- What command should a teammate run first after cloning?
- Which checks are required before a change is considered safe?

## Phase 2: Local app runtime

### Phase 2 objective

Make the application runnable on a laptop without Kubernetes so product and code
feedback stay fast.

### Phase 2 what to build

- Backend and frontend dev flows.
- A local database path.
- A full local runtime, preferably direct processes first and optionally Compose.
- Health endpoints and basic smoke checks.

### Phase 2 what to read in this repo

- [First-day setup](quickstart.md)
- [Local development](../development/local-development.md)
- [Backend development](../development/backend-development.md)
- [Frontend development](../development/frontend-development.md)
- [Database and migrations](../development/database-migrations.md)
- [Local Compose](../operations/local-compose.md)

### Phase 2 what to validate before moving on

- You can start backend, frontend, and database locally.
- The frontend can reach the backend.
- Migrations are reproducible.
- A new feature can be developed and verified without cluster tooling.

### Phase 2 common mistakes to avoid

- Reaching for Kubernetes because the final platform uses Kubernetes.
- Hiding broken local developer ergonomics behind Compose only.
- Skipping health and readiness checks that later environments depend on.

### Phase 2 questions to answer before continuing

- What is the fastest loop for changing backend code?
- What is the fastest loop for changing frontend code?
- Which problems actually require containers or Kubernetes, and which do not?

## Phase 3: Docker images

### Phase 3 objective

Turn the local application into reproducible container images without yet turning
containers into your main development environment.

### Phase 3 what to build

- Dockerfiles for the backend and frontend.
- A local image build path.
- A Compose path that uses those images together.
- Clear image naming and tagging conventions for local work.

### Phase 3 what to read in this repo

- [Tooling primer](tooling-primer.md)
- [Local Compose](../operations/local-compose.md)
- `docker-compose.yml`
- the app Dockerfiles and the image-related tasks in `mise.toml`

### Phase 3 what to validate before moving on

- Images build cleanly from the repo root or one documented command.
- Compose can run the same app shape your images define.
- The image boundaries match the runtime boundaries you expect later in Kubernetes.

### Phase 3 common mistakes to avoid

- Treating Compose as proof that Kubernetes manifests will work.
- Baking too much environment-specific config into the images.
- Introducing release signing, digest promotion, or registry policy before basic image builds are stable.

### Phase 3 questions to answer before continuing

- What belongs in an image versus an environment variable?
- How would you prove two developers are running the same containerized app shape?
- Which parts of your app still assume a laptop-only runtime?

## Phase 4: First Kubernetes `dev`

### Phase 4 objective

Create the first cluster-based environment as a learning lab, not as your final
delivery architecture.

### Phase 4 what to build

- A local k3s cluster path.
- Kubernetes manifests for app workloads, services, ingress, jobs, and database.
- A simple `dev` namespace and smoke-test flow.
- A local image build and import flow for the cluster.

### Phase 4 what to read in this repo

- [Operations overview](../operations/overview.md)
- [k3s dev environment](../operations/k3s-dev.md)
- [Configuration and environment variables](../reference/configuration.md)
- `platform/k8s/overlays/dev/**`
- `platform/k8s/components/**`

### Phase 4 what to validate before moving on

- You can render and apply the `dev` environment repeatedly.
- The cluster uses locally built images instead of pretending to be release-like.
- Smoke checks, ingress, workload health, and migrations all work in the cluster.

### Phase 4 common mistakes to avoid

- Calling this environment staging just because it uses Kubernetes.
- Adding Argo CD, SOPS, or Istio before you can explain the plain Kubernetes shape.
- Mixing local development shortcuts with the later staging trust model.

### Phase 4 questions to answer before continuing

- Why does `dev` exist if Compose already exists?
- Which cluster problems appear here that local app runtime did not show?
- What should stay intentionally simpler in `dev` than in staging?

## Phase 5: Helm base plus Kustomize overlays

### Phase 5 objective

Separate reusable package logic from environment-specific adaptation.

### Phase 5 what to build

- A reusable Helm layer for workload or platform bases.
- Kustomize overlays for `dev`, `staging-local`, and `staging` differences.
- A documented ownership rule for what belongs in Helm versus Kustomize.

### Phase 5 what to read in this repo

- [Platform delivery architecture](../architecture/platform-delivery-architecture.md)
- [Deployment topology](../architecture/deployment-topology.md)
- [Tool ownership matrix](../reference/tool-ownership-matrix.md)
- `platform/helm/**`
- `platform/k8s/overlays/**`

### Phase 5 what to validate before moving on

- Shared packaging renders from Helm without environment-specific drift.
- Overlay differences are visible in Kustomize instead of being hidden in chart conditionals.
- You can explain why each environment difference lives where it lives.

### Phase 5 common mistakes to avoid

- Using Helm values as a second overlay system.
- Using Kustomize to duplicate reusable packages that should be chart-owned.
- Adding secret decryption or GitOps before the render boundaries are clear.

### Phase 5 questions to answer before continuing

- Which settings are reusable package defaults, and which are overlay concerns?
- If a new environment appears tomorrow, where would that work go?
- What examples in your repo prove the Helm/Kustomize split is real?

## Phase 6: SOPS plus KSOPS

### Phase 6 objective

Keep secrets encrypted in Git while preserving deterministic local and staged
render flows.

### Phase 6 what to build

- SOPS-encrypted secret files for staged overlays.
- age key generation and storage guidance.
- KSOPS integration for local Kustomize rendering.
- A rule that plain-text secrets never enter the repo.

### Phase 6 what to read in this repo

- [GitOps bootstrap](../operations/gitops-bootstrap.md)
- [Configuration and environment variables](../reference/configuration.md)
- [GitOps runbook](../deployment/gitops/ARGOCD_SOPS_RUNBOOK.md)
- `.sops.yaml`
- `platform/k8s/overlays/*/secrets/*.enc.yaml`
- `platform/k8s/overlays/*/ksops-generator.yaml`

### Phase 6 what to validate before moving on

- Encrypted secrets stay encrypted in Git.
- Authorized local renders can decrypt them consistently.
- Missing keys fail clearly instead of failing as mystery Kustomize errors.

### Phase 6 common mistakes to avoid

- Adding secret tooling before you actually have staged overlays that need it.
- Treating KSOPS as a general template engine instead of a decryption bridge.
- Storing private keys in the repo or in undocumented machine-specific locations.

### Phase 6 questions to answer before continuing

- Where does secret ciphertext live?
- Where does decryption authority live?
- How would a new operator gain access without copying random local state?

## Phase 7: Argo CD and GitOps

### Phase 7 objective

Move from manual apply flows to continuous reconciliation where Git becomes the
desired source of truth for staged environments.

### Phase 7 what to build

- Argo CD app definitions.
- A bootstrap flow for repo credentials, decryption keys, and app installation.
- A clear split between workload apps and platform-infra apps.
- A local rehearsal environment for the staged architecture.

### Phase 7 what to read in this repo

- [GitOps bootstrap](../operations/gitops-bootstrap.md)
- [Staging-local](../operations/staging-local.md)
- [Platform delivery architecture](../architecture/platform-delivery-architecture.md)
- `platform/argocd/apps/**`
- `scripts/gitops/bootstrap/*.sh`
- `scripts/gitops/deploy/staging.sh`

### Phase 7 what to validate before moving on

- Argo CD can reconcile your staged workload app from Git.
- Bootstrap steps are documented and reproducible.
- Manual cluster edits get overwritten by GitOps as expected.
- Infra apps and workload apps can fail and recover independently.

### Phase 7 common mistakes to avoid

- Introducing GitOps before your render model is understandable locally.
- Letting Argo CD hide broken render logic that should have been validated first.
- Mixing workload ownership and infra ownership into one giant app.

### Phase 7 questions to answer before continuing

- What exactly does Argo CD reconcile in each environment?
- Why is GitOps useful here beyond "it is industry standard"?
- Which parts of the staged platform should reconcile before workloads?

## Phase 8: Kyverno

### Phase 8 objective

Add policy checks that reject invalid rendered manifests before they reach the
cluster or before you trust them.

### Phase 8 what to build

- A small Kyverno policy set tied to your real repo rules.
- Local validation commands that render manifests and run policy checks.
- Policies for the specific mistakes you already know are dangerous.

### Phase 8 what to read in this repo

- [Platform delivery architecture](../architecture/platform-delivery-architecture.md)
- [Quality and CI](../development/quality-and-ci.md)
- [Troubleshooting](../reference/troubleshooting.md)
- `platform/policy/kyverno/**`
- `scripts/gitops/validate-overlays.sh`

### Phase 8 what to validate before moving on

- Policies run on rendered output, not just on hand-picked examples.
- Failure messages teach the contributor what rule they broke.
- The policy set is small enough to understand and maintain.

### Phase 8 common mistakes to avoid

- Writing policies before you have stable render outputs to validate.
- Adding abstract policy for hypothetical future problems.
- Turning policy into a second undocumented architecture layer.

### Phase 8 questions to answer before continuing

- Which platform mistakes are common enough to deserve policy?
- Why is this rule better as policy than as a code review reminder?
- Can a contributor understand a failure without reading Kyverno internals first?

## Phase 9: Istio

### Phase 9 objective

Introduce a staged service mesh only after simpler ingress and environment flows
already work.

### Phase 9 what to build

- Helm-managed Istio base, control plane, and gateway packaging.
- Workload-side mesh resources in staged overlays.
- A small first wave of sidecar-enabled workloads.
- Mesh-aware validation and smoke checks.

### Phase 9 what to read in this repo

- [Service mesh](../operations/service-mesh.md)
- [Staging-local](../operations/staging-local.md)
- [Canonical staging](../operations/canonical-staging.md)
- `platform/helm/istio/**`
- `platform/k8s/components/mesh/istio/**`

### Phase 9 what to validate before moving on

- The mesh is limited to staged environments, not forced into every environment.
- Gateway routing, sidecar injection, and readiness behavior all work for the first wave.
- Local rehearsal proves the topology before canonical staging depends on it.

### Phase 9 common mistakes to avoid

- Adding Istio before plain ingress behavior is already understood.
- Mesh-enabling every workload at once.
- Treating `dev` and staged traffic as if they should have the same complexity.

### Phase 9 questions to answer before continuing

- Why does the repo use Istio only in staged paths?
- Which resources belong to infra packaging versus workload overlays?
- How would you roll back the first mesh wave safely?

## Phase 10: Prometheus

### Phase 10 objective

Add observability as a staged platform capability while keeping workload scrape
intent owned by the workload layer.

### Phase 10 what to build

- A Helm-managed Prometheus stack for staged environments.
- A first workload metrics endpoint.
- A workload-owned `ServiceMonitor` or equivalent scrape declaration.
- Health and smoke checks that prove metrics wiring exists.

### Phase 10 what to read in this repo

- [Monitoring](../operations/monitoring.md)
- [Service mesh](../operations/service-mesh.md)
- [Staging-local](../operations/staging-local.md)
- `platform/helm/prometheus/**`
- `platform/k8s/components/observability/prometheus/**`

### Phase 10 what to validate before moving on

- Prometheus itself is healthy.
- The workload metrics endpoint exists.
- The workload scrape declaration is present and labeled correctly.
- You can tell the difference between infra health and workload observability wiring.

### Phase 10 common mistakes to avoid

- Adding a full observability suite before one useful metric path exists.
- Hiding workload scrape intent inside the shared infra chart.
- Assuming Prometheus being up means workload metrics are actually connected.

### Phase 10 questions to answer before continuing

- Who owns the monitoring stack, and who owns scrape intent?
- What is the minimum evidence that metrics wiring works?
- Why is this added after GitOps and staged topology, not before?

## Phase 11: Canonical staging and promotion

### Phase 11 objective

Finish with a real pre-production path that trusts immutable published artifacts
instead of local mutable images.

### Phase 11 what to build

- A canonical staging overlay separate from `staging-local`.
- Release automation that builds, scans, generates SBOMs, and signs images.
- Promotion tooling that rewrites Git to trusted digests.
- Verification that canonical staging only consumes trusted artifacts.

### Phase 11 what to read in this repo

- [Canonical staging](../operations/canonical-staging.md)
- [Release workflow](../operations/release-workflow.md)
- [Staging promotion](../operations/staging-promotion.md)
- [Image promotion runbook](../deployment/releases/IMAGE_PROMOTION.md)
- `.github/workflows/release-images.yml`
- `.github/workflows/promote-staging.yml`
- `scripts/release/*.sh`

### Phase 11 what to validate before moving on

- Canonical staging points to digests, not mutable tags.
- Trust verification fails unsafe or unsigned images.
- Promotion is reviewable in Git and reproducible.
- `staging-local` remains a rehearsal path and does not silently become canonical staging.

### Phase 11 common mistakes to avoid

- Collapsing rehearsal and canonical staging into one environment.
- Introducing digest promotion before a release pipeline exists.
- Treating release, promotion, and deployment as the same step.

### Phase 11 questions to answer before continuing

- Why are digests trusted more than tags?
- What is the difference between release, promotion, and deployment here?
- Which guarantees should canonical staging provide that `staging-local` intentionally does not?

## How to know you are rebuilding the ideas instead of copying the files

- You can explain why each tool enters the story when it does.
- You can remove a phase and predict what capability disappears.
- You know which repo paths represent reusable platform packaging versus environment adaptation.
- You can describe the difference between a local learning convenience and a canonical trust requirement.

## Suggested investigation habit for every phase

1. Read the linked docs first.
2. Open the referenced files.
3. Write down what problem that phase is solving.
4. Implement the smallest version in your own repo.
5. Validate it.
6. Only then compare your solution with Atlas Platform again.

That rhythm will teach you more than copying finished manifests ever will.

## Read next

1. [Beginner study roadmap](beginner-study-roadmap.md) for the reading-first route.
2. [Choose your path](choose-your-path.md) for intent-based navigation.
3. [Platform delivery architecture](../architecture/platform-delivery-architecture.md) if you want to revisit the ownership model after this roadmap.
