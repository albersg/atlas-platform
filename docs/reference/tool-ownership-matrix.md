# Tool Ownership Matrix

Use this page when you want one answer to five questions:

1. what a tool is for,
2. who owns it in this repo,
3. where it is configured,
4. how it composes with the rest of the platform,
5. which commands make you care about it.

"Owner" here means the repo area that controls the tool's behavior, not a person.

Most beginners should not start here. Start with the
[tooling primer](../getting-started/tooling-primer.md), then return to this page
when you need a dense lookup table.

| Tool or concept | What it is for | Owner in this repo | Main configuration and source files | How it composes | Commands or workflows |
| --- | --- | --- | --- | --- | --- |
| `mise` | repo entry point for pinned tools and shared tasks | root automation layer | `mise.toml`, `mise.lock` | wraps almost every developer and operator workflow | most `mise run ...` tasks |
| `pre-commit` | unified lint, format, policy, and security hooks | quality layer | `.pre-commit-config.yaml` | powers local hooks and many `mise` quality tasks | `bootstrap`, `fmt`, `lint`, `security` |
| `uv` | backend dependency manager and Python command runner | backend service workflow | `mise.toml`, `services/inventory-service/pyproject.toml` | provides reproducible backend execution without a separate venv story in docs | `app-bootstrap`, `backend-*`, `test`, `typecheck` |
| `npm` | frontend dependency manager | frontend workflow | `apps/web/package.json` | supports Vite build, dev, and typecheck flows | `app-bootstrap`, `frontend-*` |
| Vite | frontend dev server and build tool | `apps/web` | `apps/web/package.json`, `apps/web/src/vite-env.d.ts` | reads `VITE_...` runtime values and produces the production web bundle | `frontend-dev`, `frontend-build`, `docs` references |
| FastAPI | backend HTTP framework | `services/inventory-service` | backend source tree under `services/inventory-service/src/` | runs behind Compose, k3s, and staged mesh routes with the same app contract | `backend-dev`, backend tests, staged smoke |
| Docker | image build and local container runtime | local app and release layers | Dockerfiles, `docker-compose.yml`, release workflow | backs local Compose, k3s image build, and GHCR release publishing | `compose-*`, `k8s-build-*`, release workflow |
| Docker Compose | simplest full local app stack | local app workflow | `docker-compose.yml`, `scripts/compose/require-compose.sh` | gives a non-Kubernetes learning path before `dev` or staging | `compose-up`, `compose-down`, `compose-logs` |
| PostgreSQL | primary relational database | backend plus platform workload layer | `docker-compose.yml`, `platform/k8s/components/in-cluster-postgres/**`, Helm workload templates | used by local dev, Compose, `dev`, and staged overlays through the same connection env contract | backend dev, Compose, backup/restore, staged deploy |
| `kubectl` | direct cluster inspection and control | cluster operations layer | `scripts/k3s/**`, `scripts/gitops/**` | the underlying CLI most cluster helpers ultimately call | almost every `k8s-*` and staged `gitops-*` command |
| k3s | local Kubernetes environment | local platform workflow | `scripts/k3s/**`, `platform/k8s/**` | hosts both `dev` and `staging-local`, but with different operational models | `k8s-*`, local staged deploy |
| Helm | reusable workload and infra chart packaging | platform packaging layer | `platform/helm/**`, `scripts/gitops/render-platform-infra.sh` | provides stable reusable bases, especially for staged platform add-ons | staged render, validation, deployment |
| Kustomize | environment overlays and composition | workload env layer | `platform/k8s/**` | assembles workload components, image overrides, mesh components, and monitoring components per environment | `gitops-render-*`, `k8s-validate-overlays`, staged deploy |
| KSOPS | Kustomize plugin for SOPS decryption | secure overlay render layer | `.gitops-local/xdg/kustomize/plugin/.../ksops`, `scripts/gitops/bootstrap/install-tools.sh` | lets Kustomize and Argo CD build encrypted overlays instead of keeping plain secrets in Git | render, validation, staged deploy |
| SOPS | encrypted secret storage in Git | secure overlay layer | encrypted files under `platform/k8s/overlays/**/secrets/*.enc.yaml`, `.sops.yaml` | keeps GitOps-compatible secrets while still allowing local and cluster-side render | bootstrap, render, validation, promotion |
| age | key format used by SOPS | secure bootstrap layer | local `.gitops-local/age/keys.txt`, bootstrap scripts | provides the private key material Argo CD and local render need for SOPS files | age-key install, promotion validation |
| Argo CD | GitOps controller | staging deployment layer | `platform/argocd/apps/**`, `scripts/gitops/bootstrap/*.sh`, `scripts/gitops/wait-app.sh` | turns Git state into staged cluster state and enforces the app/infra split | bootstrap, apply, wait, deploy staging |
| GitOps | operating model with Git as desired state | staging operating model | Argo CD app manifests plus overlay/chart sources | explains why manual cluster edits are temporary and promotion happens through Git changes | staged deploy, promotion, troubleshooting |
| Kyverno | policy-as-code validator | platform policy layer | `platform/policy/kyverno/common/**`, `platform/policy/kyverno/staging/**` | validates combined workload and infra renders before rollout | `k8s-validate-overlays`, `policy-check`, `ci` |
| Istio | staged mesh and ingress platform add-on | platform infra layer | `platform/helm/istio/**`, `platform/k8s/components/mesh/istio/**` | owns staged ingress and sidecars while workload overlays still own app-specific mesh resources | staged render, validation, deploy, smoke |
| Prometheus | staged monitoring platform add-on | split between platform infra and workload observability | `platform/helm/prometheus/**`, `platform/k8s/components/observability/prometheus/**` | infra owns Prometheus itself; workload layer owns whether `inventory-service` is scraped | staged render, validation, status, smoke |
| `ServiceMonitor` | workload scrape declaration for Prometheus | workload observability layer | `platform/k8s/components/observability/prometheus/inventory-service-monitor.yaml` | bridges workload metrics exposure to the shared Prometheus stack | staged validation, monitoring checks |
| `istioctl` | mesh analyzer and operator CLI | local GitOps helper layer | `scripts/gitops/bootstrap/install-tools.sh`, `scripts/gitops/validate-overlays.sh` | provides static analysis on combined staged manifests before rollout | `k8s-validate-overlays` |
| kubeconform | Kubernetes schema validation | platform validation layer | `scripts/gitops/validate-overlays.sh` | catches schema-level manifest problems after render but before sync | `k8s-validate-overlays` |
| Trivy | container vulnerability scanner | release security layer | `.github/workflows/release-images.yml` | scans what was actually published, not just source inputs | release workflow |
| Syft | SBOM generator | release supply-chain layer | `.github/workflows/release-images.yml` | documents image contents for later trust and audit workflows | release workflow |
| Cosign | image signing and verification | release and promotion trust layer | `.github/workflows/release-images.yml`, `scripts/release/verify-trusted-images.sh` | signs release images and later proves canonical staging only trusts those images | release workflow, promotion, canonical staging deploy |
| GitHub Actions | CI, release, and promotion automation | `.github/workflows/` | workflow YAML files under `.github/workflows/` | mirrors local commands where practical and adds hosted automation for release and PR flows | CI, security, release, promotion |

## Read next

- [Tooling primer](../getting-started/tooling-primer.md)
- [Command reference](commands.md)
- [Configuration and environment variables](configuration.md)
