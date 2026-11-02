import importlib.util
import json
from pathlib import Path
import subprocess
import sys

import pytest

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts/release-health.py"
spec = importlib.util.spec_from_file_location("release_health", SCRIPT)
release_health = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release_health)
REF = "ghcr.io/tuna-os/tromso@sha256:" + "a" * 64
SHA = "b" * 40
RUN = {"databaseId": 123, "headSha": SHA, "status": "completed", "conclusion": "success"}


def document(kind="iso"):
    return release_health.qualification(kind, REF, SHA, "123")


def test_record_cli_uses_actual_source_pin(tmp_path):
    reference = tmp_path / "payload-ref"
    reference.write_text(REF + "\n")
    import os
    env = {**os.environ, "GITHUB_SHA": SHA, "GITHUB_RUN_ID": "123"}
    result = subprocess.run(
        [sys.executable, str(SCRIPT), "record", "plain", str(reference)],
        env=env, text=True, capture_output=True, check=True,
    )
    assert json.loads(result.stdout) == document("plain")


@pytest.mark.parametrize("field,value", [
    ("schemaVersion", True), ("kind", "luks"), ("sourceRef", REF[:-1] + "b"),
    ("workflowSha", "c" * 40), ("runId", "124"), ("success", False),
])
def test_qualification_rejects_mismatched_evidence(field, value):
    evidence = document()
    evidence[field] = value
    with pytest.raises(ValueError, match=field):
        release_health.verify_qualification(evidence, "iso", REF, RUN)


def test_qualification_rejects_missing_evidence():
    with pytest.raises(ValueError, match="schemaVersion"):
        release_health.verify_qualification({}, "iso", REF, RUN)


def test_qualification_accepts_matching_evidence():
    release_health.verify_qualification(document(), "iso", REF, RUN)


def test_mutable_ref_cannot_be_qualified():
    with pytest.raises(ValueError, match="immutable"):
        release_health.qualification("iso", "ghcr.io/tuna-os/tromso:latest", SHA, "123")


def test_latest_completed_does_not_select_an_older_green_run():
    failed = {**RUN, "conclusion": "failure"}
    assert release_health.latest_completed([
        {**RUN, "status": "in_progress"}, failed, RUN,
    ]) is failed
    with pytest.raises(ValueError, match="did not succeed"):
        release_health.require_success(failed, False)
    release_health.require_success(failed, True)


def test_no_completed_run_fails_closed():
    with pytest.raises(ValueError, match="No completed"):
        release_health.latest_completed([{**RUN, "status": "queued"}])


@pytest.mark.parametrize("force", [False, True])
def test_check_compares_all_three_actual_artifacts(monkeypatch, force):
    downloaded = []
    monkeypatch.setattr(release_health, "latest", lambda workflow: RUN)

    def download(*args):
        kind = args[4].removeprefix("qualification-")
        downloaded.append(kind)
        (Path(args[-1]) / "qualification.json").write_text(json.dumps(document(kind)))
        return ""

    monkeypatch.setattr(release_health, "gh", download)
    release_health.check(REF, force)
    assert downloaded == ["iso", "plain", "luks"]


def test_force_cannot_bypass_a_different_image(monkeypatch):
    monkeypatch.setattr(release_health, "latest", lambda workflow: {**RUN, "conclusion": "failure"})

    def download(*args):
        evidence = {**document(), "sourceRef": REF[:-1] + "b"}
        (Path(args[-1]) / "qualification.json").write_text(json.dumps(evidence))
        return ""

    monkeypatch.setattr(release_health, "gh", download)
    with pytest.raises(ValueError, match="sourceRef"):
        release_health.check(REF, True)


def test_missing_artifact_is_not_replaced_by_an_old_run(monkeypatch):
    monkeypatch.setattr(release_health, "latest", lambda workflow: RUN)

    def download(*args):
        raise subprocess.CalledProcessError(1, ["gh", *args])

    monkeypatch.setattr(release_health, "gh", download)
    with pytest.raises(subprocess.CalledProcessError):
        release_health.check(REF, True)


def test_native_image_verifier_rejects_non_commit_input():
    result = subprocess.run(
        ["bash", str(ROOT / "scripts/verify-published-image.sh"), "main"],
        text=True, capture_output=True,
    )
    assert result.returncode != 0
    assert "Expected a full commit SHA" in result.stderr
