from __future__ import annotations

import json
import os
import re
import subprocess
import tempfile
import tomllib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


class RepoPolicyTests(unittest.TestCase):
    def test_required_files_exist(self) -> None:
        required = [
            ".github/workflows/ci.yml",
            ".github/workflows/security.yml",
            ".github/workflows/codeql.yml",
            ".github/workflows/dependency-review.yml",
            ".github/workflows/pre-commit-autoupdate.yml",
            ".github/workflows/release-images.yml",
            ".github/workflows/promote-staging.yml",
            ".github/dependabot.yml",
            ".github/CODEOWNERS",
            ".pre-commit-config.yaml",
            "mise.toml",
            "mkdocs.yml",
            "pyrightconfig.json",
            "AGENTS.md",
            "README.md",
            "docs/deployment/releases/IMAGE_PROMOTION.md",
            "platform/argocd/core/upstream/install-v2.13.3.yaml",
            "platform/argocd/apps/project-atlas-platform-infra.yaml",
            "platform/argocd/apps/atlas-platform-istio-base.yaml",
            "platform/argocd/apps/atlas-platform-istiod.yaml",
            "platform/argocd/apps/atlas-platform-istio-ingress.yaml",
            "platform/argocd/apps/atlas-platform-staging.yaml",
            "platform/helm/istio/base/Chart.yaml",
            "platform/helm/istio/istiod/Chart.yaml",
            "platform/helm/istio/gateway/Chart.yaml",
            "platform/policy/kyverno/common/block-dev-istio-resources.yaml",
            "platform/policy/kyverno/common/require-istio-infra-core-resources.yaml",
            "platform/policy/kyverno/common/require-staging-mesh-onboarding.yaml",
            "platform/policy/kyverno/staging/require-canonical-staging-mesh-routing.yaml",
            "platform/k8s/components/ingress/traefik/kustomization.yaml",
            "platform/k8s/components/ingress/traefik/ingress.yaml",
            "platform/k8s/components/mesh/istio/kustomization.yaml",
            "platform/k8s/components/mesh/istio/gateway.yaml",
            "platform/k8s/components/mesh/istio/virtualservice.yaml",
            "platform/k8s/components/mesh/istio/destinationrule.yaml",
            "platform/k8s/components/mesh/istio/peerauthentication.yaml",
            "platform/k8s/components/mesh/istio/authorizationpolicy.yaml",
            "platform/k8s/components/images/staging-local/kustomization.yaml",
            "platform/k8s/overlays/staging/kustomization.yaml",
            "scripts/gitops/bootstrap/apply-staging-app.sh",
            "scripts/gitops/render-platform-infra.sh",
            "scripts/gitops/delete-staging.sh",
            "scripts/gitops/validate-overlays.sh",
            "scripts/gitops/deploy/staging.sh",
            "scripts/gitops/wait-app.sh",
            "scripts/compose/require-compose.sh",
            "scripts/k3s/cluster/doctor.sh",
            "scripts/k3s/postgres/lib.sh",
            "scripts/k3s/postgres/backup.sh",
            "scripts/k3s/postgres/restore.sh",
            "scripts/k3s/verify/smoke.sh",
            "scripts/release/promote-by-digest.sh",
            "scripts/release/verify-trusted-images.sh",
            "platform/k8s/components/in-cluster-postgres/workloads/postgres-backup-job.yaml",
            "platform/k8s/components/in-cluster-postgres/workloads/postgres-restore-job.yaml",
            "platform/k8s/components/in-cluster-postgres/networkpolicy-postgres-admin-egress.yaml",
        ]
        for path in required:
            self.assertTrue((ROOT / path).exists(), f"Missing required file: {path}")

    def test_mise_has_pinned_core_tools(self) -> None:
        mise_data = tomllib.loads((ROOT / "mise.toml").read_text(encoding="utf-8"))
        tools = mise_data.get("tools", {})
        for tool in ["python", "node", "uv", "ruff", "pre-commit", "actionlint", "kubectl"]:
            self.assertIn(tool, tools)
            self.assertRegex(str(tools[tool]), r"\d+\.\d+\.\d+")

    def test_mise_keeps_gitops_helpers_out_of_duplicate_tool_pins(self) -> None:
        mise_contents = (ROOT / "mise.toml").read_text(encoding="utf-8")
        install_tools = (ROOT / "scripts" / "gitops" / "bootstrap" / "install-tools.sh").read_text(
            encoding="utf-8"
        )

        self.assertIn("Keep repo-scoped GitOps helpers", mise_contents)
        self.assertIn('HELM_VERSION="v3.16.4"', install_tools)
        self.assertIn('ISTIOCTL_VERSION="1.25.3"', install_tools)
        self.assertIn('KYVERNO_VERSION="v1.15.0"', install_tools)

        mise_tools = tomllib.loads(mise_contents).get("tools", {})
        for tool in ["helm", "istioctl", "kyverno"]:
            self.assertNotIn(tool, mise_tools)

    def test_mise_has_canonical_tasks(self) -> None:
        mise_data = tomllib.loads((ROOT / "mise.toml").read_text(encoding="utf-8"))
        tasks = mise_data.get("tasks", {})
        for task in (
            "bootstrap",
            "fmt",
            "lint",
            "typecheck",
            "test",
            "check",
            "fix",
            "ci",
            "docs-build",
        ):
            self.assertIn(task, tasks, f"Missing canonical mise task: {task}")

    def test_mise_has_nonprod_delivery_tasks(self) -> None:
        mise_data = tomllib.loads((ROOT / "mise.toml").read_text(encoding="utf-8"))
        tasks = mise_data.get("tasks", {})
        for task in (
            "k8s-deploy-dev",
            "k8s-smoke",
            "k8s-smoke-staging",
            "gitops-apply-staging",
            "gitops-deploy-staging",
            "gitops-wait-staging",
            "gitops-render-dev",
            "gitops-render-staging",
            "gitops-render-platform-infra-staging-local",
            "gitops-render-platform-infra-staging",
            "k8s-doctor",
            "k8s-backup-postgres-staging",
            "k8s-restore-postgres-staging",
            "k8s-validate-overlays",
        ):
            self.assertIn(task, tasks, f"Missing non-production task: {task}")

    def test_no_prod_operational_surface_remains(self) -> None:
        for path in (
            ".github/workflows/promote-prod.yml",
            "platform/argocd/prod",
            "platform/k8s/components/images/prod",
            "platform/k8s/overlays/prod",
            "scripts/gitops/bootstrap/apply-prod-apps.sh",
        ):
            self.assertFalse((ROOT / path).exists(), f"Unexpected prod artifact remains: {path}")

    def test_pre_commit_has_required_hooks(self) -> None:
        contents = (ROOT / ".pre-commit-config.yaml").read_text(encoding="utf-8")
        hook_ids = set(re.findall(r"^\s*-\s+id:\s+([A-Za-z0-9_-]+)\s*$", contents, re.MULTILINE))
        for hook in (
            "check-json",
            "check-yaml",
            "detect-private-key",
            "detect-secrets",
            "gitleaks",
            "check-github-workflows",
            "actionlint",
            "ruff-check",
            "pyright",
            "shellcheck",
            "no-commit-to-branch",
        ):
            self.assertIn(hook, hook_ids, f"Missing required hook: {hook}")

    def test_workflows_pin_actions_by_sha(self) -> None:
        workflows = (ROOT / ".github" / "workflows").glob("*.yml")
        for workflow in workflows:
            contents = workflow.read_text(encoding="utf-8")
            for uses in re.findall(r"^\s*uses:\s*([^\s]+)\s*$", contents, re.MULTILINE):
                self.assertIn("@", uses)
                ref = uses.rsplit("@", 1)[1]
                self.assertRegex(
                    ref,
                    r"^[a-f0-9]{40}$",
                    f"Workflow action is not SHA pinned: {uses} in {workflow}",
                )

    def test_no_latest_tags_in_kubernetes_manifests(self) -> None:
        manifests = (ROOT / "platform").glob("**/*.yaml")
        offenders: list[str] = []
        for manifest in manifests:
            contents = manifest.read_text(encoding="utf-8")
            if ":latest" in contents:
                offenders.append(str(manifest.relative_to(ROOT)))

        self.assertEqual(offenders, [], f"Found mutable latest tags in manifests: {offenders}")

    def test_environment_overlays_exist(self) -> None:
        for environment in ("dev", "staging", "staging-local"):
            overlay = ROOT / "platform" / "k8s" / "overlays" / environment / "kustomization.yaml"
            self.assertTrue(overlay.exists(), f"Missing overlay for environment: {environment}")

    def test_image_components_exist(self) -> None:
        for environment in ("dev", "staging", "staging-local"):
            component = (
                ROOT
                / "platform"
                / "k8s"
                / "components"
                / "images"
                / environment
                / "kustomization.yaml"
            )
            self.assertTrue(
                component.exists(), f"Missing image component for environment: {environment}"
            )

    def test_staging_images_use_registry_references(self) -> None:
        contents = (
            ROOT / "platform" / "k8s" / "components" / "images" / "staging" / "kustomization.yaml"
        ).read_text(encoding="utf-8")
        self.assertIn("ghcr.io/albersg/atlas-inventory-service", contents)
        self.assertIn("ghcr.io/albersg/atlas-web", contents)
        self.assertNotIn("newName: atlas-inventory-service", contents)
        self.assertNotIn("newName: atlas-web", contents)

    def test_canonical_staging_uses_digests_only(self) -> None:
        contents = (
            ROOT / "platform" / "k8s" / "components" / "images" / "staging" / "kustomization.yaml"
        ).read_text(encoding="utf-8")
        self.assertNotIn("newTag:", contents)
        self.assertEqual(contents.count("digest: sha256:"), 2)

    def test_canonical_staging_rejects_placeholder_digests_in_repo(self) -> None:
        contents = (
            ROOT / "platform" / "k8s" / "components" / "images" / "staging" / "kustomization.yaml"
        ).read_text(encoding="utf-8")
        self.assertNotIn(
            "sha256:0000000000000000000000000000000000000000000000000000000000000000",
            contents,
        )
        self.assertNotIn(
            "sha256:1111111111111111111111111111111111111111111111111111111111111111",
            contents,
        )

    def test_staging_local_is_the_only_mutable_staging_exception(self) -> None:
        staging_local = (
            ROOT
            / "platform"
            / "k8s"
            / "components"
            / "images"
            / "staging-local"
            / "kustomization.yaml"
        ).read_text(encoding="utf-8")
        self.assertIn("newTag: main", staging_local)

        mutable_tag_files: list[str] = []
        for manifest in (ROOT / "platform").glob("**/*.yaml"):
            rel_path = manifest.relative_to(ROOT)
            if rel_path == Path("platform/k8s/components/images/staging-local/kustomization.yaml"):
                continue
            contents = manifest.read_text(encoding="utf-8")
            if "newTag: main" in contents and "staging" in rel_path.parts:
                mutable_tag_files.append(str(rel_path))

        self.assertEqual(
            mutable_tag_files,
            [],
            f"Mutable staging tags are only allowed in staging-local: {mutable_tag_files}",
        )

    def test_staging_local_overlay_uses_dedicated_image_component(self) -> None:
        contents = (
            ROOT / "platform" / "k8s" / "overlays" / "staging-local" / "kustomization.yaml"
        ).read_text(encoding="utf-8")
        self.assertIn("../../components/images/staging-local", contents)
        self.assertNotIn("../../components/images/staging\n", contents)

    def test_overlay_validation_uses_layered_policy_bundles(self) -> None:
        contents = (ROOT / "scripts" / "gitops" / "validate-overlays.sh").read_text(
            encoding="utf-8"
        )
        self.assertIn('COMMON_POLICY_BUNDLE="platform/policy/kyverno/common"', contents)
        self.assertIn('STAGING_POLICY_BUNDLE="platform/policy/kyverno/staging"', contents)
        self.assertIn('ISTIOCTL_BIN="$TOOLS_DIR/istioctl"', contents)
        self.assertIn("render_platform_infra staging", contents)
        self.assertIn("render_platform_infra staging-local", contents)
        self.assertIn("combine_surface staging", contents)
        self.assertIn("combine_surface staging-local", contents)
        self.assertIn(
            'apply_policy_bundle "$COMMON_POLICY_BUNDLE" staging-local-policy-target common',
            contents,
        )
        self.assertIn(
            'apply_policy_bundle "$STAGING_POLICY_BUNDLE" staging-policy-target staging-only',
            contents,
        )
        self.assertIn('"$ISTIOCTL_BIN" analyze --use-kube=false', contents)

    def test_mesh_policy_bundles_cover_dev_guardrails_and_staging_contract(self) -> None:
        common_kustomization = (
            ROOT / "platform" / "policy" / "kyverno" / "common" / "kustomization.yaml"
        ).read_text(encoding="utf-8")
        staging_kustomization = (
            ROOT / "platform" / "policy" / "kyverno" / "staging" / "kustomization.yaml"
        ).read_text(encoding="utf-8")
        dev_guardrail = (
            ROOT / "platform" / "policy" / "kyverno" / "common" / "block-dev-istio-resources.yaml"
        ).read_text(encoding="utf-8")
        staging_mesh = (
            ROOT
            / "platform"
            / "policy"
            / "kyverno"
            / "common"
            / "require-staging-mesh-onboarding.yaml"
        ).read_text(encoding="utf-8")
        infra_core = (
            ROOT
            / "platform"
            / "policy"
            / "kyverno"
            / "common"
            / "require-istio-infra-core-resources.yaml"
        ).read_text(encoding="utf-8")
        canonical_mesh = (
            ROOT
            / "platform"
            / "policy"
            / "kyverno"
            / "staging"
            / "require-canonical-staging-mesh-routing.yaml"
        ).read_text(encoding="utf-8")

        self.assertIn("block-dev-istio-resources.yaml", common_kustomization)
        self.assertIn("require-istio-infra-core-resources.yaml", common_kustomization)
        self.assertIn("require-staging-mesh-onboarding.yaml", common_kustomization)
        self.assertIn("require-canonical-staging-mesh-routing.yaml", staging_kustomization)
        self.assertIn("atlas-platform-dev", dev_guardrail)
        self.assertIn("Gateway", dev_guardrail)
        self.assertIn('sidecar.istio.io/inject: "true"', staging_mesh)
        self.assertIn("atlas-platform-gateway", staging_mesh)
        self.assertIn("atlas-platform-istio-ingress", infra_core)
        self.assertIn("api.staging.atlas.example.com", canonical_mesh)
        self.assertIn("atlas-api", canonical_mesh)

    def test_environment_ingress_and_mesh_components_stay_split(self) -> None:
        dev_overlay = (
            ROOT / "platform" / "k8s" / "overlays" / "dev" / "kustomization.yaml"
        ).read_text(encoding="utf-8")
        staging_overlay = (
            ROOT / "platform" / "k8s" / "overlays" / "staging" / "kustomization.yaml"
        ).read_text(encoding="utf-8")
        staging_local_overlay = (
            ROOT / "platform" / "k8s" / "overlays" / "staging-local" / "kustomization.yaml"
        ).read_text(encoding="utf-8")
        base_kustomization = (ROOT / "platform" / "k8s" / "base" / "kustomization.yaml").read_text(
            encoding="utf-8"
        )
        traefik_component = (
            ROOT / "platform" / "k8s" / "components" / "ingress" / "traefik" / "kustomization.yaml"
        ).read_text(encoding="utf-8")
        mesh_component = (
            ROOT / "platform" / "k8s" / "components" / "mesh" / "istio" / "kustomization.yaml"
        ).read_text(encoding="utf-8")

        self.assertNotIn("networking/ingress.yaml", base_kustomization)
        self.assertIn("../../components/ingress/traefik", dev_overlay)
        self.assertNotIn("../../components/mesh/istio", dev_overlay)
        self.assertIn("../../components/mesh/istio", staging_overlay)
        self.assertIn("../../components/mesh/istio", staging_local_overlay)
        self.assertIn("resources:\n  - ingress.yaml", traefik_component)
        self.assertIn("resources:\n  - gateway.yaml", mesh_component)

    def test_mesh_component_targets_only_first_wave_workloads(self) -> None:
        mesh_component = (
            ROOT / "platform" / "k8s" / "components" / "mesh" / "istio" / "kustomization.yaml"
        ).read_text(encoding="utf-8")
        control_plane_policy = (
            ROOT
            / "platform"
            / "k8s"
            / "components"
            / "mesh"
            / "istio"
            / "networkpolicy-mesh-control-plane-egress.yaml"
        ).read_text(encoding="utf-8")
        migration_patch = (
            ROOT
            / "platform"
            / "k8s"
            / "components"
            / "mesh"
            / "istio"
            / "patches"
            / "inventory-migration-sidecar-injection.yaml"
        ).read_text(encoding="utf-8")
        web_patch = (
            ROOT
            / "platform"
            / "k8s"
            / "components"
            / "mesh"
            / "istio"
            / "patches"
            / "web-sidecar-injection.yaml"
        ).read_text(encoding="utf-8")
        inventory_patch = (
            ROOT
            / "platform"
            / "k8s"
            / "components"
            / "mesh"
            / "istio"
            / "patches"
            / "inventory-service-sidecar-injection.yaml"
        ).read_text(encoding="utf-8")
        migrate_script = (
            ROOT / "services" / "inventory-service" / "scripts" / "migrate.sh"
        ).read_text(encoding="utf-8")

        self.assertIn("web-sidecar-injection.yaml", mesh_component)
        self.assertIn("inventory-service-sidecar-injection.yaml", mesh_component)
        self.assertIn("inventory-migration-sidecar-injection.yaml", mesh_component)
        self.assertIn("inventory-migration", control_plane_policy)
        self.assertNotIn("postgres", control_plane_policy)
        self.assertIn("istio.io/rev: default", web_patch)
        self.assertIn("sidecar.istio.io/proxyCPU: 100m", web_patch)
        self.assertIn("sidecar.istio.io/proxyMemoryLimit: 256Mi", web_patch)
        self.assertIn("istio.io/rev: default", inventory_patch)
        self.assertIn("sidecar.istio.io/proxyCPULimit: 300m", inventory_patch)
        self.assertIn('sidecar.istio.io/inject: "true"', migration_patch)
        self.assertIn("istio.io/rev: default", migration_patch)
        self.assertIn("ISTIO_QUIT_SIDECAR_ON_EXIT", migration_patch)
        self.assertIn("ISTIO_QUIT_SIDECAR_ON_EXIT", migrate_script)
        self.assertIn("quitquitquit", migrate_script)

    def test_staging_mesh_resources_use_mesh_native_http_entrypoint(self) -> None:
        gateway = (
            ROOT / "platform" / "k8s" / "components" / "mesh" / "istio" / "gateway.yaml"
        ).read_text(encoding="utf-8")
        staging_local_gateway_values = (
            ROOT / "platform" / "helm" / "istio" / "gateway" / "values-staging-local.yaml"
        ).read_text(encoding="utf-8")
        virtual_service = (
            ROOT / "platform" / "k8s" / "components" / "mesh" / "istio" / "virtualservice.yaml"
        ).read_text(encoding="utf-8")
        smoke_script = (ROOT / "scripts" / "k3s" / "verify" / "smoke.sh").read_text(
            encoding="utf-8"
        )
        access_script = (ROOT / "scripts" / "k3s" / "cluster" / "access.sh").read_text(
            encoding="utf-8"
        )

        self.assertIn("istio: atlas-platform-istio-ingress", gateway)
        self.assertIn("number: 80", gateway)
        self.assertIn("staging.atlas.example.com", virtual_service)
        self.assertIn("api.staging.atlas.example.com", virtual_service)
        self.assertIn(
            "gateway:\n  service:\n    annotations: {}\n    type: NodePort",
            staging_local_gateway_values,
        )
        self.assertIn("nodePort: 32080", staging_local_gateway_values)
        self.assertIn("nodePort: 32443", staging_local_gateway_values)
        self.assertIn(
            'STAGING_INGRESS_SCHEME="${ATLAS_STAGING_INGRESS_SCHEME:-http}"', smoke_script
        )
        self.assertIn(
            'STAGING_LOCAL_HTTP_PORT="${ATLAS_STAGING_LOCAL_HTTP_PORT:-32080}"', smoke_script
        )
        self.assertIn("staging-local)", smoke_script)
        self.assertIn(
            'STAGING_INGRESS_SCHEME="${ATLAS_STAGING_INGRESS_SCHEME:-http}"', access_script
        )
        self.assertIn(
            'STAGING_LOCAL_HTTP_PORT="${ATLAS_STAGING_LOCAL_HTTP_PORT:-32080}"', access_script
        )
        self.assertIn("NodePort del gateway Istio", access_script)

    def test_istio_argocd_apps_ignore_webhook_mutations(self) -> None:
        base_app = (
            ROOT / "platform" / "argocd" / "apps" / "atlas-platform-istio-base.yaml"
        ).read_text(encoding="utf-8")
        istiod_app = (
            ROOT / "platform" / "argocd" / "apps" / "atlas-platform-istiod.yaml"
        ).read_text(encoding="utf-8")

        self.assertIn("RespectIgnoreDifferences=true", base_app)
        self.assertIn("name: istiod-default-validator", base_app)
        self.assertIn(".webhooks[]?.clientConfig.caBundle", base_app)
        self.assertIn(".webhooks[]?.failurePolicy", base_app)
        self.assertIn("RespectIgnoreDifferences=true", istiod_app)
        self.assertIn("name: istio-sidecar-injector", istiod_app)
        self.assertIn("name: istio-validator-istio-system", istiod_app)
        self.assertIn(".webhooks[]?.clientConfig.caBundle", istiod_app)

    def test_staging_local_keeps_local_only_mesh_admission_relaxation(self) -> None:
        staging_local_namespace = (
            ROOT / "platform" / "k8s" / "overlays" / "staging-local" / "namespace.yaml"
        ).read_text(encoding="utf-8")
        staging_namespace = (
            ROOT / "platform" / "k8s" / "overlays" / "staging" / "namespace.yaml"
        ).read_text(encoding="utf-8")

        self.assertIn("pod-security.kubernetes.io/enforce: privileged", staging_local_namespace)
        self.assertIn("pod-security.kubernetes.io/audit: baseline", staging_local_namespace)
        self.assertIn("pod-security.kubernetes.io/warn: baseline", staging_local_namespace)
        self.assertIn("pod-security.kubernetes.io/enforce: baseline", staging_namespace)
        self.assertIn("pod-security.kubernetes.io/audit: restricted", staging_namespace)
        self.assertIn("pod-security.kubernetes.io/warn: restricted", staging_namespace)

    def test_argocd_app_projects_reflect_platform_boundary(self) -> None:
        apps_kustomization = (
            ROOT / "platform" / "argocd" / "apps" / "kustomization.yaml"
        ).read_text(encoding="utf-8")
        app_project = (
            ROOT / "platform" / "argocd" / "apps" / "project-atlas-platform.yaml"
        ).read_text(encoding="utf-8")
        infra_project = (
            ROOT / "platform" / "argocd" / "apps" / "project-atlas-platform-infra.yaml"
        ).read_text(encoding="utf-8")

        self.assertIn("project-atlas-platform-infra.yaml", apps_kustomization)
        self.assertIn("atlas-platform-istio-base.yaml", apps_kustomization)
        self.assertIn("atlas-platform-istiod.yaml", apps_kustomization)
        self.assertIn("atlas-platform-istio-ingress.yaml", apps_kustomization)
        self.assertIn("kind: Gateway", app_project)
        self.assertIn("kind: VirtualService", app_project)
        self.assertIn("kind: DestinationRule", app_project)
        self.assertIn("kind: PeerAuthentication", app_project)
        self.assertIn("kind: AuthorizationPolicy", app_project)
        self.assertIn("name: atlas-platform-infra", infra_project)
        self.assertIn("namespace: istio-system", infra_project)

    def test_istio_wrapper_charts_pin_versions_and_render_tasks(self) -> None:
        base_chart = (ROOT / "platform" / "helm" / "istio" / "base" / "Chart.yaml").read_text(
            encoding="utf-8"
        )
        istiod_chart = (ROOT / "platform" / "helm" / "istio" / "istiod" / "Chart.yaml").read_text(
            encoding="utf-8"
        )
        gateway_chart = (ROOT / "platform" / "helm" / "istio" / "gateway" / "Chart.yaml").read_text(
            encoding="utf-8"
        )
        render_script = (ROOT / "scripts" / "gitops" / "render-platform-infra.sh").read_text(
            encoding="utf-8"
        )
        install_tools = (ROOT / "scripts" / "gitops" / "bootstrap" / "install-tools.sh").read_text(
            encoding="utf-8"
        )
        mise_data = tomllib.loads((ROOT / "mise.toml").read_text(encoding="utf-8"))

        self.assertIn("version: 1.25.3", base_chart)
        self.assertIn("version: 1.25.3", istiod_chart)
        self.assertIn("version: 1.25.3", gateway_chart)
        self.assertIn('ENVIRONMENT="$1"', render_script)
        self.assertIn('"$HELM_BIN" dependency build', render_script)
        self.assertIn("values-${ENVIRONMENT}.yaml", render_script)
        self.assertIn('HELM_VERSION="v3.16.4"', install_tools)
        self.assertIn('ISTIOCTL_VERSION="1.25.3"', install_tools)
        self.assertEqual(
            mise_data["tasks"]["gitops-render-platform-infra-staging-local"]["run"],
            "./scripts/gitops/render-platform-infra.sh staging-local",
        )
        self.assertEqual(
            mise_data["tasks"]["gitops-render-platform-infra-staging"]["run"],
            "./scripts/gitops/render-platform-infra.sh staging",
        )

    def test_staging_delete_requires_explicit_confirmation(self) -> None:
        contents = (ROOT / "scripts" / "gitops" / "delete-staging.sh").read_text(encoding="utf-8")
        self.assertIn("ATLAS_CONFIRM_STAGING_DELETE", contents)
        self.assertIn("PRESERVE_POSTGRES_PVC", contents)
        self.assertIn("ATLAS_RENDER_OVERLAY_SCRIPT", contents)
        self.assertIn("--cascade=orphan --wait=true", contents)
        self.assertIn("filtrar Namespace/PersistentVolumeClaim", contents)

    def test_staging_delete_preserves_namespace_by_default(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            kubectl_path = Path(temp_dir) / "kubectl"
            kubectl_path.write_text(
                "#!/usr/bin/env bash\n"
                "set -eu\n"
                "printf 'kubectl %s\\n' \"$*\" >&2\n"
                'if [ "${1:-}" = "-n" ] && [ "${3:-}" = "get" ] '
                '&& [ "${4:-}" = "application" ]; then\n'
                "  exit 0\n"
                "fi\n"
                "exit 0\n",
                encoding="utf-8",
            )
            kubectl_path.chmod(0o755)

            result = subprocess.run(
                ["bash", "scripts/gitops/delete-staging.sh"],
                cwd=ROOT,
                env={
                    **os.environ,
                    "PATH": f"{temp_dir}:/usr/bin:/bin",
                    "ATLAS_CONFIRM_STAGING_DELETE": "atlas-platform-staging",
                    "ATLAS_STAGING_DELETE_DRY_RUN": "1",
                },
                capture_output=True,
                text=True,
            )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("--cascade=orphan --wait=true", result.stdout)
        self.assertIn("filtrar Namespace/PersistentVolumeClaim", result.stdout)
        self.assertNotIn("delete namespace", result.stdout)

    def test_staging_delete_filters_namespace_and_pvc_from_live_manifest_by_default(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            render_path = Path(temp_dir) / "render-overlay.sh"
            render_path.write_text(
                "#!/usr/bin/env bash\n"
                "cat <<'EOF'\n"
                "apiVersion: v1\n"
                "kind: Namespace\n"
                "metadata:\n"
                "  name: atlas-platform-staging\n"
                "---\n"
                "apiVersion: v1\n"
                "kind: PersistentVolumeClaim\n"
                "metadata:\n"
                "  name: postgres-data\n"
                "  namespace: atlas-platform-staging\n"
                "---\n"
                "apiVersion: v1\n"
                "kind: Service\n"
                "metadata:\n"
                "  name: postgres\n"
                "  namespace: atlas-platform-staging\n"
                "EOF\n",
                encoding="utf-8",
            )
            render_path.chmod(0o755)

            kubectl_path = Path(temp_dir) / "kubectl"
            kubectl_path.write_text(
                "#!/usr/bin/env bash\n"
                "set -eu\n"
                'if [ "${1:-}" = "-n" ] && [ "${3:-}" = "get" ] '
                '&& [ "${4:-}" = "application" ]; then\n'
                "  exit 1\n"
                "fi\n"
                'if [ "${1:-}" = "delete" ] && [ "${2:-}" = "-f" ]; then\n'
                "  printf 'DELETE_FILE=%s\\n' \"$3\"\n"
                "  python - <<'PY' \"$3\"\n"
                "from pathlib import Path\n"
                "import sys\n"
                "print(Path(sys.argv[1]).read_text(encoding='utf-8'))\n"
                "PY\n"
                "  exit 0\n"
                "fi\n"
                "printf 'kubectl %s\\n' \"$*\"\n"
                "exit 0\n",
                encoding="utf-8",
            )
            kubectl_path.chmod(0o755)

            result = subprocess.run(
                ["bash", "scripts/gitops/delete-staging.sh"],
                cwd=ROOT,
                env={
                    **os.environ,
                    "PATH": f"{temp_dir}:{os.environ['PATH']}",
                    "ATLAS_CONFIRM_STAGING_DELETE": "atlas-platform-staging",
                    "ATLAS_RENDER_OVERLAY_SCRIPT": str(render_path),
                },
                capture_output=True,
                text=True,
            )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("kind: Service", result.stdout)
        self.assertNotIn("kind: Namespace", result.stdout)
        self.assertNotIn("kind: PersistentVolumeClaim", result.stdout)
        self.assertNotIn("delete namespace", result.stdout)

    def test_trusted_image_verification_is_wired_into_promotion_and_validation(self) -> None:
        promote = (ROOT / "scripts" / "release" / "promote-by-digest.sh").read_text(
            encoding="utf-8"
        )
        validate = (ROOT / "scripts" / "gitops" / "validate-overlays.sh").read_text(
            encoding="utf-8"
        )
        install_tools = (ROOT / "scripts" / "gitops" / "bootstrap" / "install-tools.sh").read_text(
            encoding="utf-8"
        )

        self.assertIn('"$ROOT_DIR/scripts/release/verify-trusted-images.sh"', promote)
        self.assertIn('"$ROOT_DIR/scripts/release/verify-trusted-images.sh"', validate)
        self.assertIn(
            'download "https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-amd64"',
            install_tools,
        )

    def test_trusted_image_verification_rejects_placeholder_digests_early(self) -> None:
        with tempfile.NamedTemporaryFile("w", encoding="utf-8", suffix=".yaml") as target_file:
            target_file.write(
                "apiVersion: kustomize.config.k8s.io/v1alpha1\n"
                "kind: Component\n\n"
                "images:\n"
                "  - name: ghcr.io/albersg/atlas-inventory-service\n"
                "    newName: ghcr.io/albersg/atlas-inventory-service\n"
                "    digest: sha256:000000000000000000000000000000000000000000000000"
                "0000000000000000\n"
                "  - name: ghcr.io/albersg/atlas-web\n"
                "    newName: ghcr.io/albersg/atlas-web\n"
                "    digest: sha256:111111111111111111111111111111111111111111111111"
                "1111111111111111\n"
            )
            target_file.flush()

            result = subprocess.run(
                ["bash", "scripts/release/verify-trusted-images.sh", target_file.name],
                cwd=ROOT,
                env={**os.environ, "PATH": "/usr/bin:/bin"},
                capture_output=True,
                text=True,
            )

        self.assertNotEqual(result.returncode, 0)
        combined_output = f"{result.stdout}\n{result.stderr}"
        self.assertIn("placeholder", combined_output)
        self.assertIn("release-images.yml", combined_output)

    def test_inventory_runtime_image_excludes_uv_binaries(self) -> None:
        contents = (ROOT / "services" / "inventory-service" / "Dockerfile").read_text(
            encoding="utf-8"
        )

        self.assertIn("FROM python:3.12-slim AS build", contents)
        self.assertIn("COPY --from=build /app /app", contents)

        runtime_stage = contents.rsplit("FROM python:3.12-slim", maxsplit=1)[1]
        self.assertNotIn("COPY --from=uv /uv /uvx /bin/", runtime_stage)
        self.assertNotIn("uv sync", runtime_stage)

    def test_k8s_doctor_checks_hardened_staging_readiness(self) -> None:
        contents = (ROOT / "scripts" / "k3s" / "cluster" / "doctor.sh").read_text(encoding="utf-8")
        self.assertIn("ATLAS_DOCTOR_SCOPE", contents)
        self.assertIn("ATLAS_VALIDATE_PREFLIGHT=1", contents)
        self.assertIn("argocd-repo-atlas-platform", contents)
        self.assertIn("cosign", contents)
        self.assertIn("helm", contents)
        self.assertIn("istioctl", contents)
        self.assertIn("Salud operativa staging", contents)
        self.assertIn("atlas-platform-istio-base", contents)
        self.assertIn("atlas-platform-istio-ingress", contents)
        self.assertIn("namespace istio-system presente", contents)
        self.assertIn("atlas-platform-staging", contents)

    def test_staging_deploy_waits_for_infra_before_workloads(self) -> None:
        deploy_script = (ROOT / "scripts" / "gitops" / "deploy" / "staging.sh").read_text(
            encoding="utf-8"
        )
        apply_apps = (ROOT / "scripts" / "gitops" / "bootstrap" / "apply-apps.sh").read_text(
            encoding="utf-8"
        )
        status_script = (ROOT / "scripts" / "k3s" / "cluster" / "status.sh").read_text(
            encoding="utf-8"
        )
        smoke_script = (ROOT / "scripts" / "k3s" / "verify" / "smoke.sh").read_text(
            encoding="utf-8"
        )

        self.assertIn(
            'ARGOCD_WAIT_TIMEOUT_SECONDS="${ARGOCD_WAIT_TIMEOUT_SECONDS:-600}"', deploy_script
        )
        self.assertIn('"$ROOT_DIR/scripts/gitops/bootstrap/apply-apps.sh"', deploy_script)
        self.assertIn(
            '"$ROOT_DIR/scripts/gitops/wait-app.sh" atlas-platform-istio-base', deploy_script
        )
        self.assertIn('"$ROOT_DIR/scripts/gitops/wait-app.sh" atlas-platform-istiod', deploy_script)
        self.assertIn(
            '"$ROOT_DIR/scripts/gitops/wait-app.sh" atlas-platform-istio-ingress', deploy_script
        )
        self.assertIn("ensure_gateway_ready_for_mesh_smoke", deploy_script)
        self.assertIn(
            '"$ROOT_DIR/scripts/k3s/cluster/status.sh" atlas-platform-staging', deploy_script
        )
        self.assertIn(
            '"$ROOT_DIR/scripts/k3s/verify/smoke.sh" "$ARGOCD_ENVIRONMENT"', deploy_script
        )
        self.assertIn('ARGOCD_ENVIRONMENT="${ARGOCD_ENVIRONMENT:-}"', apply_apps)
        self.assertIn('f"        - values-{environment}.yaml"', apply_apps)
        self.assertIn(
            (
                "atlas-platform-istio-base atlas-platform-istiod "
                "atlas-platform-istio-ingress atlas-platform-staging"
            ),
            apply_apps,
        )
        self.assertIn("== Mesh Runtime ==", status_script)
        self.assertIn("== Argo CD Applications ==", status_script)
        self.assertIn("wait_for_sidecar_ready", smoke_script)
        self.assertIn("require_sidecar_injection", smoke_script)
        self.assertIn("deployment/atlas-platform-istio-ingress", smoke_script)

    def test_doctor_and_compose_tasks_preflight_docker_compose(self) -> None:
        mise_data = tomllib.loads((ROOT / "mise.toml").read_text(encoding="utf-8"))
        doctor_task = mise_data["tasks"]["doctor"]
        self.assertNotIn("./scripts/compose/require-compose.sh --quiet", doctor_task["run"])
        doctor_script = (ROOT / "scripts" / "k3s" / "cluster" / "doctor.sh").read_text(
            encoding="utf-8"
        )
        self.assertIn("check_docker_compose", doctor_script)
        self.assertIn("docker compose version", doctor_script)
        self.assertEqual(
            mise_data["tasks"]["compose-up"]["run"],
            "./scripts/compose/require-compose.sh up --build -d",
        )
        self.assertEqual(
            mise_data["tasks"]["compose-down"]["run"],
            "./scripts/compose/require-compose.sh down",
        )
        self.assertEqual(
            mise_data["tasks"]["compose-logs"]["run"],
            "./scripts/compose/require-compose.sh logs -f --tail=200",
        )

    def test_frontend_quality_gates_are_included_in_mise_validation(self) -> None:
        mise_data = tomllib.loads((ROOT / "mise.toml").read_text(encoding="utf-8"))
        self.assertEqual(
            mise_data["tasks"]["frontend-typecheck"]["run"],
            "cd apps/web && npm run typecheck",
        )
        self.assertIn("mise run frontend-typecheck", mise_data["tasks"]["typecheck"]["run"])
        self.assertIn("mise run frontend-build", mise_data["tasks"]["check"]["run"])

        package_data = json.loads(
            (ROOT / "apps" / "web" / "package.json").read_text(encoding="utf-8")
        )
        self.assertEqual(package_data["scripts"]["typecheck"], "tsc --noEmit")

    def test_postgres_backup_restore_tasks_are_wired(self) -> None:
        mise_data = tomllib.loads((ROOT / "mise.toml").read_text(encoding="utf-8"))
        backup_task = mise_data["tasks"]["k8s-backup-postgres-staging"]
        restore_task = mise_data["tasks"]["k8s-restore-postgres-staging"]
        self.assertEqual(
            backup_task["run"], "ATLAS_POSTGRES_ENV=staging ./scripts/k3s/postgres/backup.sh"
        )
        self.assertEqual(
            restore_task["run"],
            "ATLAS_POSTGRES_ENV=staging ./scripts/k3s/postgres/restore.sh",
        )

    def test_postgres_jobs_match_networkpolicy_access_label(self) -> None:
        networkpolicy = (
            ROOT
            / "platform"
            / "k8s"
            / "components"
            / "in-cluster-postgres"
            / "networkpolicy-postgres.yaml"
        ).read_text(encoding="utf-8")
        egress_policy = (
            ROOT
            / "platform"
            / "k8s"
            / "components"
            / "in-cluster-postgres"
            / "networkpolicy-postgres-admin-egress.yaml"
        ).read_text(encoding="utf-8")
        backup_job = (
            ROOT
            / "platform"
            / "k8s"
            / "components"
            / "in-cluster-postgres"
            / "workloads"
            / "postgres-backup-job.yaml"
        ).read_text(encoding="utf-8")
        restore_job = (
            ROOT
            / "platform"
            / "k8s"
            / "components"
            / "in-cluster-postgres"
            / "workloads"
            / "postgres-restore-job.yaml"
        ).read_text(encoding="utf-8")

        self.assertIn('atlas-postgres-access: "true"', networkpolicy)
        self.assertIn('atlas-postgres-access: "true"', egress_policy)
        self.assertIn("app: postgres", egress_policy)
        self.assertIn('atlas-postgres-access: "true"', backup_job)
        self.assertIn('atlas-postgres-access: "true"', restore_job)
        self.assertIn('atlas-postgres-access: "true"', networkpolicy)

    def test_postgres_backup_requires_a_writable_workspace(self) -> None:
        with tempfile.NamedTemporaryFile() as blocked:
            result = subprocess.run(
                ["bash", "scripts/k3s/postgres/backup.sh"],
                cwd=ROOT,
                env={
                    **os.environ,
                    "PATH": "/usr/bin:/bin",
                    "ATLAS_POSTGRES_ENV": "staging",
                    "ATLAS_POSTGRES_BACKUP_ROOT": blocked.name,
                },
                capture_output=True,
                text=True,
            )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("backup", f"{result.stdout}\n{result.stderr}".lower())

    def test_postgres_restore_requires_confirmation(self) -> None:
        with tempfile.NamedTemporaryFile() as backup_file:
            result = subprocess.run(
                ["bash", "scripts/k3s/postgres/restore.sh"],
                cwd=ROOT,
                env={
                    **os.environ,
                    "PATH": "/usr/bin:/bin",
                    "ATLAS_POSTGRES_ENV": "staging",
                    "BACKUP_FILE": backup_file.name,
                },
                capture_output=True,
                text=True,
            )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("ATLAS_CONFIRM_POSTGRES_RESTORE", f"{result.stdout}\n{result.stderr}")

    def test_postgres_restore_requires_existing_backup(self) -> None:
        result = subprocess.run(
            ["bash", "scripts/k3s/postgres/restore.sh"],
            cwd=ROOT,
            env={
                **os.environ,
                "PATH": "/usr/bin:/bin",
                "ATLAS_POSTGRES_ENV": "staging",
                "ATLAS_CONFIRM_POSTGRES_RESTORE": "atlas-platform-staging",
                "BACKUP_FILE": str(ROOT / "missing-backup.dump"),
            },
            capture_output=True,
            text=True,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("BACKUP_FILE", f"{result.stdout}\n{result.stderr}")

    def test_k8s_doctor_is_wired_into_mise(self) -> None:
        mise_data = tomllib.loads((ROOT / "mise.toml").read_text(encoding="utf-8"))
        doctor_task = mise_data["tasks"]["doctor"]
        k8s_doctor_task = mise_data["tasks"]["k8s-doctor"]
        self.assertIn("./scripts/k3s/cluster/doctor.sh", doctor_task["run"])
        self.assertEqual(k8s_doctor_task["run"], "./scripts/k3s/cluster/doctor.sh")


if __name__ == "__main__":
    unittest.main()
