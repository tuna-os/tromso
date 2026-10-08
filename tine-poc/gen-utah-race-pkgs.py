#!/usr/bin/env python3
"""Regenerate utah_race_pkgs.bzl from utah's manifests + tine's catalog.

Usage:
  python3 tine-poc/gen-utah-race-pkgs.py [utah-checkout] [snapshot-json] [out-bzl]

Defaults: /tmp/pb-utah, tine/catalog/snapshot/repo/fedora.rawhide.x86_64.json,
tine-poc/utah_race_pkgs.bzl (paths relative to repo root).
"""
import json
import sys
import tomllib

MISSING_FROM_CATALOG = {"linux-atm-libs", "pipewire-libs-extra"}
# Boot-critical set utah inherits from its Hummingbird bootc-os base image;
# tine starts from bare RPMs, so the race must name them explicitly.
BOOT_ADDS = [
    "bash", "coreutils", "systemd", "glibc", "dbus", "polkit",
    "fedora-release-common", "kernel", "kernel-modules", "dracut",
    "dracut-config-generic", "ostree", "composefs", "bootc", "bootupd",
    "btrfs-progs", "xfsprogs", "dosfstools", "e2fsprogs",
    "systemd-boot-unsigned", "shim-x64", "grub2-efi-x64",
    "selinux-policy-targeted", "NetworkManager", "gdm", "openssh-server",
]


def snapshot_names(path):
    snap = json.load(open(path))
    names = set()
    for v in snap["packages"].values():
        loc = v["location"].rsplit("/", 1)[-1][:-4]
        base, _, _ = loc.rpartition(".")
        parts = base.rsplit("-", 2)
        names.add(parts[0] if len(parts) == 3 else base)
    return names


def manifest_names(utah_dir):
    want = set()
    for f in ["packages/utah.toml", "packages/bluefin.toml"]:
        d = tomllib.load(open(f"{utah_dir}/{f}", "rb"))

        def walk(o):
            if isinstance(o, dict):
                for k, v in o.items():
                    if k == "packages" and isinstance(v, list):
                        want.update(v)
                    else:
                        walk(v)

        walk(d)
    return want


def main():
    utah_dir = sys.argv[1] if len(sys.argv) > 1 else "/tmp/pb-utah"
    snap_path = (
        sys.argv[2]
        if len(sys.argv) > 2
        else "tine/catalog/snapshot/repo/fedora.rawhide.x86_64.json"
    )
    out = sys.argv[3] if len(sys.argv) > 3 else "tine-poc/utah_race_pkgs.bzl"
    pkgs = sorted(
        (manifest_names(utah_dir) - MISSING_FROM_CATALOG) | set(BOOT_ADDS)
    )
    dropped = sorted(manifest_names(utah_dir) - set(pkgs))
    missing = sorted(set(pkgs) - snapshot_names(snap_path) - set(BOOT_ADDS))
    lines = [
        "# GENERATED — do not hand-edit. Regenerate with:",
        "#   python3 tine-poc/gen-utah-race-pkgs.py",
        "# Sources: utah packages/utah.toml + packages/bluefin.toml",
        "# intersected with tine catalog fedora.rawhide.x86_64.json.",
        f"# Dropped (absent from tine catalog): {', '.join(sorted(MISSING_FROM_CATALOG))}.",
        "# Added: boot-critical set utah inherits from its Hummingbird bootc-os base.",
        "# GNOME version skew is intentional and documented: utah ships factory-built",
        "# GNOME 51; tine resolves the same names from Fedora rawhide. This",
        "# races image-assembly speed, not desktop versions.",
        "UTAH_RACE_PACKAGES = [",
    ]
    lines += [f'    "{p}",' for p in pkgs]
    lines += ["]", ""]
    open(out, "w").write("\n".join(lines))
    print(f"wrote {len(pkgs)} packages to {out}")
    print(f"dropped: {dropped}")
    if missing:
        print(f"WARNING: {len(missing)} listed packages absent from snapshot: {missing}")


if __name__ == "__main__":
    main()
