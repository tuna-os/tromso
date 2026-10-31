"""Guard: ``just dashboard`` must never run a script fetched from a mutable ref (#271).

The dashboard recipes download developer tooling and execute it as the
maintainer's own user, so the download has to come from an immutable commit
and be checksum-verified before it is installed or run.

Stdlib only: the CI pytest job installs nothing but pytest.
"""

import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
JUSTFILE = (REPO / "Justfile").read_text()
BUILDSTREAM_JUST = (REPO / "just" / "buildstream.just").read_text()


def _const(name):
    m = re.search(rf'^export {name}\s*:=\s*"([^"]*)"', JUSTFILE, re.M)
    assert m, f"{name} is not defined in the Justfile"
    return m.group(1)


def test_dashboard_rev_is_a_full_commit_sha():
    assert re.fullmatch(r"[0-9a-f]{40}", _const("bst_dashboard_rev"))


def test_dashboard_digests_are_sha256():
    for name in ("bst_dashboard_py_sha256", "bst_dashboard_html_sha256"):
        assert re.fullmatch(r"[0-9a-f]{64}", _const(name)), name


def test_no_mutable_ref_fetch():
    assert "bst-dashboard/main" not in BUILDSTREAM_JUST
    for url in re.findall(r"raw\.githubusercontent\.com/\S+", BUILDSTREAM_JUST):
        assert "bst_dashboard_rev" in url, f"unpinned fetch: {url}"
        assert "/main/" not in url and "/master/" not in url


def test_fetch_is_verified_strictly_before_install():
    # --strict: a malformed digest must fail instead of being silently skipped.
    assert "sha256sum -c --strict" in BUILDSTREAM_JUST
    verify = BUILDSTREAM_JUST.index("sha256sum -c --strict - >&2")
    install = BUILDSTREAM_JUST.index('mv -f "$TMP/bst-dashboard.py"')
    assert verify < install


def test_recipes_share_the_verified_fetch():
    for recipe in ("dashboard", "dashboard-service"):
        assert re.search(rf"^{recipe}: _bst-dashboard-fetch$", BUILDSTREAM_JUST, re.M)
    assert re.search(r'^dashboard-update: \(_bst-dashboard-fetch "force"\)$', BUILDSTREAM_JUST, re.M)


def test_service_runs_the_verified_cache_copy():
    assert "${HOME}/.cache/bst-dashboard/bst-dashboard.py --log" in BUILDSTREAM_JUST
    assert "${JUSTDIR}/bst-dashboard.py" not in BUILDSTREAM_JUST
