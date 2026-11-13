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


def test_build_workflows_disable_checkout_credential_persistence():
    """Issue #382: build workflows must disable checkout credential persistence
    to prevent GITHUB_TOKEN exposure in .git/config."""
    for name in ("build-iso.yml", "build-tromso-multirunner.yml"):
        workflow_path = REPO / ".github" / "workflows" / name
        lines = workflow_path.read_text().splitlines()
        found = 0
        for idx, line in enumerate(lines):
            if re.search(r"uses:\s+actions/checkout", line):
                found += 1
                step_block = "\n".join(lines[idx:idx + 10])
                assert "persist-credentials: false" in step_block, (
                    f"actions/checkout step at {name}:{idx + 1} lacks persist-credentials: false"
                )
        assert found > 0, f"No actions/checkout steps found in {name}"


def _locked_actions():
    """Map each workflow path to the `owner/repo@tag` refs that
    .github/workflows/actions.lock pins to a commit (`gh actions-lock`)."""
    locked = {}
    workflow = None
    in_workflows = False
    lockfile = REPO / ".github" / "workflows" / "actions.lock"
    for line in lockfile.read_text().splitlines():
        if not line.startswith(" "):
            in_workflows = line.rstrip() == "workflows:"
            continue
        if not in_workflows:
            continue
        key = re.fullmatch(r" {4}'([^']+)':.*", line)
        if key:
            workflow = key.group(1)
            locked[workflow] = set()
            continue
        ref = re.fullmatch(r" {8}- '([^']+)'", line)
        if ref and workflow:
            locked[workflow].add(ref.group(1))
    return locked


def test_e2e_install_execution_is_read_only():
    """PR recipes must not receive write grants or persisted checkout credentials."""
    import yaml

    workflows = REPO / ".github/workflows"
    for name in ("test-plain-install.yml", "test-luks-install.yml"):
        workflow = yaml.safe_load((workflows / name).read_text())
        for job in workflow["jobs"].values():
            permissions = job.get("permissions", workflow["permissions"])
            assert all(value != "write" for value in permissions.values())
            for step in job["steps"]:
                if step.get("uses", "").startswith("actions/checkout@"):
                    assert step["with"]["persist-credentials"] is False
                assert "podman login" not in step.get("run", "")


def test_iso_publication_requires_verified_candidate():
    """Neither failed boots nor partial dated uploads may promote latest."""
    workflow = (REPO / ".github/workflows/build-iso.yml").read_text()
    steps = re.split(r"^      - name: ", workflow, flags=re.MULTILINE)
    boot = next(i for i, step in enumerate(steps) if step.startswith("Boot verification"))
    dated = next(i for i, step in enumerate(steps) if step.startswith("Publish dated ISO objects"))
    latest = next(i for i, step in enumerate(steps) if step.startswith("Promote latest ISO aliases"))
    assert boot < dated < latest
    assert "id: boot_verify" in steps[boot]
    assert "continue-on-error:" not in workflow
    publishers = [step for step in steps if "rclone copyto" in step]
    assert publishers == [steps[dated], steps[latest]]
    for step in publishers:
        assert "success() && steps.boot_verify.outcome == 'success'" in step
        assert "inputs.skip_upload != true" in step
        assert "github.event_name != 'pull_request'" in step
        assert step.count("rclone copyto") == 4
    assert "steps.publish_dated.outcome == 'success'" in steps[latest]
    assert "tromso-live-latest" not in steps[dated]
    assert steps[dated].count("--immutable") == 4
    for suffix in ('iso"', 'iso-CHECKSUM"', 'iso.sig"', 'iso.cert"'):
        assert f'tromso-live-latest.{suffix}' in steps[latest]


def test_iso_upload_failures_stop_publication(tmp_path):
    """Exercise the actual upload commands with every R2 request failing in turn."""
    import subprocess

    workflow = (REPO / ".github/workflows/build-iso.yml").read_text()
    steps = re.split(r"^      - name: ", workflow, flags=re.MULTILINE)
    scripts = [step.split("        run: |\n", 1)[1] for step in steps if "rclone copyto" in step]
    script = re.sub(r"\$\{\{.*?\}\}", "candidate", "\n".join(scripts))
    log = tmp_path / "uploads"
    mock = '''
    rclone() {
        count=$((count + 1))
        echo "$*" >> "$UPLOAD_LOG"
        [ "$count" -ne "$FAIL_AT" ]
    }
    count=0
    '''
    for fail_at in range(1, 10):
        log.write_text("")
        result = subprocess.run(
            ["bash", "-e", "-c", mock + script],
            env={**os.environ, "UPLOAD_LOG": str(log), "FAIL_AT": str(fail_at), "R2_BUCKET": "test"},
            capture_output=True, text=True,
        )
        assert (result.returncode == 0) == (fail_at == 9), result.stderr
        assert len(log.read_text().splitlines()) == min(fail_at, 8)


def test_github_actions_use_immutable_references():
    """Remote actions and reusable workflows must not execute mutable tags.

    A workflow may name an action by tag only when actions.lock pins that tag
    to a commit for the same workflow. Composite actions and cross-repo
    reusable workflows are outside the lockfile and stay SHA-pinned."""
    locked = _locked_actions()
    for path in (REPO / ".github").rglob("*.y*ml"):
        rel = path.relative_to(REPO).as_posix()
        for ref in re.findall(r"^\s*(?:-\s*)?uses:\s*([^\s#]+)", path.read_text(), re.M):
            if ref.startswith(("./", "$/")):
                continue
            if ref.startswith("docker://"):
                assert re.fullmatch(r"docker://[^@]+@sha256:[0-9a-f]{64}", ref), (path, ref)
            elif re.fullmatch(r"[^@]+@[0-9a-f]{40}", ref):
                continue
            else:
                assert "/.github/workflows/" not in ref, (path, ref)
                name, _, tag = ref.partition("@")
                action_repo = "/".join(name.split("/")[:2])
                assert f"{action_repo}@{tag}" in locked.get(rel, set()), (
                    f"{rel}: {ref} is neither SHA-pinned nor locked in actions.lock"
                )


def test_workflows_declare_top_level_permissions():
    """Job overrides must not leave other jobs with repository defaults (#321)."""
    for workflow in sorted((REPO / ".github/workflows").glob("*.y*ml")):
        assert re.search(r"^permissions:", workflow.read_text(), re.MULTILINE), workflow.name


def test_iso_publication_event_gates_fail_closed():
    """Evaluate actual publisher conditions for failed boots and unsupported events."""
    from itertools import product

    workflow = (REPO / ".github/workflows/build-iso.yml").read_text()
    steps = re.split(r"^      - name: ", workflow, flags=re.MULTILINE)
    publishers = [step for step in steps if "rclone copyto" in step]
    for step in publishers:
        condition = re.search(r"if:\s*(?:>-\s*)?\$\{\{(.*?)\}\}", step, re.S)[1]
        condition = " ".join(condition.split())
        alias = step.startswith("Promote latest ISO aliases")
        for boot, status, skip, event, dated in product(
            ("success", "failure", "cancelled", "skipped"), (True, False),
            (True, False), ("pull_request", "workflow_run", "workflow_dispatch"),
            ("success", "failure", "cancelled", "skipped"),
        ):
            evaluated = condition.replace("success()", repr(status))
            evaluated = evaluated.replace("steps.boot_verify.outcome", repr(boot))
            evaluated = evaluated.replace("steps.publish_dated.outcome", repr(dated))
            evaluated = evaluated.replace("inputs.skip_upload", repr(skip))
            evaluated = evaluated.replace("github.event_name", repr(event))
            admitted = eval(evaluated.replace("true", "True").replace("&&", " and "),
                            {"__builtins__": {}})
            expected = status and boot == "success" and not skip and event != "pull_request"
            assert admitted == (expected and (not alias or dated == "success"))
