# Policy-as-Code Basics

Use this page when your question is: "Why does this repo use Kyverno, what is it
actually checking, and how should a beginner think about policy failures?"

## The short version

Atlas Platform does not trust rendered Kubernetes YAML just because it builds.
After Helm and Kustomize produce manifests, Kyverno checks that those manifests
still obey the repo's deployment rules.

Think of policy-as-code here as a review checklist that runs automatically on the
rendered output:

- Are probes present?
- Are resource requests and limits present?
- Is the container security context set?
- Are staged-only mesh resources kept out of `dev`?
- Does canonical `staging` use trusted image digests instead of mutable tags?

If one of those rules fails, the repo wants the change to stop before the cluster
or reviewer has to catch it manually.

## Where policy lives in this repo

| Path | What it means |
| --- | --- |
| `platform/policy/kyverno/common/` | Rules shared across the non-production overlays |
| `platform/policy/kyverno/staging/` | Extra rules that only canonical `staging` must satisfy |
| `scripts/gitops/validate-overlays.sh` | The script that renders overlays, assembles policy bundles, and runs Kyverno |
| `docs/development/quality-and-ci.md` | The docs page that explains where policy fits in validation |

## The mental model

Atlas Platform's platform flow is:

1. Helm renders reusable bases.
2. Kustomize adapts them for `dev`, `staging-local`, or `staging`.
3. Kyverno checks the rendered manifests against repo rules.
4. Only then do later trust and deployment steps matter.

That ordering is important. Policy is not replacing Helm, Kustomize, or Argo CD.
It sits beside them and asks: "Given the manifests this repo produced, are they
still allowed?"

## What kinds of mistakes policy catches

### Guardrail rules

These rules catch baseline safety mistakes that are easy to miss in review:

- missing liveness or readiness probes,
- missing resource requests and limits,
- missing container security settings,
- missing pod-security basics.

### Environment-boundary rules

These rules protect the repo's architecture decisions:

- `dev` should not quietly drift into staged Istio behavior,
- staged workloads should onboard to mesh and monitoring deliberately,
- canonical `staging` should use digests and staged routing instead of local shortcuts.

## How to read a policy failure as a beginner

When Kyverno fails, do not start by memorizing Kyverno syntax. Start with three
questions:

1. Which overlay or rendered surface failed: `dev`, `staging-local`, or `staging`?
2. What deployment rule is the repo trying to protect?
3. Which source layer probably owns the fix: Helm base, Kustomize overlay, or policy bundle?

Usually the fastest path is:

1. read the failing rule name,
2. inspect the rendered surface or the related overlay,
3. compare it with the ownership model in [Platform delivery architecture](../architecture/platform-delivery-architecture.md),
4. only then open the policy file if the rule intent is still unclear.

## Why this matters for beginners

Policy can feel abstract if it is only mentioned in CI or troubleshooting docs.
Here it is part of the platform design:

- it keeps architecture rules enforceable,
- it turns repeated code-review comments into executable checks,
- it teaches the difference between "valid YAML" and "acceptable platform state."

That is why Kyverno belongs in the beginner mental model, not only in the deep
operator runbooks.

## Read next

- Read [Platform delivery architecture](../architecture/platform-delivery-architecture.md) to see where policy sits relative to Helm, Kustomize, and Argo CD.
- Read [Deployment topology](../architecture/deployment-topology.md) to see where the policy bundles apply across environments.
- Read [Quality and CI](../development/quality-and-ci.md) to learn which commands run policy checks.
- Go back to [Choose your path](choose-your-path.md) if you want the best next route for your goal.
