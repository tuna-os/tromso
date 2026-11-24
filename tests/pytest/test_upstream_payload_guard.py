"""Guard the two upstream payloads that stage into the image (#487).

The guard is a shell script run inside the BuildStream `manual` elements.
Tests drive that script against synthetic trees, so a new test fails when a
guard is removed or a sensitive path stops being checked.
"""

import subprocess
from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parents[2]
AUDIT = REPO / "files/tromso/audit"
SCRIPT = AUDIT / "check-upstream-payload.sh"
ELEMENTS = REPO / "elements/tromso"
LISTS = ("bluefin-common-paths.txt", "image-overlay-paths.txt")
ALL_LISTS = (*LISTS, "bluefin-common-stripped.txt")


def run_guard(tmp_path, list_name, paths, stripped=None):
    for path in paths:
        target = tmp_path / "system_files/shared" / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text("payload\n")
    (tmp_path / list_name).write_text((AUDIT / list_name).read_text())
    args = ["sh", str(SCRIPT), list_name]
    if stripped:
        (tmp_path / stripped).write_text((AUDIT / stripped).read_text())
        args.append(stripped)
    return subprocess.run(args, cwd=tmp_path, capture_output=True, text=True)


@pytest.mark.parametrize("path", [
    "etc/sudoers.d/99-test",
    "etc/polkit-1/rules.d/99-test.rules",
    "usr/share/polkit-1/rules.d/99-test.rules",
    "usr/lib/systemd/system/99-test.service",
    "usr/bin/99-test",
    "usr/share/ublue-os/privileged-setup.hooks.d/99-test.sh",
])
def test_guard_rejects_unlisted_sensitive_path(tmp_path, path):
    result = run_guard(tmp_path, "bluefin-common-paths.txt", [path])
    assert result.returncode != 0
    assert f"unreviewed sensitive upstream path: {path}" in result.stderr


@pytest.mark.parametrize("list_name", LISTS)
def test_guard_accepts_reviewed_paths(tmp_path, list_name):
    paths = [line.strip() for line in (AUDIT / list_name).read_text().splitlines() if line.strip()]
    result = run_guard(tmp_path, list_name, paths)
    assert result.returncode == 0, result.stderr


@pytest.mark.parametrize("list_name", ALL_LISTS)
def test_reviewed_list_has_sorted_unique_relative_paths(list_name):
    paths = (AUDIT / list_name).read_text().splitlines()
    assert paths
    assert paths == sorted(set(paths))
    for path in paths:
        assert not path.startswith("/")
        assert ".." not in Path(path).parts


@pytest.mark.parametrize("element,call", [
    ("bluefin-common.bst", "sh check-upstream-payload.sh bluefin-common-paths.txt bluefin-common-stripped.txt"),
    ("image-overlay.bst", "sh check-upstream-payload.sh image-overlay-paths.txt"),
])
def test_both_upstream_elements_invoke_the_guard(element, call):
    text = (ELEMENTS / element).read_text()
    assert "- kind: local\n  path: files/tromso/audit" in text
    assert call in text
    assert "freedesktop-sdk.bst:components/grep.bst" in text


def test_reviewed_copy_is_not_replaced_by_the_later_upstream():
    aurora = (AUDIT / "image-overlay-paths.txt").read_text()
    for path in (
        "usr/share/polkit-1/actions/org.ublue.privileged.user.setup.policy",
        "usr/share/ublue-os/privileged-setup.hooks.d/10-tailscale.sh",
    ):
        assert path not in aurora


def test_upstream_nopasswd_grant_is_stripped(tmp_path):
    path = "etc/sudoers.d/001-bootc"
    rejected = run_guard(tmp_path, "bluefin-common-paths.txt", [path])
    assert rejected.returncode != 0
    accepted = run_guard(
        tmp_path, "bluefin-common-paths.txt", [path], "bluefin-common-stripped.txt"
    )
    assert accepted.returncode == 0, accepted.stderr
    bluefin = (ELEMENTS / "bluefin-common.bst").read_text()
    assert 'rm -f "%{install-root}%{sysconfdir}/sudoers.d/001-bootc"' in bluefin
    assert path not in (AUDIT / "bluefin-common-paths.txt").read_text()
