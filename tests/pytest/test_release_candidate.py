"""Exercise the actual candidate-selection shell with a fake GitHub API."""

import json
import os
import subprocess
from itertools import product
from pathlib import Path

import pytest
import yaml

REPO = Path(__file__).resolve().parents[2]
SHA = 'a' * 40
DIGEST = 'sha256:' + 'b' * 64


@pytest.mark.parametrize('candidate,expected', [
    ({'sha': SHA, 'digest': DIGEST}, True),
    ({'sha': 'c' * 40, 'digest': DIGEST}, False),
    ({'sha': SHA, 'digest': 'latest'}, False),
    ({'sha': SHA}, False),
    (None, False),
])
def test_candidate_selection_rejects_invalid_evidence(tmp_path, candidate, expected):
    workflow = yaml.safe_load(
        (REPO / '.github/workflows/promote-stable.yml').read_text()
    )
    script = workflow['jobs']['candidate']['steps'][-1]['run']
    gh = tmp_path / 'gh'
    gh.write_text('''#!/bin/bash
set -eu
if [ "$2" = list ]; then
    echo "$FAKE_RUN"
else
    mkdir -p candidate
    if [ "$FAKE_CANDIDATE" = null ]; then exit 1; fi
    echo "$FAKE_CANDIDATE" > candidate/release-candidate.json
fi
''')
    gh.chmod(0o755)
    output = tmp_path / 'output'
    result = subprocess.run(
        ['bash', '-c', script], cwd=tmp_path, capture_output=True, text=True,
        env={**os.environ, 'PATH': f'{tmp_path}:{os.environ["PATH"]}',
             'FAKE_RUN': json.dumps({'databaseId': 123, 'headSha': SHA}),
             'FAKE_CANDIDATE': json.dumps(candidate),
             'GITHUB_REPOSITORY': 'tuna-os/tromso',
             'GITHUB_OUTPUT': str(output),
             'GITHUB_STEP_SUMMARY': str(tmp_path / 'summary')},
    )
    assert (result.returncode == 0) == expected, result.stderr
    if expected:
        assert output.read_text() == f'sha={SHA}\ndigest={DIGEST}\n'
    else:
        assert not output.exists()


@pytest.mark.parametrize("event", ["schedule", "workflow_dispatch"])
def test_promotion_requires_every_gate_success(event):
    """Neither a manual event nor the old force input may bypass failed evidence."""
    workflow = yaml.safe_load(
        (REPO / ".github/workflows/promote-stable.yml").read_text()
    )
    expression = workflow["jobs"]["promote"]["if"]
    gates = ("candidate", "iso", "plain", "luks")
    for results in product(("success", "failure", "cancelled", "skipped"), repeat=4):
        evaluated = expression.replace("always()", "True")
        evaluated = evaluated.replace("github.event_name", repr(event))
        evaluated = evaluated.replace("inputs.force", "True")
        for gate, result in zip(gates, results):
            evaluated = evaluated.replace(f"needs.{gate}.result", repr(result))
        admitted = eval(
            evaluated.replace("&&", " and ").replace("||", " or "),
            {"__builtins__": {}},
        )
        assert admitted == all(result == "success" for result in results), results


def test_iso_upload_errors_stop_before_any_later_alias(tmp_path):
    """Run the production publication shell with each request failing in turn."""
    workflow = yaml.safe_load((REPO / ".github/workflows/build-iso.yml").read_text())
    steps = workflow["jobs"]["publish"]["steps"]
    script = next(step["run"] for step in steps if "rclone copyto" in step.get("run", ""))
    log = tmp_path / "uploads"
    stub = """
    rclone() {
        count=$((count + 1))
        printf '%s\\n' "$*" >> "$UPLOAD_LOG"
        [ "$count" -ne "$FAIL_AT" ]
    }
    count=0
    """
    for failure in range(1, 10):
        log.write_text("")
        result = subprocess.run(
            ["bash", "-e", "-c", stub + script], capture_output=True, text=True,
            env={**os.environ, "UPLOAD_LOG": str(log), "FAIL_AT": str(failure),
                 "R2_BUCKET": "test", "R2_PREFIX": "tromso/stable", "DATED": "candidate.iso"},
        )
        requests = log.read_text().splitlines()
        assert (result.returncode == 0) == (failure == 9), result.stderr
        assert len(requests) == min(failure, 8)
        assert all("latest" not in request for request in requests[:4])
        if failure == 9:
            assert requests[-1].endswith("/tromso-live-latest.iso")


def test_candidate_execution_has_no_write_or_signing_authority():
    """Effective job tokens and secret inheritance cannot cross into validation."""
    workflows = REPO / ".github/workflows"
    promotion = yaml.safe_load((workflows / "promote-stable.yml").read_text())
    for name in ("iso", "plain", "luks"):
        caller = promotion["jobs"][name]
        assert "secrets" not in caller
        callee = yaml.safe_load((REPO / caller["uses"]).read_text())
        for job in callee["jobs"].values():
            if name == "iso" and job is callee["jobs"]["publish"]:
                # The publication branch is unreachable for validation calls.
                condition = job["if"].removeprefix("${{").removesuffix("}}").strip()
                condition = condition.replace("inputs.skip_upload", "True")
                condition = condition.replace("github.event_name", repr("workflow_dispatch"))
                assert not eval(condition.replace("true", "True").replace("&&", " and "),
                                {"__builtins__": {}})
                continue
            permissions = job.get("permissions", callee.get("permissions", {}))
            assert all(level != "write" for level in permissions.values())


def test_failed_iso_boot_prevents_publication():
    """A failed build/boot job must block every R2 writer by job dependency."""
    workflow = yaml.safe_load((REPO / ".github/workflows/build-iso.yml").read_text())
    jobs = workflow["jobs"]
    for name, job in jobs.items():
        if any("rclone copyto" in step.get("run", "") for step in job.get("steps", [])):
            dependencies = job.get("needs", [])
            if isinstance(dependencies, str):
                dependencies = [dependencies]
            boot_jobs = [
                dependency for dependency in dependencies
                if any("qemu-system-x86_64" in step.get("run", "")
                       for step in jobs[dependency].get("steps", []))
            ]
            assert boot_jobs, f"{name} has no boot-gated dependency"
            # No always()/failure() expression may bypass needs' default success gate.
            assert "always()" not in job.get("if", "")
            assert "failure()" not in job.get("if", "")
