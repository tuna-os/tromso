#!/usr/bin/env python3
"""Check that an image root (or the kernel artifact) has the bits of the OGC variant.

Usage: check-ogc-image.py [--kernel-only] [--not FILE]... ROOT

ROOT is a checkout of elements/ogc/linux.bst (--kernel-only), or the mounted
root of the exported image. files/ogc/manifest.json is the list. Every entry
of it must be in docs/OGC.md (tests/pytest/test_ogc_variant.py holds that).
Stdlib only.
"""

import json
import subprocess
import sys
from pathlib import Path

MANIFEST = Path(__file__).resolve().parents[1] / "files" / "ogc" / "manifest.json"
SIGNATURE = b"~Module signature appended~\n"


def fail(messages):
    for message in messages:
        print(f"check-ogc-image: {message}", file=sys.stderr)
    sys.exit(1)


def check_kernel(root, manifest):
    bad = []
    base = root / "usr/lib/modules"
    releases = sorted(p.name for p in base.iterdir() if p.is_dir())
    if releases != [manifest["kernel_release"]]:
        return [f"kernel releases are {releases}, want {[manifest['kernel_release']]}"]
    tree = base / releases[0]
    modules = {p.name.split(".")[0].replace("-", "_"): p for p in tree.rglob("*.ko.zst")}
    print(f"kernel {releases[0]}: {len(modules)} modules")
    for name in manifest["out_of_tree_modules"]:
        path = modules.get(name.replace("-", "_"))
        if path is None:
            bad.append(f"out-of-tree module {name} is missing")
        elif "extra" not in path.relative_to(tree).parts:
            bad.append(f"out-of-tree module {name} is not in extra/")
    for name in manifest["in_tree_modules"]:
        if name.replace("-", "_") not in modules:
            bad.append(f"in-tree module {name} is missing")
    for name in manifest["forbidden_modules"]:
        if name.replace("-", "_") in modules:
            bad.append(f"module {name} must not be in the image (docs/OGC.md)")
    dep = (tree / "modules.dep").read_text() if (tree / "modules.dep").exists() else ""
    for path in modules.values():
        rel = path.relative_to(tree).as_posix()
        data = subprocess.run(["zstd", "-dcq", path], capture_output=True, check=True).stdout
        if not data.endswith(SIGNATURE):
            bad.append(f"{rel} has no signature")
        if f"{rel}:" not in dep:
            bad.append(f"{rel} is not in modules.dep")
    return bad


def check_files(root, manifest, skip=()):
    bad = [f"{f} is missing" for f in manifest["files"] if f not in skip and not (root / f).exists()]
    release = (root / "usr/lib/os-release").read_text()
    for key, value in manifest["os_release"].items():
        if f'{key}="{value}"' not in release.splitlines():
            bad.append(f"os-release: {key} is not {value!r}")
    return bad


def main(argv):
    kernel_only = "--kernel-only" in argv
    skip, roots, args = set(), [], iter(argv)
    for arg in args:
        if arg == "--not":
            skip.add(next(args))
        elif not arg.startswith("--"):
            roots.append(arg)
    if len(roots) != 1:
        sys.exit(__doc__)
    root = Path(roots[0])
    manifest = json.loads(MANIFEST.read_text())
    bad = check_kernel(root, manifest)
    if not kernel_only:
        bad += check_files(root, manifest, skip)
    if bad:
        fail(bad)
    print("check-ogc-image: pass")


if __name__ == "__main__":
    main(sys.argv[1:])
