"""Run scripts/embed-oci-payload.sh on a real OCI archive.

A fake `podman` runs the helper's skopeo command on the host, so the test
needs skopeo and jq but no container runtime.
"""

import gzip
import hashlib
import io
import json
import shutil
import subprocess
import tarfile
from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parents[2]
CANDIDATE = "ghcr.io/tuna-os/tromso@sha256:" + "c" * 64
TRACKING = "ghcr.io/tuna-os/tromso:latest"

FAKE_PODMAN = r"""#!/bin/bash
# Map the container mounts to host paths and run the command on the host.
set -eu
archive='' layout='' cmd=''
while [ $# -gt 0 ]; do
    case "$1" in
        -v) case "$2" in
                *:/payload.oci.tar:ro) archive=${2%:/payload.oci.tar:ro} ;;
                *:/layout) layout=${2%:/layout} ;;
            esac
            shift 2 ;;
        -c) cmd=$2; shift 2 ;;
        *) shift ;;
    esac
done
cmd=${cmd//\/payload.oci.tar/$archive}
cmd=${cmd//oci:\/layout:/oci:$layout:}
exec sh -c "$cmd"
"""


def blob(layout, raw, media_type):
    digest = hashlib.sha256(raw).hexdigest()
    path = layout / "blobs/sha256" / digest
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(raw)
    return {"mediaType": media_type, "digest": "sha256:" + digest, "size": len(raw)}


def archive(tmp_path, name):
    """Write a one-layer linux/amd64 image as an OCI archive called `name`."""
    layout = tmp_path / "source"
    layout.mkdir()
    tar = io.BytesIO()
    with tarfile.open(fileobj=tar, mode="w") as out:
        info = tarfile.TarInfo("payload.txt")
        content = b"release candidate payload\n"
        info.size = len(content)
        out.addfile(info, io.BytesIO(content))
    diff_id = "sha256:" + hashlib.sha256(tar.getvalue()).hexdigest()
    layer = blob(layout, gzip.compress(tar.getvalue(), mtime=0),
                 "application/vnd.oci.image.layer.v1.tar+gzip")
    config = blob(layout, json.dumps({
        "os": "linux", "architecture": "amd64",
        "rootfs": {"type": "layers", "diff_ids": [diff_id]}}).encode(),
        "application/vnd.oci.image.config.v1+json")
    manifest = blob(layout, json.dumps({
        "schemaVersion": 2, "mediaType": "application/vnd.oci.image.manifest.v1+json",
        "config": config, "layers": [layer]}).encode(),
        "application/vnd.oci.image.manifest.v1+json")
    (layout / "oci-layout").write_text('{"imageLayoutVersion":"1.0.0"}')
    (layout / "index.json").write_text(json.dumps({"schemaVersion": 2, "manifests": [manifest]}))
    path = tmp_path / "payload.oci.tar"
    subprocess.run(["skopeo", "copy", f"oci:{layout}", f"oci-archive:{path}:{name}"],
                   check=True, capture_output=True)
    return path


@pytest.fixture
def embed(tmp_path):
    if not shutil.which("skopeo") or not shutil.which("jq"):
        pytest.skip("the embed helper needs skopeo and jq")
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    (bin_dir / "podman").write_text(FAKE_PODMAN)
    (bin_dir / "podman").chmod(0o755)
    root = tmp_path / "root"
    for directory in ("bootc-installer", "tuna-installer"):
        (root / "etc" / directory).mkdir(parents=True)
        shutil.copy(REPO / "tromso/src/etc/bootc-installer/images.json", root / "etc" / directory)
    shutil.copy(REPO / "tromso/src/etc/bootc-installer/recipe.json", root / "etc/bootc-installer")

    def run(image):
        payload = archive(tmp_path, image)
        subprocess.run(
            ["bash", str(REPO / "scripts/embed-oci-payload.sh"), str(payload), image,
             str(root), "tools-image"],
            check=True, capture_output=True, text=True,
            env={"PATH": f"{bin_dir}:/usr/bin:/bin:{shutil.which('skopeo').rsplit('/', 1)[0]}"})
        return root, json.loads((root / "etc/bootc-installer/media-input.json").read_text())

    return run


def test_candidate_digest_binds_receipt_and_installers(embed):
    root, media = embed(CANDIDATE)
    assert media["image"] == CANDIDATE
    assert media["targetImgref"] == TRACKING  # day-2 updates keep the recipe ref
    assert media["ociLayoutPath"] == "/run/rootfsbase/usr/lib/tunaos/payload"
    assert media["platform"] == "linux/amd64"
    layout = root / "usr/lib/tunaos/payload"
    index = json.loads((layout / "index.json").read_text())
    assert [m["digest"] for m in index["manifests"]] == [media["platformManifestDigest"]]
    manifest = (layout / "blobs/sha256" / media["platformManifestDigest"].split(":")[1]).read_bytes()
    assert "sha256:" + hashlib.sha256(manifest).hexdigest() == media["platformManifestDigest"]
    assert json.loads(manifest)["config"]["digest"] == media["configDigest"]
    # The graphical installer must request the image the receipt names.
    recipe = json.loads((root / "etc/bootc-installer/recipe.json").read_text())
    assert recipe["imgref"] == CANDIDATE
    for directory in ("bootc-installer", "tuna-installer"):
        catalog = json.loads((root / "etc" / directory / "images.json").read_text())
        assert catalog["default_image"] == CANDIDATE
        assert {entry["imgref"] for entry in catalog["images"]} == {CANDIDATE}


def test_channel_tag_keeps_installer_catalogs(embed):
    root, media = embed(TRACKING)
    assert media["image"] == media["targetImgref"] == TRACKING
    catalog = json.loads((root / "etc/bootc-installer/images.json").read_text())
    assert catalog == json.loads((REPO / "tromso/src/etc/bootc-installer/images.json").read_text())
