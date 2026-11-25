"""The CAS restore never uses plain tar, which trusts a truncated object."""

import re
from pathlib import Path

SCRIPT = (Path(__file__).resolve().parents[2] / "scripts" / "cas-restore-stream.sh").read_text()


def test_restore_verifies_each_object_with_a_pinned_untar():
    assert '| python3 "$CAS_UNTAR" "$CACHE_DIR"' in SCRIPT
    assert not re.search(r"\| *tar ", SCRIPT)
    assert re.search(r"^BST_CI_COMMIT=[0-9a-f]{40}$", SCRIPT, re.MULTILINE)
