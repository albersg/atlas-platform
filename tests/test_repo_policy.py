from __future__ import annotations

import re
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
            "platform/argocd/apps/atlas-platform-staging.yaml",
            "platform/k8s/overlays/staging/kustomization.yaml",
            "scripts/gitops/bootstrap/apply-staging-app.sh",
            "scripts/gitops/validate-overlays.sh",
            "scripts/gitops/deploy/staging.sh",
            "scripts/gitops/wait-app.sh",
            "scripts/k3s/verify/smoke.sh",
            "scripts/release/promote-by-digest.sh",
        ]
        for path in required:
            self.assertTrue((ROOT / path).exists(), f"Missing required file: {path}")

    def test_mise_has_pinned_core_tools(self) -> None:
        mise_data = tomllib.loads((ROOT / "mise.toml").read_text(encoding="utf-8"))
        tools = mise_data.get("tools", {})
        for tool in ["python", "node", "uv", "ruff", "pre-commit", "actionlint"]:
            self.assertIn(tool, tools)
            self.assertRegex(str(tools[tool]), r"\d+\.\d+\.\d+")

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
        for environment in ("dev", "staging"):
            overlay = ROOT / "platform" / "k8s" / "overlays" / environment / "kustomization.yaml"
            self.assertTrue(overlay.exists(), f"Missing overlay for environment: {environment}")

    def test_image_components_exist(self) -> None:
        for environment in ("dev", "staging"):
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


if __name__ == "__main__":
    unittest.main()
