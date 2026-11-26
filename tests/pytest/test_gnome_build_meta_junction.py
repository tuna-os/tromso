"""Step 5: gnome-build-meta owns the SDK layer.

The local ``elements/sdk`` and ``elements/sdk-deps`` copies are gone; only the
two Tromso-only elements remain. A stale local copy silently diverges from
gnome-51 and reintroduces failures such as the C23 ``strchr`` break in krb5,
so keep this invariant.
"""

import re
from pathlib import Path

import yaml

REPO = Path(__file__).resolve().parents[2]
ELEMENTS = REPO / "elements"
JUNCTION = ELEMENTS / "gnome-build-meta.bst"
LOCAL_SDK = {"gcr-3.bst", "librice.bst"}
DEP_RE = re.compile(
    r"^\s*-\s+(?:filename:\s*)?([A-Za-z0-9_][A-Za-z0-9_/.:-]*\.bst)\s*$"
)


def _load(path):
    with path.open(encoding="utf-8") as handle:
        return yaml.safe_load(handle)


def test_junction_pins_gnome_51_and_overrides_base():
    data = _load(JUNCTION)
    assert data["kind"] == "junction"
    source = data["sources"][0]
    assert source["url"] == "gnome:gnome-build-meta.git"
    assert source["track"] == "gnome-51"
    assert re.fullmatch(r"51\.1-36-g[0-9a-f]{40}", source["ref"])

    overrides = data["config"]["overrides"]
    assert overrides["freedesktop-sdk.bst"] == "freedesktop-sdk.bst"
    assert overrides["plugins/buildstream-plugins.bst"] == "plugins/buildstream-plugins.bst"
    assert (
        overrides["plugins/buildstream-plugins-community.bst"]
        == "plugins/buildstream-plugins-community.bst"
    )


def test_only_tromso_sdk_elements_remain():
    assert {path.name for path in (ELEMENTS / "sdk").glob("*.bst")} == LOCAL_SDK
    assert not (ELEMENTS / "sdk-deps").exists()
    assert not (ELEMENTS / "sdk" / "webkitgtk.inc").exists()


def test_no_local_sdk_or_sdk_deps_dependencies():
    allowed = {f"sdk/{name}" for name in LOCAL_SDK}
    bad = []
    for path in ELEMENTS.rglob("*.bst"):
        for lineno, line in enumerate(
            path.read_text(encoding="utf-8").splitlines(), 1
        ):
            match = DEP_RE.match(line)
            if (
                match
                and match.group(1).startswith(("sdk/", "sdk-deps/"))
                and match.group(1) not in allowed
            ):
                bad.append(f"{path.relative_to(REPO)}:{lineno}: {match.group(1)}")
    assert not bad, (
        "Vendored SDK references found; use gnome-build-meta.bst:sdk/... instead:\n"
        + "\n".join(bad)
    )


def test_fd_sdk_overrides_point_into_the_junction():
    overrides = _load(ELEMENTS / "freedesktop-sdk.bst")["config"]["overrides"]
    assert overrides["components/krb5.bst"] == (
        "gnome-build-meta.bst:sdk/krb5.bst"
    )
    for key, value in overrides.items():
        assert not value.startswith(("sdk/", "sdk-deps/")), (key, value)
    assert (
        sum(value.startswith("gnome-build-meta.bst:sdk/") for value in overrides.values())
        >= 20
    )
