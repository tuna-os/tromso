"""The source-tracking scope must agree with the shipping element graph.

``.github/workflows/track-bst-sources.yml`` bumps ``ref:`` for a *path*
allowlist (``elements/tromso elements/gnomeos-deps``), while what actually
ships is a *graph*: whatever ``oci/tromso.bst`` transitively depends on.
Nothing keeps those two sets in agreement, and they have already diverged --
``gnomeos-deps/bootc.bst`` is tracked but orphaned, so 7 automated bumps
carried it from v1.15.0 to v1.16.13 while the element the image really
installs, ``kde-linux-deps/bootc.bst``, sat untracked on v1.15.1 since the
kde-build-meta consolidation.  Two elements, one upstream
(``github:bootc-dev/bootc.git``), and the tracked one is the one nothing
builds.

That is the specific failure this file exists to catch: a tracked element and
an untracked element claiming the *same* upstream, which makes the ref bumps
land in a copy the image never installs.  A plain orphan is not an error --
310 of 802 local elements are unreachable from the shipping target, most of
them consolidated-in package definitions kept for future variants -- and
neither is an untracked reachable element, since tracking is deliberately
scoped to Tromso's own additions rather than the whole inherited tree.

Pure source inspection: no BuildStream, no network, stdlib only (the CI pytest
job installs nothing but pytest).  ``bst-validate`` is the authoritative graph
check; this is the fast offline view of the same graph, in the spirit of
tests/pytest/test_source_aliases.py.
"""

import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
ELEMENTS = REPO / "elements"
WORKFLOW = REPO / ".github" / "workflows" / "track-bst-sources.yml"

# The element the image is built from -- see build-tromso-multirunner.yml's
# BST_TARGET and test.yml's bst-validate job.
SHIPPING_TARGET = "oci/tromso.bst"

# A dependency entry, as either `- some/element.bst` or the expanded
# `- filename: some/element.bst` form. Junction-qualified targets
# (`freedesktop-sdk.bst:components/foo.bst`) live in another project and are
# not trackable from here, so they are skipped by the `:` test below.
DEP_RE = re.compile(r"^\s*-\s+(?:filename:\s*)?([A-Za-z0-9_][A-Za-z0-9_/.:-]*\.bst)\s*$")
# `url: <value>`, whether or not the mapping opens a list item.
URL_RE = re.compile(r"^\s*(?:-\s+)?url:\s*(\S+)\s*$")
# The matrix `paths:` allowlist and the offline-unbuildable exclusion list,
# both double-quoted plain scalars in the workflow.
PATHS_RE = re.compile(r'^\s*paths:\s*"([^"]+)"\s*$', re.MULTILINE)
EXCLUDE_RE = re.compile(r'^\s*TRACK_EXCLUDE="([^"]*)"\s*$', re.MULTILINE)

# The one upstream already in this state, kept here so the count cannot grow.
#
# Repointing tracking at the shipped element is a one-line edit to
# `paths:` in track-bst-sources.yml, but it cannot land from the same PR as
# this test: `elements/gnomeos-deps/` holds nothing but the orphan, so
# removing the orphan and leaving the workflow pointed at a directory that no
# longer exists makes tracking silently skip it (see test_tracked_paths_exist).
# The workflow edit and the removal have to land together, and a GitHub App
# without the Workflows permission cannot push `.github/workflows/**` at all.
# Tracked in tuna-os/tromso#318. Drop this entry when that lands -- the
# staleness test below will insist on it.
SPLIT_UPSTREAM_GRANDFATHERED = frozenset({"github:bootc-dev/bootc.git"})


def _local_elements():
    """Every repo-local element, as an ``elements/``-relative posix path."""
    return {p.relative_to(ELEMENTS).as_posix() for p in ELEMENTS.rglob("*.bst")}


def _local_deps(rel):
    """Repo-local dependencies declared by one element."""
    out = set()
    for line in (ELEMENTS / rel).read_text().splitlines():
        match = DEP_RE.match(line)
        if match and ":" not in match.group(1):
            out.add(match.group(1))
    return out


def _reachable(elements):
    """Elements transitively reachable from the shipping target."""
    seen = set()
    stack = [SHIPPING_TARGET]
    while stack:
        current = stack.pop()
        if current in seen or current not in elements:
            continue
        seen.add(current)
        stack.extend(_local_deps(current))
    return seen


def _tracked(elements):
    """Elements the tracking workflow bumps refs for.

    Mirrors the workflow's own shell: each `paths:` entry is either a
    directory -- expanded with a non-recursive `"$p"/*.bst` glob -- or a
    single element, minus anything in TRACK_EXCLUDE.
    """
    paths_match = PATHS_RE.search(WORKFLOW.read_text())
    assert paths_match, "track-bst-sources.yml declares no matrix paths:"
    exclude_match = EXCLUDE_RE.search(WORKFLOW.read_text())
    assert exclude_match, "track-bst-sources.yml declares no TRACK_EXCLUDE"
    excluded = set(exclude_match.group(1).split())

    out = set()
    for entry in paths_match.group(1).split():
        rel = entry.removeprefix("elements/")
        if (ELEMENTS / rel).is_dir():
            # Non-recursive, exactly like `for f in "$p"/*.bst`.
            out |= {
                b for b in elements if b.startswith(f"{rel}/") and b.count("/") == rel.count("/") + 1
            }
        else:
            out.add(rel)
    return out - excluded


def _primary_upstream(rel):
    """The first `url:` in an element -- its main upstream, if it has one."""
    for line in (ELEMENTS / rel).read_text().splitlines():
        match = URL_RE.match(line)
        if match:
            return match.group(1).strip("'\"")
    return None


ELEMENT_SET = _local_elements()
REACHABLE = _reachable(ELEMENT_SET)
TRACKED = _tracked(ELEMENT_SET)


def test_graph_and_workflow_both_parsed():
    """Guard the helpers: a silent parse failure would make the real
    assertions below vacuously true."""
    assert SHIPPING_TARGET in ELEMENT_SET, SHIPPING_TARGET
    assert len(ELEMENT_SET) > 500, len(ELEMENT_SET)
    # The shipping graph is a large subset of the tree, not all of it and not
    # just the root.
    assert 100 < len(REACHABLE) < len(ELEMENT_SET), (len(REACHABLE), len(ELEMENT_SET))
    assert "kde-linux-deps/bootc.bst" in REACHABLE
    assert TRACKED, "tracking workflow resolved to no elements"
    # Not `TRACKED <= ELEMENT_SET`: a `paths:` entry whose directory was
    # removed resolves to a non-element string, and that is a real finding
    # owned by test_tracked_paths_exist, not a parse failure.
    assert len(TRACKED & ELEMENT_SET) > 10, sorted(TRACKED)


def test_tracked_paths_exist():
    """A renamed or removed directory silently shrinks tracking scope: the
    workflow's `if [ -d "$p" ]` test just skips a path that no longer
    exists, so refs stop being bumped with no failure anywhere."""
    paths_match = PATHS_RE.search(WORKFLOW.read_text())
    missing = [
        entry
        for entry in paths_match.group(1).split()
        if not (REPO / entry).exists()
    ]
    assert not missing, (
        "track-bst-sources.yml tracks paths that no longer exist "
        "(tracking silently skips them):\n" + "\n".join(missing)
    )


def test_excluded_elements_exist():
    """Same ratchet for TRACK_EXCLUDE: once an element is gone or vendors its
    modules, the exclusion should go too, or it silently protects nothing."""
    exclude_match = EXCLUDE_RE.search(WORKFLOW.read_text())
    stale = sorted(e for e in exclude_match.group(1).split() if e not in ELEMENT_SET)
    assert not stale, (
        "TRACK_EXCLUDE names elements that no longer exist:\n" + "\n".join(stale)
    )


def test_no_upstream_is_tracked_only_in_an_unshipped_element():
    """The regression that motivated this file.

    If two elements share an upstream and only the one outside the shipping
    graph is tracked, every automated bump lands in a copy the image never
    installs -- while the element that *is* installed silently stays behind.
    Fix by tracking the shipped element, or by removing the unshipped copy.
    """
    upstreams = {}
    for rel in sorted(ELEMENT_SET):
        url = _primary_upstream(rel)
        if url:
            upstreams.setdefault(url, []).append(rel)

    offenders = {}
    for url, rels in sorted(upstreams.items()):
        if len(rels) < 2:
            continue
        tracked_unshipped = [r for r in rels if r in TRACKED and r not in REACHABLE]
        untracked_shipped = [r for r in rels if r not in TRACKED and r in REACHABLE]
        if tracked_unshipped and untracked_shipped:
            offenders[url] = (
                f"{url}\n"
                f"    tracked but not shipped: {', '.join(tracked_unshipped)}\n"
                f"    shipped but not tracked: {', '.join(untracked_shipped)}"
            )

    new = [offenders[u] for u in sorted(set(offenders) - SPLIT_UPSTREAM_GRANDFATHERED)]
    assert not new, (
        "source tracking bumps an upstream only in an element the image does "
        "not install -- track the shipped element, or remove the unshipped "
        "copy:\n" + "\n".join(new)
    )


def test_split_upstream_allowlist_has_no_stale_entries():
    """Keep the ratchet honest: once tracking is repointed at the shipped
    element, drop the upstream from the allowlist so it can never silently
    regress."""
    upstreams = {}
    for rel in sorted(ELEMENT_SET):
        url = _primary_upstream(rel)
        if url:
            upstreams.setdefault(url, []).append(rel)

    still_split = set()
    for url, rels in upstreams.items():
        if len(rels) < 2:
            continue
        if any(r in TRACKED and r not in REACHABLE for r in rels) and any(
            r not in TRACKED and r in REACHABLE for r in rels
        ):
            still_split.add(url)

    stale = sorted(SPLIT_UPSTREAM_GRANDFATHERED - still_split)
    assert not stale, (
        "remove from SPLIT_UPSTREAM_GRANDFATHERED, they no longer need it:\n"
        + "\n".join(stale)
    )
