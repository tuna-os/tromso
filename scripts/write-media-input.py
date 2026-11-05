#!/usr/bin/env python3
"""Bind the live installer to the OCI layout exported by skopeo."""

import hashlib
import json
from pathlib import Path
import re
import sys


def read_blob(layout, descriptor):
    digest = descriptor["digest"]
    if not re.fullmatch(r"sha256:[0-9a-f]{64}", digest):
        raise ValueError(f"invalid OCI digest: {digest}")
    data = (layout / "blobs" / "sha256" / digest.split(":")[1]).read_bytes()
    if len(data) != descriptor["size"] or hashlib.sha256(data).hexdigest() != digest[7:]:
        raise ValueError(f"OCI metadata does not match descriptor: {digest}")
    return json.loads(data)


def write_media_input(root, image):
    layout = root / "usr/share/tromso/payload"
    index = json.loads((layout / "index.json").read_text())
    # skopeo exports one platform. Reject ambiguous/multi-platform layouts.
    if index["schemaVersion"] != 2 or len(index["manifests"]) != 1:
        raise ValueError("expected one platform manifest in embedded layout")
    descriptor = index["manifests"][0]
    manifest = read_blob(layout, descriptor)
    config = read_blob(layout, manifest["config"])
    if config["os"] != "linux" or config["architecture"] not in ("amd64", "arm64"):
        raise ValueError("Tromso live ISO requires a linux/amd64 or linux/arm64 payload")
    receipt = {
        "schemaVersion": 1,
        "kind": "tromso-live",
        "image": image,
        "platformManifestDigest": descriptor["digest"],
        "configDigest": manifest["config"]["digest"],
        "ociLayoutPath": "/run/tromso/payload",
        "targetImgref": image,
        "platform": f'linux/{config["architecture"]}',
    }
    destination = root / "etc/bootc-installer/media-input.json"
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(receipt, indent=2) + "\n")


if __name__ == "__main__":
    write_media_input(Path(sys.argv[1]), sys.argv[2])
