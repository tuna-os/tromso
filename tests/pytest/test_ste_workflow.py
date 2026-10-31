"""Tests for the Simplified Technical English workflow configuration (issue #345).

Verifies that .github/workflows/ste.yml references the shared ste-lint workflow
pinned to an immutable 40-character commit SHA rather than a mutable branch ref.
"""

from pathlib import Path
import re

REPO = Path(__file__).resolve().parents[2]
STE_WORKFLOW = REPO / ".github" / "workflows" / "ste.yml"


def test_ste_workflow_pins_immutable_sha():
    """Shared ste-lint workflow reference must be pinned to a full commit SHA."""
    assert STE_WORKFLOW.is_file(), f"{STE_WORKFLOW} does not exist"
    content = STE_WORKFLOW.read_text()

    match = re.search(
        r"uses:\s+tuna-os/\.github/\.github/workflows/ste-lint\.yml@([^\s#]+)",
        content,
    )
    assert match is not None, "ste-lint.yml workflow reference not found"

    ref = match.group(1)
    assert re.fullmatch(
        r"[0-9a-f]{40}", ref
    ), f"ste-lint.yml must be pinned to a 40-character commit SHA, found {ref!r}"
    assert ref != "main", "ste-lint.yml must not use mutable branch reference 'main'"
