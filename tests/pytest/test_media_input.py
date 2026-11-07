"""Exercise the producer boundary with real OCI archives and transported blobs."""

import gzip
import hashlib
import io
import json
from pathlib import Path
import shutil
import subprocess
import tarfile

import pytest

REPO = Path(__file__).resolve().parents[2]


def run(*args, **kwargs):
    return subprocess.run(args, check=True, capture_output=True, text=True, **kwargs)


def blob(layout, raw, media_type):
    digest = hashlib.sha256(raw).hexdigest()
    path = layout / "blobs/sha256" / digest
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(raw)
    return {"mediaType": media_type, "digest": "sha256:" + digest, "size": len(raw)}


@pytest.fixture
def transported(tmp_path):
    if not shutil.which("skopeo") or not shutil.which("jq"):
        pytest.skip("real OCI transport requires skopeo and jq")
    layout = tmp_path / "source"
    layout.mkdir()
    tar = io.BytesIO()
    with tarfile.open(fileobj=tar, mode="w") as archive:
        info = tarfile.TarInfo("payload.txt")
        content = b"immutable media transport regression\n"
        info.size = len(content)
        archive.addfile(info, io.BytesIO(content))
    layer = blob(layout, gzip.compress(tar.getvalue(), mtime=0), "application/vnd.oci.image.layer.v1.tar+gzip")
    config = blob(layout, json.dumps({"os": "linux", "architecture": "amd64", "rootfs": {"type": "layers", "diff_ids": ["sha256:" + hashlib.sha256(tar.getvalue()).hexdigest()]}}).encode(), "application/vnd.oci.image.config.v1+json")
    manifest = blob(layout, json.dumps({"schemaVersion": 2, "mediaType": "application/vnd.oci.image.manifest.v1+json", "config": config, "layers": [layer]}).encode(), "application/vnd.oci.image.manifest.v1+json")
    (layout / "oci-layout").write_text('{"imageLayoutVersion":"1.0.0"}')
    (layout / "index.json").write_text(json.dumps({"schemaVersion": 2, "manifests": [manifest]}))
    archive = tmp_path / "payload.oci.tar"
    run("skopeo", "copy", "--preserve-digests", f"oci:{layout}", f"oci-archive:{archive}:payload")
    root = tmp_path / "root"
    for directory in ("bootc-installer", "tuna-installer"):
        config_dir = root / "etc" / directory
        config_dir.mkdir(parents=True)
        shutil.copy(REPO / "tromso/src/etc/bootc-installer/images.json", config_dir)
    shutil.copy(REPO / "tromso/src/etc/bootc-installer/recipe.json", root / "etc/bootc-installer")
    image = "ghcr.io/tuna-os/tromso@" + manifest["digest"]
    return root, archive, image, manifest, layer


def embed(transported, image=None):
    root, archive, selected, _, _ = transported
    run("bash", str(REPO / "scripts/embed-oci-payload.sh"), f"oci-archive:{archive}:payload", image or selected, str(root))
    return json.loads((root / "etc/bootc-installer/media-input.json").read_text())


def test_transport_preserves_candidate_bytes_and_update_identity(transported):
    root, _, image, manifest, layer = transported
    media = embed(transported)
    assert media["image"] == image
    assert media["targetImgref"] == "ghcr.io/tuna-os/tromso:latest"
    assert media["platformManifestDigest"] == manifest["digest"]
    assert media["platform"] == "linux/amd64"
    assert "qualificationID" not in media
    layout = root / "usr/lib/tunaos/payload"
    for desc in (manifest, layer):
        raw = (layout / "blobs/sha256" / desc["digest"].split(":")[1]).read_bytes()
        assert "sha256:" + hashlib.sha256(raw).hexdigest() == desc["digest"]
    for directory in ("bootc-installer", "tuna-installer"):
        catalog = json.loads((root / "etc" / directory / "images.json").read_text())
        assert catalog["default_image"] == image
        assert {entry["imgref"] for entry in catalog["images"]} == {image}
    recipe = json.loads((root / "etc/bootc-installer/recipe.json").read_text())
    assert recipe["imgref"] == image
    assert "local_imgref" not in recipe


def test_transport_refuses_different_candidate(transported):
    with pytest.raises(subprocess.CalledProcessError) as failure:
        embed(transported, "ghcr.io/tuna-os/tromso@sha256:" + "0" * 64)
    assert "Transported manifest differs" in failure.value.stderr
    assert not (transported[0] / "etc/bootc-installer/media-input.json").exists()


@pytest.mark.parametrize("image", ["ghcr.io/tuna-os/tromso:latest", "ghcr.io/tuna-os/tromso@sha256:invalid"])
def test_transport_requires_immutable_candidate(transported, image):
    with pytest.raises(subprocess.CalledProcessError) as failure:
        embed(transported, image)
    assert "Payload must name a platform manifest by digest" in failure.value.stderr
    assert not (transported[0] / "etc/bootc-installer/media-input.json").exists()
