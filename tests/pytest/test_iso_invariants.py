"""Invariants across the live-ISO build scripts.

Each assertion here encodes a bug class that actually shipped (see
docs/ci-and-iso-pipeline.md troubleshooting table). Cheap to run, no
containers needed — pure source inspection.
"""

import os
import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
TARGET = "tromso"
INSTALLER_APP = "org.tunaos.InstallerKde"
READY_MARKER = "TROMSO_LIVE_READY"

SRC = REPO / TARGET / "src"
INSTALL_FLATPAKS = (SRC / "install-flatpaks.sh").read_text()
CONFIGURE_LIVE = (SRC / "configure-live.sh").read_text()
CONTAINERFILE = (REPO / TARGET / "Containerfile").read_text()


def test_installer_app_id_consistent():
    """install-flatpaks.sh and configure-live.sh must bake and wire the SAME
    installer app ID — they once drifted apart and the installer never
    launched (autostart + fisherman symlink pointed at an uninstalled app)."""
    assert INSTALLER_APP in INSTALL_FLATPAKS
    assert INSTALLER_APP in CONFIGURE_LIVE
    for stale in ("org.bootcinstaller.Installer", "org.xfceinstaller", "org.kdeinstaller"):
        assert stale not in INSTALL_FLATPAKS, f"stale installer id {stale} in install-flatpaks.sh"
        assert stale not in CONFIGURE_LIVE.replace(
            # the polkit action id is shared and fine
            "org.tunaos.Installer.install", ""
        ), f"stale installer id {stale} in configure-live.sh"


def test_live_ready_marker_present():
    """CI's boot gate greps the serial log for the ready marker; if
    configure-live.sh stops printing it every ISO 'fails' to boot."""
    assert READY_MARKER in CONFIGURE_LIVE


def test_payload_ref_points_at_our_image():
    ref = (REPO / TARGET / "payload_ref").read_text().strip()
    assert ref.startswith(f"ghcr.io/tuna-os/{TARGET}:"), ref


def test_polkit_action_id_is_shared_constant():
    """All four frontends escalate via the shared action id; renaming it
    breaks every installer at once."""
    assert "org.tunaos.Installer.install" in CONFIGURE_LIVE


def test_fisherman_symlink_target():
    """Frontends run `pkexec /usr/local/bin/fisherman`; the symlink must be
    created and the polkit annotate path must match."""
    assert "/usr/local/bin/fisherman" in CONFIGURE_LIVE
    assert re.search(r"annotate.*exec\.path.*>/usr/local/bin/fisherman<", CONFIGURE_LIVE)


def test_containerfile_wires_this_targets_dracut_module():
    assert f"95{TARGET}-isofile" in CONTAINERFILE
    module_dir = REPO / TARGET / "src" / "dracut" / f"95{TARGET}-isofile"
    assert (module_dir / "module-setup.sh").exists()
    setup = (module_dir / "module-setup.sh").read_text()
    hook = re.search(r'inst_hook initqueue \d+ "\$moddir/([^"]+)"', setup)
    assert hook, "module-setup.sh must install an initqueue hook"
    assert (module_dir / hook.group(1)).exists(), f"hook script {hook.group(1)} missing"


def test_single_root_justfile():
    """just >=1.30 hard-errors when both justfile and Justfile exist — this
    killed every CI invocation once. Extra recipes belong in iso.justfile."""
    assert (REPO / "Justfile").exists()
    assert not (REPO / "justfile").exists(), "second root justfile reintroduced"
    assert 'import "iso.justfile"' in (REPO / "Justfile").read_text()


def test_gitignore_does_not_swallow_target_containerfile():
    """An unanchored 'Containerfile' rule once silently dropped
    <target>/Containerfile from the repo."""
    gitignore = (REPO / ".gitignore").read_text() if (REPO / ".gitignore").exists() else ""
    for line in gitignore.splitlines():
        line = line.strip()
        assert line != "Containerfile", (
            "unanchored Containerfile gitignore rule — use /Containerfile"
        )


def test_no_quiet_karg_in_elements():
    """CI serial-log assertions depend on boot messages; a kargs.d drop-in
    adding 'quiet' would blind every boot gate."""
    for bst in (REPO / "elements").rglob("*.bst"):
        text = bst.read_text()
        if "kargs.d" in text:
            assert '"quiet"' not in text, f"{bst} adds quiet karg"


def test_high_frequency_workflows_cancel_superseded_runs():
    """Push bursts once left stale checks and image/ISO builds queued for
    hours. Newer work on the same ref must replace those obsolete runs."""
    workflows = REPO / ".github" / "workflows"
    names = (
        "test.yml",
        "build-iso.yml",
        "build-tromso-multirunner.yml",
    )
    for name in names:
        text = (workflows / name).read_text()
        assert "concurrency:" in text, f"{name} lacks a concurrency group"
        assert re.search(
            r"cancel-in-progress:\s*true", text
        ), f"{name} queues superseded same-ref runs"

    iso = (workflows / "build-iso.yml").read_text()
    assert "github.event.workflow_run.head_branch || github.ref_name" in iso, (
        "push and workflow_run ISO triggers must normalize to the same branch key"
    )


def test_multi_runner_is_the_only_buildstream_image_builder():
    """Prevent a second, non-convergent image builder from returning."""
    workflows = REPO / ".github" / "workflows"
    names = {path.name for path in workflows.glob("*.yml")}
    assert "build-tromso-multirunner.yml" in names
    assert "build-buildgrid.yml" not in names
    assert "pr-build-changed.yml" not in names

    multi = (workflows / "build-tromso-multirunner.yml").read_text()
    assert "multirunner:" in multi
    assert "build_final:" in multi
    assert "just export" in multi


def test_e2e_install_workflows_do_not_run_pr_code_with_write_token():
    """tromso#270: the PR-triggered install e2e workflows built and ran the
    PR's own Justfile/iso.justfile/tromso recipes as root while holding
    `contents: write` (and with the GITHUB_TOKEN in root's podman auth store).
    The job that runs that code must be read-only; write scopes belong to a
    separate `report` job that runs no repository code."""
    workflows = REPO / ".github" / "workflows"
    for name, job in (
        ("test-plain-install.yml", "plain-e2e"),
        ("test-luks-install.yml", "luks-e2e"),
    ):
        text = "".join(
            line
            for line in (workflows / name).read_text().splitlines(keepends=True)
            if not line.lstrip().startswith("#")
        )
        top, jobs = text.split("\njobs:\n", 1)
        jobs = "\n" + jobs
        perms = re.search(r"^permissions:\n((?:  .*\n)+)", top, re.M)
        assert perms, f"{name} lacks a workflow-level permissions block"
        assert "write" not in perms.group(1), (
            f"{name} grants a write scope at workflow level; it executes PR code as root"
        )
        assert f"\n  {job}:\n" in jobs and "\n  report:\n" in jobs, name

        run_job, report_job = jobs.split("\n  report:\n", 1)
        assert "write" not in run_job, f"{name}: {job} job must stay read-only"
        assert "ghcr.io" not in run_job and "podman login" not in run_job, (
            f"{name}: the token must not be written to root's registry auth store"
        )
        assert "contents: write" in report_job, name
        assert "actions/checkout" not in report_job, (
            f"{name}: the write-scoped report job must not check out PR code"
        )
        assert "just " not in report_job and "sudo" not in report_job, (
            f"{name}: the write-scoped report job must not run repository recipes"
        )
