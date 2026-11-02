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


def test_workflow_cancellation_preserves_expensive_image_builds():
    """Supersede cheap checks, but let long builds finish and save their CAS."""
    workflows = REPO / ".github" / "workflows"
    for name, policy in (
        ("test.yml", "true"),
        ("build-iso.yml", "true"),
        ("build-tromso-multirunner.yml", "false"),
    ):
        text = (workflows / name).read_text()
        assert "concurrency:" in text, f"{name} lacks a concurrency group"
        assert re.search(rf"cancel-in-progress:\s*{policy}", text), name

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


def test_webkit_framework_condition_handles_unset_link_target():
    """WebKit 2.53.1's empty variable expansion stopped main in CMake (#392)."""
    sources = (REPO / "elements/sdk/webkitgtk.inc").read_text()
    patch = "patches/webkitgtk/fix-empty-linked-into.patch"
    assert f"path: {patch}" in sources
    correction = (REPO / patch).read_text()
    assert (
        "+        if ((NOT _linked_into) OR (framework STREQUAL _linked_into) "
        "OR (NOT _linked_into IN_LIST ${_target}_FRAMEWORKS))"
    ) in correction


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
        assert step.count("rclone copyto") == 3
    assert "steps.publish_dated.outcome == 'success'" in steps[latest]
    assert "tromso-live-latest" not in steps[dated]
    assert steps[dated].count("--immutable") == 3
    for suffix in ('iso"', 'iso-CHECKSUM"', 'iso.bundle"'):
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
    for fail_at in range(1, 8):
        log.write_text("")
        result = subprocess.run(
            ["bash", "-e", "-c", mock + script],
            env={**os.environ, "UPLOAD_LOG": str(log), "FAIL_AT": str(fail_at), "R2_BUCKET": "test"},
            capture_output=True, text=True,
        )
        assert (result.returncode == 0) == (fail_at == 7), result.stderr
        assert len(log.read_text().splitlines()) == min(fail_at, 6)


def test_offline_media_is_an_oci_layout_not_a_vfs_graphroot():
    recipe = (REPO / "iso.justfile").read_text()
    producer = (REPO / "scripts/embed-oci-payload.sh").read_text()
    driver = (REPO / "scripts/lib-install-qemu.sh").read_text()
    assert "PAYLOAD_PINNED" in recipe
    assert "scripts/embed-oci-payload.sh" in recipe
    assert "SQUASHFS_STORAGE" not in recipe
    assert 'LAYOUT_PATH=/usr/lib/tunaos/payload' in producer
    assert 'platformManifestDigest: $manifest' in producer
    assert 'targetImgref: $image' in producer
    assert '"${LAYOUT}/index.json"' in producer
    assert 'INSTALL_IMAGE=""' in driver
    assert 'docker://${PAYLOAD_IMAGE}' not in driver
    assert "offline-stores" not in CONFIGURE_LIVE


def test_live_iso_preserves_root_mountpoints_and_matching_label():
    recipe = (REPO / "iso.justfile").read_text()
    assert "-wildcards -e 'proc/*' -e 'sys/*' -e 'dev/*'" in recipe
    hook = (SRC / "dracut/95tromso-isofile/tromso-isofile.sh").read_text()
    assert 'LABEL="TROMSO_LIVE"' in hook


def test_iso_signing_publishes_sigstore_bundle():
    workflow = (REPO / ".github/workflows/build-iso.yml").read_text()
    assert 'cosign sign-blob --yes --bundle "${ISO}.bundle"' in workflow
    assert "--output-signature" not in workflow
    assert "--output-certificate" not in workflow
    assert "tromso-live-latest.iso.bundle" in workflow


def test_installed_identity_selects_shipped_tromso_artwork():
    identity = (REPO / "elements/oci/os-release.bst").read_text()
    assert 'IMAGE_PRETTY_NAME: "TunaOS Tromsø"' in identity
    assert "ID_LIKE" not in identity
    brand = (REPO / "elements/tromso/branding.bst").read_text()
    assert "Image=Tromso" in brand
    assert "wallpapers/Tromso/contents/images/1920x1080.png" in brand
    defaults = REPO / "files/tromso/aurora-common/system_files/shared/usr/share/kde-settings/kde-profile/default/xdg"
    about = (defaults / "kcm-about-distrorc").read_text()
    assert "Name=TunaOS Tromsø" in about
    assert "tromso-logo.svg" in about
    assert "Aurora" not in (defaults / "kscreenlockerrc").read_text()


def test_manual_candidate_publish_never_changes_channel_aliases():
    workflow = (REPO / ".github/workflows/build-tromso-multirunner.yml").read_text()
    candidate = workflow.split('if [ "${{ inputs.publish_candidate }}" = "true" ]; then', 1)[1].split("elif", 1)[0]
    assert 'TAGS="${{ github.sha }}"' in candidate
    assert "latest" not in candidate and "nightly" not in candidate
    assert "path: ~/.cache/buildstream/sources" in workflow
    assert "/cache/sources" not in workflow
