"""Contract tests for image publication and architecture channel ownership (#314).

- Final assembly for every architecture is the repository-owned reusable
  workflow .github/workflows/build-final.yml.
- scripts/resolve-image-tags.sh computes the published tags. The bare channel
  tags (:latest, :nightly, :nightly-YYYYMMDD, :stable, :stable-YYYYMMDD) belong
  to x86_64 only (channel_ownership=true). Any other architecture must pass a
  non-empty suffix and never gets a bare channel tag.
- Signing stays in build-tromso-multirunner.yml, the identity README.md's
  cosign verify instructions trust. build-final.yml has no id-token grant.
"""

import os
import re
import subprocess
from pathlib import Path

import pytest
import yaml

REPO = Path(__file__).resolve().parents[2]
WORKFLOWS = REPO / ".github" / "workflows"
RESOLVE_TAGS = REPO / "scripts" / "resolve-image-tags.sh"
CALLER = WORKFLOWS / "build-tromso-multirunner.yml"
CALLEE = WORKFLOWS / "build-final.yml"
REUSABLE = "$/.github/workflows/build-final.yml"

UNSUFFIXED_CHANNEL_TAGS = {"latest", "nightly", "stable"}


def _load(path):
    return yaml.safe_load(path.read_text())


def _run_resolve_tags(ref, sha, channel_owner, tag_suffix=None, date="20261024"):
    cmd = [
        str(RESOLVE_TAGS),
        "--ref", ref,
        "--sha", sha,
        "--channel-owner", str(channel_owner).lower(),
        "--date", date,
    ]
    if tag_suffix is not None:
        cmd.extend(["--tag-suffix", tag_suffix])
    return subprocess.run(cmd, capture_output=True, text=True)


class TestResolveImageTagsScript:
    """Unit and contract tests for scripts/resolve-image-tags.sh."""

    def test_channel_owner_main_channel_tags(self):
        proc = _run_resolve_tags("refs/heads/main", "abcdef123456", True)
        assert proc.returncode == 0, proc.stderr
        assert proc.stdout.split() == ["latest", "nightly", "nightly-20261024", "abcdef123456"]

    def test_channel_owner_stable_channel_tags(self):
        proc = _run_resolve_tags("refs/heads/stable", "abcdef123456", True)
        assert proc.returncode == 0, proc.stderr
        assert proc.stdout.split() == ["stable", "stable-20261024", "abcdef123456"]

    def test_channel_owner_accepts_explicit_empty_suffix(self):
        """build-final.yml always passes --tag-suffix, empty for x86_64."""
        proc = _run_resolve_tags("refs/heads/main", "abcdef123456", True, "")
        assert proc.returncode == 0, proc.stderr
        assert proc.stdout.split() == ["latest", "nightly", "nightly-20261024", "abcdef123456"]

    def test_channel_owner_rejects_tag_suffix(self):
        proc = _run_resolve_tags("refs/heads/main", "abcdef123456", True, "-aarch64")
        assert proc.returncode != 0
        assert "channel owner must not specify tag suffix" in proc.stderr

    def test_non_channel_owner_main_tags_are_suffixed(self):
        proc = _run_resolve_tags("refs/heads/main", "abcdef123456", False, "-aarch64")
        assert proc.returncode == 0, proc.stderr
        assert proc.stdout.split() == [
            "latest-aarch64",
            "nightly-aarch64",
            "nightly-20261024-aarch64",
            "abcdef123456-aarch64",
        ]

    def test_non_channel_owner_stable_tags_are_suffixed(self):
        proc = _run_resolve_tags("refs/heads/stable", "abcdef123456", False, "-aarch64")
        assert proc.returncode == 0, proc.stderr
        assert proc.stdout.split() == [
            "stable-aarch64",
            "stable-20261024-aarch64",
            "abcdef123456-aarch64",
        ]

    def test_non_channel_owner_rejects_empty_suffix(self):
        proc = _run_resolve_tags("refs/heads/main", "abcdef123456", False, "")
        assert proc.returncode != 0
        assert "non-channel-owner must specify non-empty tag suffix" in proc.stderr

    def test_non_channel_owner_rejects_missing_suffix(self):
        proc = _run_resolve_tags("refs/heads/main", "abcdef123456", False)
        assert proc.returncode != 0
        assert "non-channel-owner must specify non-empty tag suffix" in proc.stderr

    def test_rejects_unknown_ownership_value(self):
        proc = _run_resolve_tags("refs/heads/main", "abcdef123456", "yes", "-aarch64")
        assert proc.returncode != 0
        assert not proc.stdout.strip()

    @pytest.mark.parametrize("ref", ["refs/heads/main", "refs/heads/stable", "refs/heads/feature"])
    @pytest.mark.parametrize("suffix", ["-aarch64", "-riscv64", "-arm64"])
    def test_unsuffixed_channel_tags_never_emitted_for_non_channel_owners(self, ref, suffix):
        proc = _run_resolve_tags(ref, "1234567890ab", False, suffix)
        assert proc.returncode == 0, proc.stderr
        tags = proc.stdout.split()
        assert set(tags).isdisjoint(UNSUFFIXED_CHANNEL_TAGS)
        assert all(tag.endswith(suffix) for tag in tags)


@pytest.mark.parametrize("suffix", [" latest", "-arm64 latest", "-arm64\nstable", "/arm64", "-", "aarch64"])
def test_suffix_cannot_inject_unsuffixed_channel_tags(suffix):
    result = _run_resolve_tags("refs/heads/main", "abcdef", False, suffix)
    assert result.returncode != 0
    assert not result.stdout.strip()


def _final_jobs():
    caller = _load(CALLER)
    return {name: job for name, job in caller["jobs"].items() if job.get("uses") == REUSABLE}


def test_each_architecture_calls_the_reusable_final_build():
    jobs = _final_jobs()
    assert set(jobs) == {"build_final", "build_final_aarch64"}
    x86, arm = jobs["build_final"]["with"], jobs["build_final_aarch64"]["with"]
    assert x86["architecture"] == "x86_64" and x86["channel_ownership"] is True
    assert x86["tag_suffix"] == "" and x86["cache_suffix"] == ""
    assert arm["architecture"] == "aarch64" and arm["channel_ownership"] is False
    assert arm["tag_suffix"] == "-aarch64" and arm["cache_suffix"] == "-aarch64"
    # aarch64 is unverified (#88): no remote executor, manual dispatch only.
    assert arm["enable_remote_execution"] is False
    caller = _load(CALLER)
    assert jobs["build_final_aarch64"]["needs"] == "multirunner_aarch64"
    assert "workflow_dispatch" in caller["jobs"]["multirunner_aarch64"]["if"]
    assert "inputs.build_aarch64" in caller["jobs"]["multirunner_aarch64"]["if"]


def test_final_build_inputs_are_declared_and_used():
    callee = _load(CALLEE)
    # PyYAML reads the bare `on:` key as boolean True.
    declared = set(callee[True]["workflow_call"]["inputs"])
    text = CALLEE.read_text()
    for name in declared:
        assert f"inputs.{name}" in text, f"input {name} is declared but unused"
    for job in _final_jobs().values():
        assert set(job["with"]) <= declared
        required = {name for name, spec in callee[True]["workflow_call"]["inputs"].items()
                    if spec.get("required")}
        assert required <= set(job["with"])
        assert "inherit" != job.get("secrets")


def test_push_step_resolves_tags_through_the_contract_script():
    steps = _load(CALLEE)["jobs"]["build_final"]["steps"]
    push = next(step for step in steps if step.get("id") == "push")
    assert "scripts/resolve-image-tags.sh" in push["run"]
    assert push["env"]["CHANNEL_OWNER"] == "${{ inputs.channel_ownership }}"
    assert push["env"]["TAG_SUFFIX"] == "${{ inputs.tag_suffix }}"
    # No inline tag lists may bypass the script.
    assert "TAGS=\"" not in push["run"]
    assert 'digest-${GITHUB_SHA}${TAG_SUFFIX}' in push["run"]


def test_x86_only_checks_stay_x86_only():
    steps = _load(CALLEE)["jobs"]["build_final"]["steps"]
    for step in steps:
        run = step.get("run", "")
        if "getcap" in run or "leaked overlay whiteouts" in run:
            assert step["if"] == "inputs.architecture == 'x86_64'"


def test_final_build_has_no_signing_identity():
    callee = _load(CALLEE)
    code = "\n".join(line for line in CALLEE.read_text().splitlines()
                     if not line.lstrip().startswith("#"))
    assert "id-token" not in code
    assert "cosign" not in code
    assert callee["permissions"] == {"contents": "read"}
    job = callee["jobs"]["build_final"]
    assert job["permissions"] == {
        "contents": "read", "packages": "write", "security-events": "write",
    }
    for caller_job in _final_jobs().values():
        assert caller_job["permissions"] == job["permissions"]


def test_signing_stays_in_existing_identity_workflow():
    """Execute signing commands against a recorder, retaining the verifier boundary."""
    caller = _load(CALLER)
    signed = {}
    digest = "sha256:" + "a" * 64
    for name, job in caller["jobs"].items():
        for step in job.get("steps", []):
            if "cosign sign" not in step.get("run", ""):
                continue
            assert job["permissions"]["id-token"] == "write"
            # No checkout: the signing jobs run no repository code.
            assert not any(s.get("uses", "").startswith("actions/checkout@") for s in job["steps"])
            source = re.fullmatch(r"\$\{\{ needs\.(\w+)\.outputs\.digest \}\}", step["env"]["IMAGE_DIGEST"])
            assert source and source[1] in job["needs"]
            assert f"needs.{source[1]}.result == 'success'" in job["if"]
            command = "cosign() { printf '%s\\n' \"$*\"; }; " + step["run"]
            result = subprocess.run(
                ["bash", "-e", "-c", command], capture_output=True, text=True,
                env={**os.environ, "IMAGE_REGISTRY": "ghcr.io/tuna-os",
                     "IMAGE_NAME": caller["env"]["IMAGE_NAME"], "IMAGE_DIGEST": digest},
            )
            assert result.returncode == 0, result.stderr
            signed[source[1]] = result.stdout.strip()
    expected = f"sign --yes ghcr.io/tuna-os/tromso@{digest}"
    assert signed == {"build_final": expected, "build_final_aarch64": expected}


def test_readme_verifier_identity_is_not_widened():
    readme = (REPO / "README.md").read_text()
    identities = re.findall(r"--certificate-identity-regexp '([^']+)'", readme)
    assert "https://github.com/tuna-os/tromso/\\.github/workflows/build-tromso-multirunner\\.yml@.*" in identities
    assert not any("build-final" in identity for identity in identities)
