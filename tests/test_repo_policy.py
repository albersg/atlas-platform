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
            ".github/dependabot.yml",
            ".github/CODEOWNERS",
            ".pre-commit-config.yaml",
            "mise.toml",
            "mkdocs.yml",
            "pyrightconfig.json",
            "AGENTS.md",
            "README.md",
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

    def test_pre_commit_has_required_hooks(self) -> None:
        contents = (ROOT / ".pre-commit-config.yaml").read_text(encoding="utf-8")
        hook_ids = set(re.findall(r"^\s*-\s+id:\s+([A-Za-z0-9_-]+)\s*$", contents, re.MULTILINE))
        for hook in (
            "check-json",
            "check-yaml",
            "detect-private-key",
            "detect-secrets",
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


if __name__ == "__main__":
    unittest.main()
