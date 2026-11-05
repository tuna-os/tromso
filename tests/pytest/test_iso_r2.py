"""Exercise R2 release failure paths without credentials or network writes."""

import os
import subprocess
from pathlib import Path

import pytest

SCRIPT = Path(__file__).resolve().parents[2] / "scripts/iso-r2.sh"
DATED = "tromso-live-20261103-123abcd.iso"
LATEST = "tromso-live-latest.iso"


@pytest.fixture
def storage(tmp_path):
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    remote = tmp_path / "remote"
    remote.mkdir()
    rclone = bin_dir / "rclone"
    rclone.write_text('''#!/usr/bin/env python3
import os, pathlib, shutil, sys
args = [a for a in sys.argv[1:] if not a.startswith("--")]
command, source, dest = args
root = pathlib.Path(os.environ["MOCK_REMOTE"])
def path(value):
    return root / value.removeprefix("R2:bucket/tromso/stable/") if value.startswith("R2:") else pathlib.Path(value)
if os.environ.get("FAIL_COPY") and command == "copyto" and os.environ["FAIL_COPY"] in dest:
    sys.exit(1)
if command == "copyto":
    shutil.copyfile(path(source), path(dest))
elif command == "check":
    if os.environ.get("FAIL_CHECK"):
        sys.exit(1)
    for item in path(source).iterdir():
        assert item.read_bytes() == (root / item.name).read_bytes()
else:
    sys.exit(2)
''')
    rclone.chmod(0o755)
    cosign = bin_dir / "cosign"
    cosign.write_text('#!/bin/sh\n[ "${FAIL_SIGNATURE:-}" != 1 ]\n')
    cosign.chmod(0o755)
    curl = bin_dir / "curl"
    curl.write_text('#!/bin/sh\n[ "${FAIL_PUBLIC:-}" != 1 ]\n')
    curl.chmod(0o755)
    iso = tmp_path / "input.iso"
    iso.write_bytes(b"boot-tested ISO")
    Path(f"{iso}.sig").write_bytes(b"signature")
    Path(f"{iso}.cert").write_bytes(b"certificate")
    env = {**os.environ, "PATH": f"{bin_dir}:{os.environ['PATH']}",
           "MOCK_REMOTE": str(remote), "R2_BUCKET": "bucket"}

    def run(mode, **extra):
        return subprocess.run(
            ["bash", str(SCRIPT), mode, DATED, "tromso/stable", str(iso)],
            env={**env, **extra}, capture_output=True, text=True,
        )

    return remote, iso, run


def test_publish_complete_set(storage):
    remote, iso, run = storage
    assert run("publish").returncode == 0
    for name in (DATED, LATEST):
        assert (remote / name).read_bytes() == iso.read_bytes()
        assert (remote / f"{name}.sig").read_bytes() == b"signature"
        assert (remote / f"{name}.cert").read_bytes() == b"certificate"
        assert (remote / f"{name}-CHECKSUM").read_text().endswith(f"  {name}\n")


@pytest.mark.parametrize("failure", [{"FAIL_COPY": DATED}, {"FAIL_CHECK": "1"}])
def test_dated_failure_never_updates_latest(storage, failure):
    remote, _, run = storage
    (remote / LATEST).write_bytes(b"previous ISO")
    assert run("publish", **failure).returncode != 0
    assert (remote / LATEST).read_bytes() == b"previous ISO"


def test_mutable_copy_failure_is_fatal(storage):
    _, _, run = storage
    assert run("publish", FAIL_COPY=LATEST).returncode != 0


def test_public_download_failure_is_fatal(storage):
    _, _, run = storage
    assert run("publish", FAIL_PUBLIC="1").returncode != 0


def test_restore_and_dry_run(storage):
    remote, iso, run = storage
    assert run("publish").returncode == 0
    (remote / LATEST).write_bytes(b"bad release")
    before = {p.name: p.read_bytes() for p in remote.iterdir()}
    assert run("verify").returncode == 0
    assert before == {p.name: p.read_bytes() for p in remote.iterdir()}
    assert run("restore").returncode == 0
    assert (remote / LATEST).read_bytes() == iso.read_bytes()
    assert (remote / DATED).read_bytes() == before[DATED]
    assert (remote / f"{LATEST}-CHECKSUM").read_text().endswith(f"  {LATEST}\n")


@pytest.mark.parametrize("problem", ["signature", "checksum", "missing"])
def test_bad_restore_target_never_updates_latest(storage, problem):
    remote, _, run = storage
    assert run("publish").returncode == 0
    (remote / LATEST).write_bytes(b"previous ISO")
    extra = {}
    if problem == "signature":
        extra["FAIL_SIGNATURE"] = "1"
    elif problem == "checksum":
        (remote / DATED).write_bytes(b"corrupt ISO")
    else:
        (remote / f"{DATED}.cert").unlink()
    before = {p.name: p.read_bytes() for p in remote.iterdir()}
    assert run("restore", **extra).returncode != 0
    assert before == {p.name: p.read_bytes() for p in remote.iterdir()}
