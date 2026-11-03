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


def test_github_actions_use_immutable_references():
    """Remote actions and reusable workflows must not execute mutable tags."""
    for path in (REPO / ".github").rglob("*.y*ml"):
        for ref in re.findall(r"^\s*(?:-\s*)?uses:\s*([^\s#]+)", path.read_text(), re.M):
            if ref.startswith("./"):
                continue
            if ref.startswith("docker://"):
                assert re.fullmatch(r"docker://[^@]+@sha256:[0-9a-f]{64}", ref), (path, ref)
            else:
                assert re.fullmatch(r"[^@]+@[0-9a-f]{40}", ref), (path, ref)


def test_workflows_declare_top_level_permissions():
    """Job overrides must not leave other jobs with repository defaults (#321)."""
    for workflow in sorted((REPO / ".github/workflows").glob("*.y*ml")):
        assert re.search(r"^permissions:", workflow.read_text(), re.MULTILINE), workflow.name

def test_release_workflows_enforce_guard():
    import yaml

    for workflow, jobs in [('build-tromso-multirunner.yml', ['build_final', 'build_final_aarch64']),
                           ('build-iso.yml', ['build-and-publish'])]:
        data = yaml.safe_load((REPO / '.github/workflows' / workflow).read_text())
        for job in jobs:
            steps = data['jobs'][job]['steps']
            checks = [i for i, step in enumerate(steps)
                      if 'check-release-keys.py --release' in step.get('run', '')]
            assert len(checks) == 2
            assert all('if' not in steps[i] or steps[i]['name'] == 'Push to GHCR' for i in checks)
            build = next(i for i, step in enumerate(steps)
                         if step.get('name') in ('Build Final Target', 'Build Live ISO'))
            assert checks[0] < build < checks[1]


def test_python_ci_installs_workflow_parser():
    """Workflow invariants need PyYAML even on a clean Python runner (#449)."""
    import shlex
    import yaml

    workflow = yaml.safe_load((REPO / '.github/workflows/test.yml').read_text())
    steps = workflow['jobs']['pytest']['steps']
    install = next(step['run'] for step in steps if step.get('name') == 'Install dependencies')
    assert 'pyyaml' in shlex.split(install.lower())


def _media_fixture(root, architecture="amd64"):
    import hashlib
    import json

    layout = root / "usr/share/tromso/payload"
    blobs = layout / "blobs/sha256"
    blobs.mkdir(parents=True)

    def blob(value):
        data = json.dumps(value).encode()
        digest = hashlib.sha256(data).hexdigest()
        (blobs / digest).write_bytes(data)
        return {"digest": "sha256:" + digest, "size": len(data)}

    config = blob({"os": "linux", "architecture": architecture})
    manifest = blob({"schemaVersion": 2, "config": config, "layers": []})
    (layout / "index.json").write_text(json.dumps({
        "schemaVersion": 2, "manifests": [manifest],
    }))
    return layout, manifest, config


def test_iso_media_receipt_identifies_exported_payload(tmp_path):
    """The installer binds the exported bytes, not the registry's moving tag."""
    import json
    import subprocess

    for architecture in ("amd64", "arm64"):
        root = tmp_path / architecture
        _, manifest, config = _media_fixture(root, architecture)
        image = "ghcr.io/tuna-os/tromso:latest"
        subprocess.run([
            "python3", str(REPO / "scripts/write-media-input.py"), str(root), image,
        ], check=True)
        receipt = json.loads((root / "etc/bootc-installer/media-input.json").read_text())
        assert receipt["schemaVersion"] == 1
        assert receipt["image"] == receipt["targetImgref"] == image
        assert receipt["platformManifestDigest"] == manifest["digest"]
        assert receipt["configDigest"] == config["digest"]
        assert receipt["platform"] == "linux/" + architecture
        assert receipt["ociLayoutPath"] == "/run/tromso/payload"


def test_iso_media_receipt_rejects_corrupt_metadata(tmp_path):
    import subprocess

    layout, manifest, _ = _media_fixture(tmp_path)
    # Same length, wrong hash: size checks alone must not authorize a receipt.
    path = layout / "blobs/sha256" / manifest["digest"][7:]
    path.write_bytes(b" " * manifest["size"])
    result = subprocess.run([
        "python3", str(REPO / "scripts/write-media-input.py"), str(tmp_path), "image:latest",
    ], capture_output=True, text=True)
    assert result.returncode != 0
    assert "does not match descriptor" in result.stderr
    assert not (tmp_path / "etc/bootc-installer/media-input.json").exists()


def test_iso_binds_media_receipt_before_installer_starts():
    """Live media requires both a receipt and an actually read-only OCI mount."""
    import json

    assembly = (REPO / "iso.justfile").read_text()
    assert 'PAYLOAD_LAYOUT=' in assembly
    assert 'usr/share/tromso/payload' in assembly
    assert 'oci:/payload:payload' in assembly
    assert '--dest-compress-format gzip --dest-force-compress-format' in assembly
    assert assembly.index('python3 scripts/write-media-input.py') < assembly.index('        mksquashfs ')
    assert 'What=/usr/share/tromso/payload' in CONFIGURE_LIVE
    assert 'Where=/run/tromso/payload' in CONFIGURE_LIVE
    assert 'Options=bind,ro' in CONFIGURE_LIVE
    assert 'Before=display-manager.service' in CONFIGURE_LIVE
    assert 'Requires=display-manager.service run-tromso-payload.mount' in CONFIGURE_LIVE
    assert 'systemctl enable run-tromso-payload.mount' in CONFIGURE_LIVE
    recipe = json.loads((SRC / "etc/bootc-installer/recipe.json").read_text())
    assert recipe['local_imgref'] == 'oci:/run/tromso/payload'
    qemu = (REPO / 'scripts/lib-install-qemu.sh').read_text()
    assert 'INSTALL_IMAGE=""' in qemu
    assert 'test -r /etc/bootc-installer/media-input.json' in qemu
    assert 'INSTALL_IMAGE="docker://' not in qemu
