"""Stable promotion is bound to one immutable release candidate (#309).

These tests run the production shell from the workflows with fake `gh` and
`skopeo` binaries, and evaluate the job gates for every result combination.
"""

import json
import os
import subprocess
from itertools import product
from pathlib import Path

import pytest
import yaml

REPO = Path(__file__).resolve().parents[2]
WORKFLOWS = REPO / ".github/workflows"
SHA = "a" * 40
DIGEST = "sha256:" + "b" * 64
GATES = ("candidate", "iso", "plain", "luks")


def workflow(name):
    return yaml.safe_load((WORKFLOWS / name).read_text())


def step(job, name):
    return next(s for s in job["steps"] if s.get("name") == name)


def fake(tmp_path, name, body):
    path = tmp_path / "bin" / name
    path.parent.mkdir(exist_ok=True)
    path.write_text("#!/bin/bash\nset -eu\n" + body)
    path.chmod(0o755)


def evaluate(expression, values):
    """Evaluate a GitHub Actions boolean expression made of ==, && and ||."""
    expression = expression.strip().removeprefix("${{").removesuffix("}}")
    for key, value in values.items():
        expression = expression.replace(key, repr(value))
    expression = expression.replace("&&", " and ").replace("||", " or ")
    return eval(expression.replace("true", "True"), {"__builtins__": {}})


# ── candidate selection ──────────────────────────────────────────────────────

@pytest.mark.parametrize("run,candidate,expected", [
    ({"databaseId": 1, "headSha": SHA}, {"sha": SHA, "digest": DIGEST}, True),
    ({"databaseId": 1, "headSha": SHA}, {"sha": "c" * 40, "digest": DIGEST}, False),
    ({"databaseId": 1, "headSha": SHA}, {"sha": SHA[:12], "digest": DIGEST}, False),
    ({"databaseId": 1, "headSha": SHA}, {"sha": SHA, "digest": "latest"}, False),
    ({"databaseId": 1, "headSha": SHA}, {"sha": SHA, "digest": "sha256:short"}, False),
    ({"databaseId": 1, "headSha": SHA}, {"sha": SHA}, False),
    ({"databaseId": 1, "headSha": SHA}, None, False),  # artifact missing or expired
    (None, {"sha": SHA, "digest": DIGEST}, False),  # no successful main build
])
def test_candidate_selection_rejects_invalid_evidence(tmp_path, run, candidate, expected):
    script = step(workflow("promote-stable.yml")["jobs"]["candidate"],
                  "Select successful main build and its immutable candidate")["run"]
    fake(tmp_path, "gh", """
if [ "$2" = list ]; then
    echo "$FAKE_RUN"
else
    [ "$FAKE_CANDIDATE" != null ] || { echo 'no artifact matches' >&2; exit 1; }
    mkdir -p candidate
    echo "$FAKE_CANDIDATE" > candidate/release-candidate.json
fi
""")
    output = tmp_path / "output"
    result = subprocess.run(
        ["bash", "-c", script], cwd=tmp_path, capture_output=True, text=True,
        env={**os.environ, "PATH": f"{tmp_path / 'bin'}:{os.environ['PATH']}",
             "FAKE_RUN": json.dumps(run), "FAKE_CANDIDATE": json.dumps(candidate),
             "GITHUB_REPOSITORY": "tuna-os/tromso", "GITHUB_OUTPUT": str(output),
             "GITHUB_STEP_SUMMARY": str(tmp_path / "summary")},
    )
    assert (result.returncode == 0) == expected, result.stderr
    if expected:
        assert output.read_text() == f"sha={SHA}\ndigest={DIGEST}\n"
    else:
        assert not output.exists()


def test_build_records_the_pushed_digest():
    """The x86_64 signer uploads the digest build_final pushed and it signed."""
    data = workflow("build-tromso-multirunner.yml")
    job = data["jobs"]["sign_final"]
    assert job["needs"] == "build_final"
    assert data["jobs"]["build_final"]["uses"].endswith("/.github/workflows/build-final.yml")
    names = [s.get("name") for s in job["steps"]]
    record = step(job, "Record release candidate")
    upload = step(job, "Upload release candidate")
    assert names.index("Sign image (cosign keyless)") < names.index("Record release candidate")
    assert names.index("Record release candidate") < names.index("Upload release candidate")
    assert record["env"] == {"CANDIDATE_SHA": "${{ github.sha }}",
                             "CANDIDATE_DIGEST": "${{ needs.build_final.outputs.digest }}"}
    assert upload["with"]["name"] == "release-candidate"
    assert upload["with"]["path"] == "release-candidate.json"
    assert upload["with"]["if-no-files-found"] == "error"


def test_recorded_candidate_is_valid_json(tmp_path):
    record = step(workflow("build-tromso-multirunner.yml")["jobs"]["sign_final"],
                  "Record release candidate")
    subprocess.run(["bash", "-e", "-c", record["run"]], cwd=tmp_path, check=True,
                   capture_output=True, env={**os.environ, "CANDIDATE_SHA": SHA,
                                             "CANDIDATE_DIGEST": DIGEST})
    assert json.loads((tmp_path / "release-candidate.json").read_text()) == {
        "sha": SHA, "digest": DIGEST}


# ── gates ────────────────────────────────────────────────────────────────────

def test_every_gate_validates_the_same_candidate():
    jobs = workflow("promote-stable.yml")["jobs"]
    for name in ("iso", "plain", "luks", "publish-stable-iso"):
        assert "candidate" in jobs[name]["needs"]
        assert jobs[name]["with"]["candidate_sha"] == "${{ needs.candidate.outputs.sha }}"
        assert jobs[name]["with"]["candidate_digest"] == "${{ needs.candidate.outputs.digest }}"
    assert jobs["iso"]["with"]["skip_upload"] is True
    assert jobs["publish-stable-iso"]["with"]["skip_upload"] is False
    assert jobs["publish-stable-iso"]["with"]["release_channel"] == "stable"
    assert jobs["publish-stable-iso"]["needs"] == ["candidate", "promote"]
    for callee, job in (("build-iso.yml", "build-and-publish"),
                        ("test-plain-install.yml", "plain-e2e"),
                        ("test-luks-install.yml", "luks-e2e")):
        data = workflow(callee)
        inputs = data[True]["workflow_call"]["inputs"]  # PyYAML reads `on` as True
        assert inputs["candidate_sha"]["default"] == ""
        assert inputs["candidate_digest"]["default"] == ""
        steps = data["jobs"][job]["steps"]
        checkout = steps[0]
        assert checkout["uses"].startswith("actions/checkout@")
        assert checkout["with"]["ref"].startswith("${{ inputs.candidate_sha || ")
        pin = step(data["jobs"][job], "Pin release candidate payload")
        assert "scripts/pin-candidate-payload.sh" in pin["run"]
        assert "tromso/payload_ref" in pin["run"]
        names = [s.get("name") for s in steps]
        build = "Build Live ISO" if callee == "build-iso.yml" else "Build debug ISO"
        assert names.index("Pin release candidate payload") < names.index(build)


@pytest.mark.parametrize("event", ["schedule", "workflow_dispatch"])
def test_promotion_requires_every_gate_success(event):
    """No event and no input can promote past failed or missing evidence."""
    data = workflow("promote-stable.yml")
    assert data[True]["workflow_dispatch"] is None  # no force or escape input
    promote = data["jobs"]["promote"]
    assert sorted(promote["needs"]) == sorted(GATES)
    expression = promote["if"]
    assert "always()" not in expression and "failure()" not in expression
    for results in product(("success", "failure", "cancelled", "skipped"), repeat=4):
        values = {f"needs.{gate}.result": result for gate, result in zip(GATES, results)}
        values["github.event_name"] = event
        assert evaluate(expression, values) == all(r == "success" for r in results)


def test_only_promotion_holds_write_authority():
    """Jobs that run candidate code get read-only tokens and no secrets."""
    data = workflow("promote-stable.yml")
    assert all(level != "write" for level in data["permissions"].values())
    for name, job in data["jobs"].items():
        writes = {scope for scope, level in job.get("permissions", {}).items() if level == "write"}
        if name == "promote":
            assert writes == {"contents", "packages"}
            assert not any("actions/checkout" in s.get("uses", "") for s in job["steps"])
        elif name in ("iso", "publish-stable-iso"):
            assert writes == {"id-token"}  # ceiling for the build-iso.yml publish job
        else:
            assert not writes, name
        if name in ("candidate", "iso", "plain", "luks"):
            assert "secrets" not in job, name
    assert data["jobs"]["publish-stable-iso"]["secrets"] != "inherit"


def test_candidate_execution_has_no_write_or_signing_authority():
    """Effective callee permissions for the validation calls."""
    caller = workflow("promote-stable.yml")["jobs"]
    for name in ("iso", "plain", "luks"):
        callee = workflow(caller[name]["uses"].removeprefix("$/.github/workflows/"))
        for job_name, job in callee["jobs"].items():
            if name == "iso" and job_name == "publish":
                # Unreachable from validation: skip_upload is true.
                assert not evaluate(job["if"], {
                    "inputs.skip_upload": caller["iso"]["with"]["skip_upload"],
                    "github.event_name": "workflow_dispatch"})
                continue
            permissions = job.get("permissions", callee.get("permissions", {}))
            assert all(level != "write" for level in permissions.values()), (name, job_name)


def test_failed_iso_boot_prevents_publication():
    """Every R2 writer depends on the job that boots the ISO, without bypass."""
    jobs = workflow("build-iso.yml")["jobs"]
    writers = [name for name, job in jobs.items()
               if any("rclone copyto" in s.get("run", "") for s in job["steps"])]
    assert writers == ["publish"]
    publish = jobs["publish"]
    assert publish["needs"] == "build-and-publish"
    assert any("qemu-system-x86_64" in s.get("run", "") for s in jobs["build-and-publish"]["steps"])
    for expression in (publish["if"], *(s.get("if", "") for s in publish["steps"])):
        assert "always()" not in expression and "failure()" not in expression
    assert not any("actions/checkout" in s.get("uses", "") for s in publish["steps"])
    assert "id-token" not in jobs["build-and-publish"]["permissions"]
    assert publish["permissions"]["id-token"] == "write"


@pytest.mark.parametrize("outcome", ["success", "failure", "cancelled", "skipped", ""])
def test_publish_requires_boot_evidence(outcome):
    evidence = step(workflow("build-iso.yml")["jobs"]["publish"], "Boot verification evidence")
    assert evidence["id"] == "boot_verify"
    result = subprocess.run(["bash", "-e", "-c", evidence["run"]], capture_output=True,
                            text=True, env={**os.environ, "BOOT_OUTCOME": outcome})
    assert (result.returncode == 0) == (outcome == "success")


# ── promotion ────────────────────────────────────────────────────────────────

@pytest.mark.parametrize("on_main,from_stable,promoted", [
    ("ahead", "ahead", True),
    ("identical", "identical", True),
    ("diverged", "ahead", False),   # candidate is not on main
    ("behind", "ahead", False),
    ("ahead", "behind", False),     # stable would move backwards
    ("ahead", "diverged", False),   # stable would need a force push
])
def test_promotion_checks_ancestry_before_any_write(tmp_path, on_main, from_stable, promoted):
    promote = workflow("promote-stable.yml")["jobs"]["promote"]
    script = step(promote, "Publish verified digest and fast-forward stable")["run"]
    log = tmp_path / "calls"
    fake(tmp_path, "gh", """
echo "gh $*" >> "$CALLS"
case "$*" in
    *"compare/$SHA...main"*) echo "$ON_MAIN" ;;
    *"compare/stable...$SHA"*) echo "$FROM_STABLE" ;;
esac
""")
    fake(tmp_path, "skopeo", 'cat > /dev/null || true\necho "skopeo $*" >> "$CALLS"\n')
    result = subprocess.run(
        ["bash", "-c", script], capture_output=True, text=True,
        env={**os.environ, "PATH": f"{tmp_path / 'bin'}:{os.environ['PATH']}",
             "CALLS": str(log), "SHA": SHA, "DIGEST": DIGEST, "GH_TOKEN": "token",
             "ON_MAIN": on_main, "FROM_STABLE": from_stable,
             "GITHUB_REPOSITORY": "tuna-os/tromso", "GITHUB_ACTOR": "bot",
             "GITHUB_STEP_SUMMARY": str(tmp_path / "summary")},
    )
    calls = log.read_text().splitlines()
    writes = [c for c in calls if c.startswith("skopeo copy") or "-X PATCH" in c]
    assert (result.returncode == 0) == promoted, result.stderr
    if not promoted:
        assert writes == []
        return
    assert writes == [
        f"skopeo copy --preserve-digests docker://ghcr.io/tuna-os/tromso@{DIGEST} "
        "docker://ghcr.io/tuna-os/tromso:stable",
        f"gh api -X PATCH repos/tuna-os/tromso/git/refs/heads/stable -f sha={SHA} -F force=false",
    ]


@pytest.mark.parametrize("sha,digest", [("", DIGEST), (SHA, ""), (SHA, "sha256:latest")])
def test_promotion_rejects_malformed_candidate_outputs(tmp_path, sha, digest):
    promote = workflow("promote-stable.yml")["jobs"]["promote"]
    script = step(promote, "Publish verified digest and fast-forward stable")["run"]
    fake(tmp_path, "gh", 'echo "gh $*" >> "$CALLS"\necho ahead\n')
    fake(tmp_path, "skopeo", 'echo "skopeo $*" >> "$CALLS"\n')
    log = tmp_path / "calls"
    result = subprocess.run(
        ["bash", "-c", script], capture_output=True, text=True,
        env={**os.environ, "PATH": f"{tmp_path / 'bin'}:{os.environ['PATH']}",
             "CALLS": str(log), "SHA": sha, "DIGEST": digest,
             "GITHUB_REPOSITORY": "tuna-os/tromso", "GITHUB_ACTOR": "bot",
             "GITHUB_STEP_SUMMARY": str(tmp_path / "summary")},
    )
    assert result.returncode != 0
    assert not log.exists()


def test_promotion_never_force_pushes():
    text = (WORKFLOWS / "promote-stable.yml").read_text()
    assert "--force" not in text and "force: true" not in text
    assert "-F force=false" in text


# ── payload pin ──────────────────────────────────────────────────────────────

@pytest.fixture
def checkout(tmp_path):
    repo = tmp_path / "repo"
    repo.mkdir()
    git = ["git", "-C", str(repo), "-c", "user.name=t", "-c", "user.email=t@t"]
    subprocess.run(["git", "init", "-q", str(repo)], check=True)
    subprocess.run([*git, "commit", "-q", "--allow-empty", "-m", "c"], check=True)
    head = subprocess.run([*git, "rev-parse", "HEAD"], check=True,
                          capture_output=True, text=True).stdout.strip()
    (repo / "payload_ref").write_text("ghcr.io/tuna-os/tromso:latest\n")
    return repo, head


def pin(repo, sha, digest):
    return subprocess.run(
        ["bash", str(REPO / "scripts/pin-candidate-payload.sh"), sha, digest, "payload_ref"],
        cwd=repo, capture_output=True, text=True)


def test_pin_names_the_payload_by_digest(checkout):
    repo, head = checkout
    result = pin(repo, head, DIGEST)
    assert result.returncode == 0, result.stderr
    assert (repo / "payload_ref").read_text() == f"ghcr.io/tuna-os/tromso@{DIGEST}\n"


@pytest.mark.parametrize("sha,digest", [
    ("c" * 40, DIGEST),                  # checkout is not the candidate
    ("HEAD", DIGEST),
    (None, "latest"),
    (None, "sha256:" + "B" * 64),
    (None, ""),
    ("", DIGEST),
])
def test_pin_rejects_mismatched_or_mutable_candidates(checkout, sha, digest):
    repo, head = checkout
    result = pin(repo, head if sha is None else sha, digest)
    assert result.returncode != 0
    assert (repo / "payload_ref").read_text() == "ghcr.io/tuna-os/tromso:latest\n"


def test_live_image_and_payload_share_one_ref():
    """iso-sd-boot hands its payload ref to the live image build."""
    justfile = (REPO / "iso.justfile").read_text()
    assert 'container {{target}} "${PAYLOAD_REF}"' in justfile
    assert 'container target payload_ref="":' in justfile
    assert '--build-arg BASE_IMAGE="${BUILD_BASE}"' in justfile
