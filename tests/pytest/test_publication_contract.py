"""Contract tests for image publication and architecture channel exclusivity.

Issue #314:
- Final assembly and publication is extracted into a repository-owned reusable workflow
  (.github/workflows/build-final.yml) with typed inputs.
- scripts/resolve-image-tags.sh computes image tags and enforces channel ownership.
- Unsuffixed channel tags (:latest, :nightly, :nightly-YYYYMMDD, :stable, :stable-YYYYMMDD)
  are strictly exclusive to x86_64 (channel_ownership=true).
- Any non-channel-owner (e.g. aarch64) must specify a non-empty tag suffix and cannot
  publish unsuffixed channel tags.
"""

import subprocess
from pathlib import Path
import pytest
import yaml

REPO = Path(__file__).resolve().parents[2]
WORKFLOWS = REPO / ".github" / "workflows"
RESOLVE_TAGS = REPO / "scripts" / "resolve-image-tags.sh"

UNSUFFIXED_CHANNEL_TAGS = {"latest", "nightly", "stable"}


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
        proc = _run_resolve_tags(
            ref="refs/heads/main",
            sha="abcdef123456",
            channel_owner=True,
            date="20261024",
        )
        assert proc.returncode == 0, proc.stderr
        tags = proc.stdout.strip().split()
        assert tags == ["latest", "nightly", "nightly-20261024", "abcdef123456"]

    def test_channel_owner_stable_channel_tags(self):
        proc = _run_resolve_tags(
            ref="refs/heads/stable",
            sha="abcdef123456",
            channel_owner=True,
            date="20261024",
        )
        assert proc.returncode == 0, proc.stderr
        tags = proc.stdout.strip().split()
        assert tags == ["stable", "stable-20261024", "abcdef123456"]

    def test_channel_owner_rejects_tag_suffix(self):
        proc = _run_resolve_tags(
            ref="refs/heads/main",
            sha="abcdef123456",
            channel_owner=True,
            tag_suffix="-aarch64",
        )
        assert proc.returncode != 0
        assert "channel owner must not specify tag suffix" in proc.stderr

    def test_non_channel_owner_main_tags_are_suffixed(self):
        proc = _run_resolve_tags(
            ref="refs/heads/main",
            sha="abcdef123456",
            channel_owner=False,
            tag_suffix="-aarch64",
            date="20261024",
        )
        assert proc.returncode == 0, proc.stderr
        tags = proc.stdout.strip().split()
        assert tags == [
            "latest-aarch64",
            "nightly-aarch64",
            "nightly-20261024-aarch64",
            "abcdef123456-aarch64",
        ]
        for tag in tags:
            assert tag not in UNSUFFIXED_CHANNEL_TAGS
            assert tag.endswith("-aarch64")

    def test_non_channel_owner_stable_tags_are_suffixed(self):
        proc = _run_resolve_tags(
            ref="refs/heads/stable",
            sha="abcdef123456",
            channel_owner=False,
            tag_suffix="-aarch64",
            date="20261024",
        )
        assert proc.returncode == 0, proc.stderr
        tags = proc.stdout.strip().split()
        assert tags == [
            "stable-aarch64",
            "stable-20261024-aarch64",
            "abcdef123456-aarch64",
        ]
        for tag in tags:
            assert tag not in UNSUFFIXED_CHANNEL_TAGS
            assert tag.endswith("-aarch64")

    def test_non_channel_owner_rejects_empty_suffix(self):
        proc = _run_resolve_tags(
            ref="refs/heads/main",
            sha="abcdef123456",
            channel_owner=False,
            tag_suffix="",
        )
        assert proc.returncode != 0
        assert "non-channel-owner must specify non-empty tag suffix" in proc.stderr

    def test_non_channel_owner_rejects_missing_suffix(self):
        proc = _run_resolve_tags(
            ref="refs/heads/main",
            sha="abcdef123456",
            channel_owner=False,
        )
        assert proc.returncode != 0
        assert "non-channel-owner must specify non-empty tag suffix" in proc.stderr

    @pytest.mark.parametrize("ref", ["refs/heads/main", "refs/heads/stable", "refs/heads/feature"])
    @pytest.mark.parametrize("suffix", ["-aarch64", "-riscv64", "-arm64"])
    def test_unsuffixed_channel_tags_never_emitted_for_non_channel_owners(self, ref, suffix):
        proc = _run_resolve_tags(
            ref=ref,
            sha="1234567890ab",
            channel_owner=False,
            tag_suffix=suffix,
        )
        assert proc.returncode == 0, proc.stderr
        tags = set(proc.stdout.strip().split())
        assert tags.isdisjoint(UNSUFFIXED_CHANNEL_TAGS)


@pytest.mark.parametrize("suffix", [" latest", "-arm64 latest", "-arm64\nstable", "/arm64"])
def test_suffix_cannot_inject_unsuffixed_channel_tags(suffix):
    result = _run_resolve_tags("refs/heads/main", "abcdef", False, suffix)
    assert result.returncode != 0
    assert not result.stdout.strip()


def test_signing_stays_in_existing_identity_workflow():
    """Execute signing commands against a recorder, retaining the verifier boundary."""
    import os

    caller = yaml.safe_load((WORKFLOWS / "build-tromso-multirunner.yml").read_text())
    callee = yaml.safe_load((WORKFLOWS / "build-final.yml").read_text())
    assert callee["jobs"]["build_final"]["permissions"].get("id-token") != "write"
    signed = []
    digest = "sha256:" + "a" * 64
    for job in caller["jobs"].values():
        for step in job.get("steps", []):
            if "cosign sign" not in step.get("run", ""):
                continue
            assert job["permissions"]["id-token"] == "write"
            command = "cosign() { printf '%s\\n' \"$*\"; }; " + step["run"]
            result = subprocess.run(
                ["bash", "-e", "-c", command], capture_output=True, text=True,
                env={**os.environ, "IMAGE": "ghcr.io/tuna-os/tromso", "DIGEST": digest},
            )
            assert result.returncode == 0, result.stderr
            signed.append(result.stdout.strip())
    assert signed == [f"sign --yes ghcr.io/tuna-os/tromso@{digest}"] * 2
