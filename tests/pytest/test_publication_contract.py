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


class TestPublicationWorkflowsContract:
    """Contract assertions on workflow definitions and architecture configurations."""

    def test_reusable_workflow_declares_typed_inputs(self):
        content = yaml.safe_load((WORKFLOWS / "build-final.yml").read_text())
        on_block = content.get("on") or content.get(True, {})
        assert "workflow_call" in on_block
        inputs = on_block["workflow_call"].get("inputs", {})

        expected_inputs = {
            "architecture": "string",
            "runner": "string",
            "cache_suffix": "string",
            "tag_suffix": "string",
            "channel_ownership": "boolean",
            "final_target": "string",
            "matrix_keys": "string",
            "cache_keys": "string",
            "push_image": "boolean",
            "enable_remote_execution": "boolean",
        }
        for name, expected_type in expected_inputs.items():
            assert name in inputs, f"missing expected input '{name}' in build-final.yml"
            assert inputs[name].get("type") == expected_type, (
                f"input '{name}' expected type {expected_type}, got {inputs[name].get('type')}"
            )

    def test_reusable_workflow_has_required_permissions(self):
        content = yaml.safe_load((WORKFLOWS / "build-final.yml").read_text())
        job = content["jobs"]["build_final"]
        perms = job.get("permissions", {})
        assert perms.get("packages") == "write"
        assert perms.get("id-token") == "write"
        assert perms.get("security-events") == "write"
        assert perms.get("contents") == "read"

    def test_multirunner_architecture_jobs_delegate_to_reusable_workflow(self):
        content = yaml.safe_load((WORKFLOWS / "build-tromso-multirunner.yml").read_text())
        jobs = content.get("jobs", {})

        assert "build_final" in jobs
        assert "build_final_aarch64" in jobs

        # Both jobs must call the repository-owned reusable workflow
        assert jobs["build_final"].get("uses") == "./.github/workflows/build-final.yml"
        assert jobs["build_final_aarch64"].get("uses") == "./.github/workflows/build-final.yml"

        # Check inputs for x86_64
        x86_with = jobs["build_final"].get("with", {})
        assert x86_with.get("architecture") == "x86_64"
        assert x86_with.get("channel_ownership") is True
        assert x86_with.get("tag_suffix") == ""
        assert x86_with.get("cache_suffix") == ""

        # Check inputs for aarch64
        arm_with = jobs["build_final_aarch64"].get("with", {})
        assert arm_with.get("architecture") == "aarch64"
        assert arm_with.get("channel_ownership") is False
        assert arm_with.get("tag_suffix") == "-aarch64"
        assert arm_with.get("cache_suffix") == "-aarch64"

    def test_no_duplicated_steps_in_multirunner(self):
        """multirunner jobs must be thin callers without inline publication steps."""
        multi_text = (WORKFLOWS / "build-tromso-multirunner.yml").read_text()
        content = yaml.safe_load(multi_text)
        jobs = content.get("jobs", {})

        for job_id in ("build_final", "build_final_aarch64"):
            assert "steps" not in jobs[job_id], f"{job_id} must not have inline steps"

        # Neither cosign sign nor trivy nor bst build should be in multirunner anymore
        assert "cosign sign" not in multi_text
        assert "aquasecurity/trivy-action" not in multi_text
