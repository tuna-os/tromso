"""Source-URL aliasing conventions, as practised by freedesktop-sdk.

freedesktop-sdk's own ``project.conf`` makes ``unaliased-url`` a fatal
warning and routes every source through ``include/_private/aliases.yml`` so
that a download location can be re-pointed (or mirrored) without changing an
element's cache key.  Tromso inherits that model — ``include/aliases.yml``
plus ``include/mirrors.yml`` — so these invariants keep it honest.

Pure source inspection: no BuildStream, no network, stdlib only (the CI
pytest job installs nothing but pytest).  The authoritative check is the
``bst-validate`` job, which loads the whole graph and fails on the fatal
warning; this file is the fast, offline version of the same rule.

See docs/adr/0004-freedesktop-sdk-upstream-practices.md (tuna-os/tromso#264).
"""

import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
ELEMENTS = REPO / "elements"
ALIASES_YML = REPO / "include" / "aliases.yml"
MIRRORS_YML = REPO / "include" / "mirrors.yml"
PROJECT_CONF = REPO / "project.conf"

# `url: <value>`, whether or not the mapping is the first key of a list item.
URL_RE = re.compile(r"^\s*(?:-\s+)?url:\s*(\S+)\s*$")
# `  some_alias: https://…` under the `aliases:` mapping of include/aliases.yml.
ALIAS_DEF_RE = re.compile(r"^  ([A-Za-z0-9_]+):\s*(\S+)\s*$")

# Generic catch-all aliases. They satisfy `unaliased-url` (BuildStream only
# requires *an* alias) but carry no mirror of their own, so a source using one
# has no fallback when the origin is down.
CATCH_ALL_ALIASES = frozenset({"tar_https"})

# GitHub tarballs still on the catch-all `tar_https:` alias instead of
# `github_files:`, which include/mirrors.yml does mirror. Migrating one is a
# one-word edit, but `url` is part of a downloadable source's cache key, so
# flipping the alias rebuilds the element and everything above it (imath and
# openexr sit low in the graph). Left as-is deliberately; this allowlist only
# exists to stop the count from growing. Shrink it when a rebuild is cheap.
GITHUB_TARBALL_GRANDFATHERED = frozenset(
    {
        "elements/kde-linux-deps/ayatana-ido.bst",
        "elements/kde-linux-deps/cups-browsed.bst",
        "elements/kde-linux-deps/fuse2.bst",
        "elements/kde-linux-deps/imath.bst",
        "elements/kde-linux-deps/jxrlib.bst",
        "elements/kde-linux-deps/leptonica.bst",
        "elements/kde-linux-deps/libappimage.bst",
        "elements/kde-linux-deps/libappindicator-gtk3.bst",
        "elements/kde-linux-deps/libayatana-indicator.bst",
        "elements/kde-linux-deps/noto-fonts-emoji.bst",
        "elements/kde-linux-deps/openexr.bst",
        "elements/kde-linux-deps/squashfuse.bst",
        "elements/kde-linux-deps/tesseract-data-eng.bst",
        "elements/kde-linux-deps/tesseract.bst",
        "elements/kde-linux-deps/xdg-utils-cxx.bst",
    }
)


def _defined_aliases():
    """Alias names from include/aliases.yml (a flat `aliases:` mapping)."""
    aliases = {}
    in_block = False
    for line in ALIASES_YML.read_text().splitlines():
        if line.startswith("aliases:"):
            in_block = True
            continue
        if not in_block:
            continue
        if line and not line.startswith(" "):
            break
        match = ALIAS_DEF_RE.match(line)
        if match:
            aliases[match.group(1)] = match.group(2)
    return aliases


def _source_urls():
    """(repo-relative path, url) for every `url:` in an element."""
    found = []
    for bst in sorted(ELEMENTS.rglob("*.bst")):
        rel = bst.relative_to(REPO).as_posix()
        for line in bst.read_text().splitlines():
            match = URL_RE.match(line)
            if match:
                found.append((rel, match.group(1).strip("'\"")))
    return found


ALIASES = _defined_aliases()
SOURCE_URLS = _source_urls()


def test_aliases_file_is_parsed():
    """Guard the two helpers above: a silent parse failure would make every
    other assertion in this file vacuously true."""
    assert len(ALIASES) > 50, ALIASES
    assert "github_files" in ALIASES
    assert len(SOURCE_URLS) > 100, len(SOURCE_URLS)


def test_no_unaliased_source_urls():
    """Every element source must go through an alias.

    This is BuildStream's `unaliased-url` warning, which project.conf makes
    fatal. A raw URL cannot be mirrored or re-pointed without a rebuild.
    """
    raw = [
        f"{path}: {url}"
        for path, url in SOURCE_URLS
        if url.startswith(("http://", "https://"))
    ]
    assert not raw, "unaliased source URLs (use include/aliases.yml):\n" + "\n".join(raw)


def test_every_alias_used_is_defined():
    """A typo'd alias is only discovered at fetch time, deep into a build."""
    unknown = []
    for path, url in SOURCE_URLS:
        alias = url.split(":", 1)[0]
        if alias not in ALIASES:
            unknown.append(f"{path}: {url}")
    assert not unknown, "undefined source aliases:\n" + "\n".join(unknown)


def test_unaliased_url_is_a_fatal_warning():
    """freedesktop-sdk makes this fatal; so do we. Without it the rule above
    is enforced only by this test and never by BuildStream itself."""
    conf = PROJECT_CONF.read_text()
    match = re.search(r"^fatal-warnings:\n((?:- .*\n)+)", conf, re.MULTILINE)
    assert match, "project.conf declares no fatal-warnings block"
    warnings = {line[2:].strip() for line in match.group(1).splitlines()}
    assert "unaliased-url" in warnings, warnings


def test_catch_all_aliases_have_no_mirror():
    """`tar_https:` is upstream's escape hatch for one-off hosts, and by
    design has nothing to fall back to. If someone ever adds a mirror for it,
    the grandfathering below stops being a real cost and should go."""
    mirrors = MIRRORS_YML.read_text()
    for alias in CATCH_ALL_ALIASES:
        assert not re.search(rf"^\s+{alias}:\s*$", mirrors, re.MULTILINE), alias


def test_no_new_github_tarballs_on_the_catch_all_alias():
    """GitHub tarballs belong on `github_files:`, which include/mirrors.yml
    mirrors, not on the unmirrored `tar_https:` catch-all."""
    offenders = {
        path
        for path, url in SOURCE_URLS
        if url.startswith("tar_https:github.com/")
    }
    new = sorted(offenders - GITHUB_TARBALL_GRANDFATHERED)
    assert not new, (
        "use `github_files:<owner>/<repo>/…` instead of `tar_https:github.com/…` "
        "so include/mirrors.yml applies:\n" + "\n".join(new)
    )


def test_github_tarball_allowlist_has_no_stale_entries():
    """Keep the ratchet honest: once an element is migrated, drop it from the
    allowlist so it can never silently regress."""
    offenders = {
        path
        for path, url in SOURCE_URLS
        if url.startswith("tar_https:github.com/")
    }
    stale = sorted(GITHUB_TARBALL_GRANDFATHERED - offenders)
    assert not stale, (
        "remove from GITHUB_TARBALL_GRANDFATHERED, they no longer need it:\n"
        + "\n".join(stale)
    )
