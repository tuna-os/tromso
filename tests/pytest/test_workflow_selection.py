"""Execute the checked-in CI classifier rather than asserting workflow text."""

import os
from pathlib import Path
import subprocess

import pytest
import yaml


REPO = Path(__file__).resolve().parents[2]


@pytest.mark.parametrize(
    ("event", "base_ref", "plain", "luks"),
    [
        ("workflow_dispatch", "", "true", "true"),
        ("pull_request", "main", "true", "true"),
        ("pull_request", "stable", "false", "false"),
        ("push", "", "false", "false"),
    ],
)
def test_full_selection_executes_required_manual_modes(tmp_path, event, base_ref, plain, luks):
    workflow = yaml.safe_load((REPO / ".github/workflows/test.yml").read_text())
    classifier = next(
        step["run"]
        for step in workflow["jobs"]["changes"]["steps"]
        if step.get("id") == "classify"
    )
    changed = tmp_path / "changed"
    changed.write_text("")
    output = tmp_path / "outputs"
    summary = tmp_path / "summary"
    result = subprocess.run(
        ["bash", "-euo", "pipefail", "-c", classifier],
        cwd=REPO,
        env={
            **os.environ,
            "ALL": "true",
            "EVENT": event,
            "BASE_REF": base_ref,
            "RUN_NUMBER": "2",
            "RR_SIZE": "1",
            "CHANGED": str(changed),
            "GITHUB_OUTPUT": str(output),
            "GITHUB_STEP_SUMMARY": str(summary),
        },
        capture_output=True,
        text=True,
        check=True,
    )
    values = dict(line.split("=", 1) for line in output.read_text().splitlines())
    assert values["e2e-plain"] == plain, result.stdout + result.stderr
    assert values["e2e-luks"] == luks, result.stdout + result.stderr
    assert values["graph"] == "true"
