"""Unit tests for scripts/check-ogc-image.py and scripts/cas-pack-artifacts.py.

The two scripts of the OGC workflow (docs/OGC.md). The tests make a small
module tree and a small BuildStream cache in a temporary directory. Needs the
zstd command, as the scripts do.
"""

import hashlib
import importlib.util
import json
import os
import subprocess
import sys
from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parents[2]
MANIFEST = json.loads((REPO / "files/ogc/manifest.json").read_text())


def _load(name, file):
    spec = importlib.util.spec_from_file_location(name, REPO / "scripts" / file)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


check = _load("check_ogc_image", "check-ogc-image.py")
pack = _load("cas_pack_artifacts", "cas-pack-artifacts.py")


# check-ogc-image.py

def _module(tree, rel, signed=True):
    path = tree / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    data = b"\x7fELF module" + (check.SIGNATURE if signed else b"")
    path.write_bytes(subprocess.run(["zstd", "-cq"], input=data, capture_output=True, check=True).stdout)
    return rel


def _image(root, unsigned=(), extra=(), skip_dep=()):
    """A root with the kernel and the files of the manifest."""
    tree = root / "usr/lib/modules" / MANIFEST["kernel_release"]
    rels = [_module(tree, f"extra/{m}.ko.zst", m not in unsigned) for m in MANIFEST["out_of_tree_modules"]]
    rels += [_module(tree, f"kernel/drivers/{m}.ko.zst", m not in unsigned) for m in MANIFEST["in_tree_modules"]]
    rels += [_module(tree, rel) for rel in extra]
    (tree / "modules.dep").write_text("".join(f"{r}:\n" for r in rels if r not in skip_dep))
    for rel in MANIFEST["files"]:
        (root / rel).parent.mkdir(parents=True, exist_ok=True)
        (root / rel).touch()
    release = "".join(f'{k}="{v}"\n' for k, v in MANIFEST["os_release"].items())
    (root / "usr/lib/os-release").write_text(release)
    return tree


def _run(argv, capsys):
    with pytest.raises(SystemExit) as stop:
        check.main(argv)
    return stop.value.code, capsys.readouterr().err


def test_a_complete_image_passes(tmp_path, capsys):
    _image(tmp_path)
    check.main([str(tmp_path)])
    out = capsys.readouterr().out
    assert "check-ogc-image: pass" in out
    modules = len(MANIFEST["out_of_tree_modules"]) + len(MANIFEST["in_tree_modules"])
    assert f"{modules} modules" in out


def test_kernel_only_does_not_need_the_files(tmp_path, capsys):
    _image(tmp_path)
    (tmp_path / "usr/lib/os-release").unlink()
    check.main(["--kernel-only", str(tmp_path)])
    assert "pass" in capsys.readouterr().out


def test_a_bad_kernel_tree_fails(tmp_path, capsys):
    first, second = MANIFEST["out_of_tree_modules"][:2]
    tree = _image(
        tmp_path,
        unsigned=[first],
        extra=[f"kernel/{MANIFEST['forbidden_modules'][0]}.ko.zst"],
        skip_dep=[f"extra/{first}.ko.zst"],
    )
    (tree / f"extra/{second}.ko.zst").rename(tree / f"kernel/{second}.ko.zst")
    (tree / f"kernel/drivers/{MANIFEST['in_tree_modules'][0]}.ko.zst").unlink()
    code, err = _run(["--kernel-only", str(tmp_path)], capsys)
    assert code == 1
    assert f"extra/{first}.ko.zst has no signature" in err
    assert f"extra/{first}.ko.zst is not in modules.dep" in err
    assert f"out-of-tree module {second} is not in extra/" in err
    assert f"in-tree module {MANIFEST['in_tree_modules'][0]} is missing" in err
    assert f"module {MANIFEST['forbidden_modules'][0]} must not be in the image" in err


def test_a_missing_module_and_a_second_kernel_fail(tmp_path, capsys):
    tree = _image(tmp_path)
    name = MANIFEST["out_of_tree_modules"][0]
    (tree / f"extra/{name}.ko.zst").unlink()
    code, err = _run(["--kernel-only", str(tmp_path)], capsys)
    assert code == 1 and f"out-of-tree module {name} is missing" in err
    (tmp_path / "usr/lib/modules/6.0.0").mkdir()
    code, err = _run(["--kernel-only", str(tmp_path)], capsys)
    assert code == 1 and "kernel releases are" in err


def test_files_and_os_release_are_checked_and_not_skips_one(tmp_path, capsys):
    _image(tmp_path)
    missing = MANIFEST["files"][0]
    (tmp_path / missing).unlink()
    (tmp_path / "usr/lib/os-release").write_text('IMAGE_NAME="tromso"\n')
    code, err = _run([str(tmp_path)], capsys)
    assert code == 1
    assert f"{missing} is missing" in err
    assert "os-release: IMAGE_NAME is not 'tromso-ogc'" in err
    code, err = _run(["--not", missing, str(tmp_path)], capsys)
    assert f"{missing} is missing" not in err


def test_one_root_only(capsys):
    with pytest.raises(SystemExit) as stop:
        check.main(["--kernel-only"])
    assert "Usage" in str(stop.value.code)


# cas-pack-artifacts.py

def _varint(value):
    out = bytearray()
    while True:
        byte, value = value & 0x7F, value >> 7
        out.append(byte | (0x80 if value else 0))
        if not value:
            return bytes(out)


def _field(number, value):
    if isinstance(value, int):
        return _varint(number << 3) + _varint(value)
    return _varint(number << 3 | 2) + _varint(len(value)) + value


def _digest(data):
    return hashlib.sha256(data).hexdigest()


def _digest_message(data):
    return _field(1, _digest(data).encode()) + _field(2, len(data))


def _store(cache, data):
    digest = _digest(data)
    path = cache / "cas/objects" / digest[:2] / digest[2:]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    return f"cas/objects/{digest[:2]}/{digest[2:]}"


def test_pack_follows_the_new_artifacts_only(tmp_path, capsys):
    cache = tmp_path / "cache"
    stamp = tmp_path / "stamp"
    old_file = _store(cache, b"old file")
    old_ref = cache / "artifacts/refs/tromso/old/aaaa"
    old_ref.parent.mkdir(parents=True)
    old_ref.write_bytes(_field(5, _digest_message(b"old file")))
    os.utime(old_ref, (1, 1))
    stamp.touch()
    os.utime(stamp, (100, 100))

    blob = b"a file of the kernel"
    blob_rel = _store(cache, blob)
    directory = _field(3, _field(1, b"vmlinuz") + _field(2, _digest_message(blob)))
    dir_rel = _store(cache, directory)
    # A digest that is not in the cache costs nothing.
    ref = cache / "artifacts/refs/tromso/ogc-linux/bbbb"
    ref.parent.mkdir(parents=True)
    ref.write_bytes(_field(2, b"ogc/linux") + _field(5, _digest_message(directory))
                    + _field(6, _digest_message(b"not stored")) + _field(9, 7))

    pack.main(cache, stamp)
    captured = capsys.readouterr()
    listed = set(captured.out.split("\0")) - {""}
    assert listed == {"artifacts/refs/tromso/ogc-linux/bbbb", dir_rel, blob_rel}
    assert old_file not in listed
    assert "1 artifacts, 3 files" in captured.err


def test_pack_needs_a_new_artifact(tmp_path):
    (tmp_path / "artifacts/refs").mkdir(parents=True)
    stamp = tmp_path / "stamp"
    stamp.touch()
    with pytest.raises(SystemExit) as stop:
        pack.main(tmp_path, stamp)
    assert "no artifact is newer" in str(stop.value.code)


@pytest.mark.parametrize("data", [b"\x80", b"\x00\x01", b"\x0a\x05ab", b"\x0b"])
def test_bad_protos_have_no_digests(data):
    assert list(pack.digests(data)) == []


def test_fixed_width_fields_are_skipped():
    data = _field(1, b"x" * 64) + bytes([1 << 3 | 1]) + b"8bytes!!" + bytes([2 << 3 | 5]) + b"4byt"
    assert list(pack.digests(data)) == []
