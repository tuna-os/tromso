"""The OGC variant must stay pinned, separate and complete (docs/OGC.md).

Pure source inspection: no BuildStream, no network, stdlib only.
"""

import json
import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
OGC = REPO / "elements" / "ogc"
MANIFEST = json.loads((REPO / "files/ogc/manifest.json").read_text())
LINUX = (OGC / "linux.bst").read_text()
DOC = (REPO / "docs/OGC.md").read_text()
WORKFLOW = (REPO / ".github/workflows/build-tromso-ogc.yml").read_text()
DEFAULT = (REPO / ".github/workflows/build-tromso-multirunner.yml").read_text()


def test_every_source_is_pinned():
    for path in OGC.glob("*.bst"):
        for ref in re.findall(r"^  ref: *(\S+)$", path.read_text(), re.MULTILINE):
            assert re.search(r"[0-9a-f]{40}$|[0-9a-f]{64}$", ref), f"{path.name}: {ref}"


def test_only_a_conditional_uses_the_variant():
    """An unconditional use of elements/ogc would change the default image."""
    for path in (REPO / "elements").rglob("*.bst"):
        if path.parent == OGC:
            continue
        conditional = False
        for line in path.read_text().splitlines():
            if line and not line[0].isspace() and not line.startswith(("-", "#")):
                conditional = False
            if 'flavor == "ogc"' in line:
                conditional = True
            if re.search(r"\bogc/[a-z0-9-]+\.bst|freedesktop-sdk-ogc", line):
                assert conditional, f"{path.name}: {line}"


def test_the_default_flavor_is_main():
    conf = (REPO / "project.conf").read_text()
    block = conf[conf.index("  flavor:"):].split("\nsandbox:")[0]
    assert "default: main" in block and "variable:" not in block


def test_the_module_key_never_enters_the_cache():
    policy = (REPO / "files/ogc/kernel/tromso-policy.config").read_text()
    key = re.search(r'^CONFIG_MODULE_SIG_KEY="(.+)"$', policy, re.MULTILINE).group(1)
    assert key.startswith("/tmp/")
    assert "stat -f -c %T /tmp" in LINUX and "rm -rf /tmp/ogc-modsign" in LINUX
    assert "boot-keys" not in LINUX
    assert 'CONFIG_SYSTEM_TRUSTED_KEYS=""' in policy
    assert "CONFIG_MODULE_SIG_ALL=y" in policy
    assert "CONFIG_SECURITY_LOCKDOWN_LSM=y" in policy


def test_the_kernel_release_and_the_version_agree():
    version = re.search(r"linux-([0-9.]+)\.tar\.xz", LINUX).group(1)
    patch = re.search(r"download/v([0-9.]+-ogc[0-9]+)/monolithic", LINUX).group(1)
    assert patch.startswith(version + "-")
    assert MANIFEST["kernel_release"] == patch + "-tromso"


def test_the_document_names_every_module_and_the_refused_ones():
    for name in MANIFEST["out_of_tree_modules"] + MANIFEST["forbidden_modules"]:
        assert f"`{name}`" in DOC, name
    for path in OGC.glob("*.bst"):
        assert f"ogc/{path.name}" in DOC, path.name


def test_the_default_workflow_does_not_know_the_variant():
    assert "ogc" not in DEFAULT.lower()
    assert "  workflow_run:" not in WORKFLOW


def test_the_variant_reads_the_default_caches_only():
    assert "oras push" not in WORKFLOW
    final = (REPO / ".github/workflows/build-final.yml").read_text()
    assert "oras push" not in final
    assert "CACHE_IMAGE: tromso\n" in final
    assert "default: 'tromso'" in final
