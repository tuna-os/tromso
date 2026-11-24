"""One element owns the installed container policy (tuna-os/tromso#478).

Pure source inspection: stdlib only.
"""

from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
ELEMENTS = REPO / "elements"
POLICY = "containers/policy.json"


def test_exactly_one_element_writes_the_container_policy():
    writers = {
        element.relative_to(REPO).as_posix()
        for element in sorted(ELEMENTS.rglob("*.bst"))
        if f'install -Dm644 /dev/stdin "%{{install-root}}/etc/{POLICY}"' in element.read_text()
    }
    assert writers == {"elements/tromso/containers-config.bst"}, writers


def test_vendored_payloads_drop_the_duplicate_policy():
    for name in ("common.bst", "bluefin-common.bst"):
        text = (ELEMENTS / "tromso" / name).read_text()
        assert f'rm -f "%{{install-root}}%{{sysconfdir}}/{POLICY}"' in text, name
        for line in text.splitlines():
            assert f"/etc/{POLICY}" not in line, f"{name}: {line.strip()}"


def test_security_model_matches_the_open_policy():
    policy = (ELEMENTS / "tromso/containers-config.bst").read_text()
    assert '"type": "insecureAcceptAnything"' in policy
    for rule in ("sigstoreSigned", "fulcio", "signedBy"):
        assert rule not in policy
    section = (REPO / "SECURITY.md").read_text().split("## Security Model", 1)[1]
    section = section.split("## Supply Chain Security", 1)[0]
    assert "do not verify the cosign signature" in section
    assert "GHCR over TLS is the only authentication" in section
