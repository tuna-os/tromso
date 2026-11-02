"""Invariants across the live-ISO build scripts.

These cover shipped bug classes, command failure handling and real OCI
conversion with native skopeo. No OS build or running container is needed.
"""

import os
import re
from pathlib import Path

import pytest

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


@pytest.mark.parametrize("update", [
    "ghcr.io/tuna-os/tromso:qualification",
    "ghcr.io/tuna-os/tromso:stable",
    "ghcr.io/tuna-os/tromso@sha256:" + "a" * 64,
])
def test_media_producer_copies_and_binds_a_real_oci_layout(tmp_path, update):
    """Exercise skopeo conversion and verify the bytes fisherman will consume."""
    import gzip
    import hashlib
    import io
    import json
    import subprocess
    import tarfile

    source = tmp_path / "source"
    blobs = source / "blobs/sha256"
    blobs.mkdir(parents=True)

    def blob(data, media_type):
        digest = hashlib.sha256(data).hexdigest()
        (blobs / digest).write_bytes(data)
        return {"mediaType": media_type, "digest": f"sha256:{digest}", "size": len(data)}

    archive = io.BytesIO()
    with tarfile.open(fileobj=archive, mode="w") as tar:
        entry = tarfile.TarInfo("proof")
        entry.size = 5
        tar.addfile(entry, io.BytesIO(b"media"))
    layer = archive.getvalue()
    config = blob(json.dumps({
        "os": "linux", "architecture": "amd64",
        "rootfs": {"type": "layers", "diff_ids": ["sha256:" + hashlib.sha256(layer).hexdigest()]},
    }).encode(), "application/vnd.oci.image.config.v1+json")
    manifest = blob(json.dumps({
        "schemaVersion": 2, "mediaType": "application/vnd.oci.image.manifest.v1+json",
        "config": config, "layers": [blob(layer, "application/vnd.oci.image.layer.v1.tar")],
    }).encode(), "application/vnd.oci.image.manifest.v1+json")
    (source / "oci-layout").write_text('{"imageLayoutVersion":"1.0.0"}')
    (source / "index.json").write_text(json.dumps({"schemaVersion": 2, "manifests": [manifest]}))
    root = tmp_path / "root"
    (root / "etc/bootc-installer").mkdir(parents=True)
    for name in ("recipe.json", "images.json"):
        (root / "etc/bootc-installer" / name).write_bytes(
            (SRC / "etc/bootc-installer" / name).read_bytes()
        )
    subprocess.run(
        ["bash", str(REPO / "scripts/embed-oci-payload.sh"), f"oci:{source}", update, str(root)],
        check=True, capture_output=True, text=True,
    )
    media = json.loads((root / "etc/bootc-installer/media-input.json").read_text())
    assert media["image"] == media["targetImgref"] == update
    assert media["platform"] == "linux/amd64"
    layout = root / media["ociLayoutPath"].lstrip("/")
    selected = json.loads((layout / "index.json").read_text())["manifests"][0]
    assert media["platformManifestDigest"] == selected["digest"]
    output_manifest = json.loads((layout / "blobs/sha256" / selected["digest"][7:]).read_text())
    for descriptor in [selected, output_manifest["config"], *output_manifest["layers"]]:
        data = (layout / "blobs/sha256" / descriptor["digest"][7:]).read_bytes()
        assert len(data) == descriptor["size"]
        assert "sha256:" + hashlib.sha256(data).hexdigest() == descriptor["digest"]
    compressed = layout / "blobs/sha256" / output_manifest["layers"][0]["digest"][7:]
    assert gzip.decompress(compressed.read_bytes()) == layer
    assert json.loads((root / "etc/bootc-installer/recipe.json").read_text())["imgref"] == update
    catalog = json.loads((root / "etc/tuna-installer/images.json").read_text())
    assert catalog["default_image"] == catalog["images"][0]["imgref"] == update


def test_media_producer_refuses_missing_local_source(tmp_path):
    import subprocess

    root = tmp_path / "root"
    result = subprocess.run(
        ["bash", str(REPO / "scripts/embed-oci-payload.sh"), f"oci:{tmp_path}/absent",
         "ghcr.io/tuna-os/tromso:qualification", str(root)],
        capture_output=True, text=True,
    )
    assert result.returncode != 0
    assert not (root / "etc/bootc-installer/media-input.json").exists()
