from __future__ import annotations

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
            "platform/argocd/apps/atlas-platform-staging.yaml",
            "platform/k8s/components/images/staging-local/kustomization.yaml",
            "platform/k8s/overlays/staging/kustomization.yaml",
            "scripts/gitops/bootstrap/apply-staging-app.sh",
            "scripts/gitops/delete-staging.sh",
            "scripts/gitops/validate-overlays.sh",
            "scripts/gitops/deploy/staging.sh",
            "scripts/gitops/wait-app.sh",
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
        self.assertIn('apply_policy_bundle "$COMMON_POLICY_BUNDLE" staging-local common', contents)
        self.assertIn('apply_policy_bundle "$STAGING_POLICY_BUNDLE" staging staging-only', contents)

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
