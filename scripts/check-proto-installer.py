#!/usr/bin/env python3
"""Compare the vendored installer and upstream tip to the recorded Git tree."""

import argparse
import hashlib
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VENDOR = ROOT / "files/kde-linux-system/live/proto-installer"


def tree(repo, revision, path):
    output = subprocess.check_output(
        ["git", "-C", str(repo), "ls-tree", "-rz", revision, "--", path]
    )
    result = {}
    for entry in output.split(b"\0"):
        if not entry:
            continue
        metadata, name = entry.decode().split("\t", 1)
        mode, kind, digest = metadata.split()
        if kind != "blob":
            raise ValueError(f"Unexpected upstream entry: {name}")
        result[name[len(path) + 1 :]] = (mode, digest)
    if not result:
        raise ValueError(f"No installer files at {revision}:{path}")
    return result


def differences(left, right):
    return sorted(
        name for name in left.keys() | right.keys() if left.get(name) != right.get(name)
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("upstream", type=Path, help="gnome-build-meta Git checkout")
    parser.add_argument("--tip", help="also check an upstream revision for updates")
    args = parser.parse_args()
    pin = json.loads((VENDOR / "upstream.json").read_text())
    baseline = tree(args.upstream, pin["commit"], pin["path"])
    local = {}
    for file in VENDOR.rglob("*"):
        if (
            not file.is_file()
            or "__pycache__" in file.parts
            or file.relative_to(VENDOR).as_posix() in {"README.md", "upstream.json"}
        ):
            continue
        data = file.read_bytes()
        digest = hashlib.sha1(
            b"blob " + str(len(data)).encode() + b"\0" + data
        ).hexdigest()
        mode = "100755" if file.stat().st_mode & 0o111 else "100644"
        local[file.relative_to(VENDOR).as_posix()] = (mode, digest)
    changed = differences(baseline, local)
    if changed:
        print("Local drift from pin:\n" + "\n".join(changed))
    else:
        print(
            f"All {len(local)} vendored files match {pin['commit']} (content and mode)."
        )
    upstream_changes = []
    if args.tip:
        upstream_changes = differences(
            baseline, tree(args.upstream, args.tip, pin["path"])
        )
        if upstream_changes:
            print("Upstream changes requiring review:\n" + "\n".join(upstream_changes))
            subprocess.run(
                [
                    "git",
                    "-C",
                    str(args.upstream),
                    "diff",
                    pin["commit"],
                    args.tip,
                    "--",
                    pin["path"],
                ],
                check=True,
            )
    return int(bool(changed or upstream_changes))


if __name__ == "__main__":
    raise SystemExit(main())
