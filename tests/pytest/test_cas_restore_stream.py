"""The CAS restore is bst-ci's transport, called at a pinned commit.

scripts/cas-restore-stream.sh keeps only what build-final.yml needs from it:
exit 1 for a reference with no manifest, so the caller can fall back from the
cache-key tag to :latest. The download, digest check, filter and object check
belong to tuna-os/bst-ci's cas_transport.py (tuna-os/tromso#472).
"""

import os
import re
import subprocess
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SCRIPT_PATH = REPO / "scripts" / "cas-restore-stream.sh"
SCRIPT = SCRIPT_PATH.read_text()
REF = "ghcr.io/tuna-os/tromso/cache-tromso-core:latest"

STUB = """\
import sys
from pathlib import Path

Path(sys.argv[0]).with_name("calls").open("a").write(" ".join(sys.argv[1:]) + "\\n")
if sys.argv[1] == "exists":
    sys.exit(0 if Path(sys.argv[0]).with_name("present").exists() else 1)
sys.exit(int(Path(sys.argv[0]).with_name("restore-rc").read_text()))
"""


def _run(tmp_path, present, restore_rc=0):
    stub = tmp_path / "cas_transport.py"
    stub.write_text(STUB)
    (tmp_path / "restore-rc").write_text(str(restore_rc))
    if present:
        (tmp_path / "present").touch()
    env = {**os.environ, "CAS_TRANSPORT": str(stub)}
    result = subprocess.run(
        ["bash", str(SCRIPT_PATH), REF, str(tmp_path / "cache")],
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )
    calls = (tmp_path / "calls").read_text().splitlines()
    return result.returncode, calls


def test_restores_through_the_bst_ci_transport(tmp_path):
    rc, calls = _run(tmp_path, present=True)
    assert rc == 0
    assert calls == [f"exists {REF}", f"restore {REF} {tmp_path / 'cache'}"]


def test_missing_manifest_exits_1_so_the_caller_falls_back(tmp_path):
    rc, calls = _run(tmp_path, present=False)
    assert rc == 1
    assert calls == [f"exists {REF}"]


def test_failed_restore_fails(tmp_path):
    rc, _ = _run(tmp_path, present=True, restore_rc=3)
    assert rc != 0


def test_transport_is_pinned_and_not_forked():
    assert re.search(r"^BST_CI_COMMIT=[0-9a-f]{40}$", SCRIPT, re.MULTILINE)
    assert not re.search(r"\| *tar ", SCRIPT)
    assert not (REPO / "scripts" / "ghcr-blob-stream.py").exists()


def test_pin_matches_the_multirunner_workflow_pin():
    pin = re.search(r"^BST_CI_COMMIT=([0-9a-f]{40})$", SCRIPT, re.MULTILINE).group(1)
    workflow = (
        REPO / ".github" / "workflows" / "build-tromso-multirunner.yml"
    ).read_text()
    pins = set(
        re.findall(
            r"tuna-os/bst-ci/\.github/workflows/multirunner-build\.yml@([0-9a-f]{40})",
            workflow,
        )
    )
    assert pins == {pin}
