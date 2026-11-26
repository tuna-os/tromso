"""Contract tests for the Secure Boot layer of the publish job (#516).

The signature is not part of the BuildStream build. The publish path of
build-final.yml adds it as one layer with the tunaOS installer-medium/
secure-boot tooling, at a pinned commit, and then checks it with sbverify
and no key. These tests keep that wiring honest:

- only the publish condition (main or stable, push_image) reaches the key;
- the key is in the environment of exactly one step;
- the layer goes on before the push, so cosign and promotion name the
  digest that has it;
- the key-free check follows the signing step;
- the 7-stage installer workflow is called from tuna-os/tunaOS, not copied,
  and does not publish by default.
"""

import re
from pathlib import Path

import yaml

REPO = Path(__file__).resolve().parents[2]
WORKFLOWS = REPO / ".github" / "workflows"
CALLEE = WORKFLOWS / "build-final.yml"
INSTALLER = WORKFLOWS / "image-installer.yml"
SECRETS = ("TUNAOS_SB_KEY", "TUNAOS_SB_CERT")
PUBLISH = "(github.ref == 'refs/heads/main' || github.ref == 'refs/heads/stable') && inputs.push_image"
SHA = re.compile(r"[0-9a-f]{40}")


def _steps():
    return yaml.safe_load(CALLEE.read_text())["jobs"]["build_final"]["steps"]


def _index(steps, name):
    return next(i for i, step in enumerate(steps) if step.get("name") == name)


def test_only_one_step_gets_the_key_and_only_on_the_publish_path():
    steps = _steps()
    holders = [
        step
        for step in steps
        if any(f"secrets.{name}" in str(step.get("env", {})) for name in SECRETS)
    ]
    assert [step["name"] for step in holders] == ["Add the Secure Boot layer"]
    for name in (
        "Checkout the Secure Boot tooling",
        "Add the Secure Boot layer",
        "Verify the Secure Boot layer",
    ):
        condition = steps[_index(steps, name)]["if"]
        assert PUBLISH in condition, name
        assert "inputs.architecture == 'x86_64'" in condition, name
    # No other workflow file reads the secrets, except the caller that
    # passes them to build-final.yml by name.
    for path in WORKFLOWS.glob("*.y*ml"):
        text = path.read_text()
        if path.name == "build-final.yml":
            continue
        for name in SECRETS:
            uses = re.findall(rf"^.*secrets\.{name}.*$", text, re.MULTILINE)
            assert all(
                line.strip() == f"{name}: ${{{{ secrets.{name} }}}}" for line in uses
            ), (path.name, uses)
            if uses:
                assert path.name == "build-tromso-multirunner.yml"


def test_the_layer_goes_on_after_the_export_and_before_the_push():
    steps = _steps()
    order = [
        _index(steps, name)
        for name in (
            "Export OCI image",
            "Checkout the Secure Boot tooling",
            "Add the Secure Boot layer",
            "Verify the Secure Boot layer",
            "Login to GHCR (podman)",
            "Push to GHCR",
        )
    ]
    assert order == sorted(order)
    sign = steps[_index(steps, "Add the Secure Boot layer")]["run"]
    verify = steps[_index(steps, "Verify the Secure Boot layer")]
    assert "image/sign-image.sh" in sign and "localhost/${IMAGE_REF}" in sign
    # A missing key must stop the publish; nothing may swallow the failure.
    assert "||" not in sign and "continue-on-error" not in str(
        steps[_index(steps, "Add the Secure Boot layer")]
    )
    assert "image/verify-image.sh" in verify["run"]
    assert "TUNAOS_SB" not in str(verify.get("env", {})) and "||" not in verify["run"]


def test_the_tooling_checkout_is_pinned_and_keeps_no_credentials():
    steps = _steps()
    checkout = steps[_index(steps, "Checkout the Secure Boot tooling")]["with"]
    assert checkout["repository"] == "tuna-os/tunaOS"
    assert SHA.fullmatch(checkout["ref"])
    assert checkout["persist-credentials"] is False
    # secureboot.py loads scripts/lib/tunaos_config.py from the same checkout.
    assert checkout["sparse-checkout"].split() == [
        "installer-medium/secure-boot",
        "scripts/lib",
    ]


def test_the_build_job_has_no_token_that_can_sign_a_release():
    # cosign stays in the caller; this job must not gain id-token.
    job = yaml.safe_load(CALLEE.read_text())["jobs"]["build_final"]
    assert "id-token" not in job["permissions"]


def test_installer_workflow_calls_tunaos_at_one_pinned_commit_and_does_not_publish_by_default():
    workflow = yaml.safe_load(INSTALLER.read_text())
    triggers = workflow[True]  # PyYAML reads the key `on` as True
    assert set(triggers) == {"workflow_dispatch"}
    assert triggers["workflow_dispatch"]["inputs"]["publish"]["default"] is False
    assert workflow["permissions"] == {}
    # The called workflow uses the group image-installer-<ref>. The same
    # group here is a deadlock, and the run fails at start.
    assert workflow["concurrency"]["group"].startswith("image-installer-caller-")
    job = workflow["jobs"]["e2e"]
    repo, _, ref = job["uses"].partition("@")
    assert repo == "tuna-os/tunaOS/.github/workflows/image-installer.yml"
    assert SHA.fullmatch(ref) and job["with"]["tunaos_ref"] == ref
    assert job["with"]["cell"] == "tromso:kde"
    assert job["with"]["dest"] == "ghcr.io/tuna-os/tromso-installer"
    assert "secrets" not in job


def test_the_document_states_the_limits():
    text = (REPO / "docs" / "secure-boot.md").read_text()
    for needle in (
        "initramfs",
        "command line",
        "MokManager",
        "TUNAOS_SB_KEY",
        "throwaway",
        "shim-x64-16.1-7",
    ):
        assert needle in text, needle
