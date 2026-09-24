"""Tests for sibling CI and packaging improvements adopted from sibling repos (issue #312).

The os-release elements take VERSION_ID from ``%{image-version}``, whose
committed default in include/image-version.yml is the local placeholder
``'l.1'``. That is only correct if CI regenerates the file before building the
shipped image, so the tests below check behaviour, not just file contents:

* the ``generate-image-version`` recipe is executed (in a throwaway git repo)
  and must produce a real, commit-dated version that keeps every variable the
  committed default defines;
* every workflow job that runs ``bst build`` must run
  ``just generate-image-version`` first.

Stdlib only: the CI pytest job installs nothing but pytest.
"""

import re
import shutil
import subprocess
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
IMAGE_VERSION_YML = REPO / "include" / "image-version.yml"
BUILDSTREAM_JUST = REPO / "just" / "buildstream.just"
WORKFLOWS = REPO / ".github" / "workflows"

LOCAL_DEFAULT = "l.1"


def _yaml_scalars(text):
    """Parse the flat ``key: value`` mapping include/image-version.yml uses."""
    out = {}
    for line in text.splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        key, _, value = line.partition(":")
        out[key.strip()] = value.strip().strip("'\"")
    return out


def _recipe_body(name):
    """Return the shebang body of a just recipe, dedented, as a bash script."""
    lines = BUILDSTREAM_JUST.read_text().splitlines()
    start = next(i for i, l in enumerate(lines) if re.match(rf"^{re.escape(name)}\b.*:\s*$", l))
    body = []
    for line in lines[start + 1:]:
        if line and not line.startswith(" "):
            break
        body.append(line[4:] if line.startswith("    ") else line)
    return "\n".join(body).rstrip() + "\n"


def _run_generate_image_version(branch):
    """Run the recipe in a scratch git repo seeded with the committed default."""
    assert shutil.which("bash") and shutil.which("git"), "bash and git are required"
    script = _recipe_body("generate-image-version").replace("{{branch}}", branch)
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        (tmp / "include").mkdir()
        shutil.copy(IMAGE_VERSION_YML, tmp / "include" / "image-version.yml")
        env = {
            "PATH": "/usr/local/bin:/usr/bin:/bin",
            "HOME": str(tmp),
            "GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@example.com",
            "GIT_COMMITTER_NAME": "t", "GIT_COMMITTER_EMAIL": "t@example.com",
            "GIT_COMMITTER_DATE": "2026-09-18T12:34:56+02:00",
            "GIT_AUTHOR_DATE": "2026-09-18T12:34:56+02:00",
        }
        subprocess.run(["git", "init", "-q"], cwd=tmp, env=env, check=True)
        subprocess.run(["git", "commit", "-q", "--allow-empty", "-m", "x"], cwd=tmp, env=env, check=True)
        sha = subprocess.run(["git", "rev-parse", "HEAD"], cwd=tmp, env=env, check=True,
                             capture_output=True, text=True).stdout.strip()
        subprocess.run(["bash", "-c", script], cwd=tmp, env=env, check=True, capture_output=True)
        return _yaml_scalars((tmp / "include" / "image-version.yml").read_text()), sha


def _jobs(workflow_text):
    """Split a workflow into {job_id: job_text} using the 2-space job indent."""
    m = re.search(r"^jobs:\n", workflow_text, re.MULTILINE)
    if not m:
        return {}
    body = workflow_text[m.end():]
    parts = re.split(r"^  ([A-Za-z0-9_-]+):[^\n]*\n", body, flags=re.MULTILINE)
    return dict(zip(parts[1::2], parts[2::2]))


def _code_lines(text):
    return [l for l in text.splitlines() if not l.lstrip().startswith("#")]


def _first_index(lines, pattern):
    return next((i for i, l in enumerate(lines) if re.search(pattern, l)), None)


BST_BUILD = r"\bbst\b.*\sbuild\s"
GENERATE = r"\bjust\s+generate-image-version\b"


def test_project_conf_fatal_warnings():
    """unaliased-url (from #264) and unstaged-files are fatal. overlaps is deferred, see docs/adr/0004."""
    content = (REPO / "project.conf").read_text()
    assert content.count("\nfatal-warnings:") == 1, "exactly one fatal-warnings block"
    block = re.search(r"^fatal-warnings:\n((?:- .*\n)+)", content, re.MULTILINE)
    assert block, "fatal-warnings block not found"
    assert "- unaliased-url" in block.group(1)
    assert "- unstaged-files" in block.group(1)


def test_project_conf_connection_config():
    """project.conf artifacts and source-caches must configure connection-config timeouts and retries."""
    content = (REPO / "project.conf").read_text()
    assert "artifacts:" in content
    assert "source-caches:" in content
    assert content.count("connection-config:") >= 2
    assert "keepalive-time: 180" in content
    assert "retry-limit: 5" in content
    assert "retry-delay: 500" in content
    assert "request-timeout: 180" in content


def test_project_conf_includes_image_version():
    """project.conf must include include/image-version.yml under variables."""
    content = (REPO / "project.conf").read_text()
    var_match = re.search(r"variables:\s*\n\s*\(@\):[\s\S]*?- include/image-version\.yml", content)
    assert var_match is not None, "variables section must include include/image-version.yml"


def test_committed_image_version_is_local_default():
    """The committed file is the local placeholder; CI must overwrite it."""
    values = _yaml_scalars(IMAGE_VERSION_YML.read_text())
    assert values["image-version"] == LOCAL_DEFAULT
    for key in ("filesystem-time", "commit", "commit-date-pretty"):
        assert key in values


def test_generate_image_version_resolves_past_local_default():
    """Running the recipe must replace 'l.1' with <branch>.<commit date, UTC>."""
    committed = _yaml_scalars(IMAGE_VERSION_YML.read_text())
    values, sha = _run_generate_image_version("main")
    assert values["image-version"] != LOCAL_DEFAULT
    # 12:34:56+02:00 is 10:34 UTC.
    assert values["image-version"] == "main.202609181034"
    assert values["commit"] == sha
    assert set(values) == set(committed), "generator must write every variable the default defines"
    assert values["filesystem-time"] == committed["filesystem-time"]


def test_generate_image_version_sanitizes_branch():
    """os-release VERSION_ID allows only [a-z0-9._-]."""
    values, _ = _run_generate_image_version("Feat/Some Branch")
    assert re.fullmatch(r"[a-z0-9._-]+", values["image-version"]), values["image-version"]
    assert values["image-version"].startswith("feat-some-branch.")


def test_every_bst_build_job_generates_image_version_first():
    """A job that builds with bst must regenerate the image version before it."""
    build_jobs = []
    for wf in sorted(WORKFLOWS.glob("*.yml")):
        for job, text in _jobs(wf.read_text()).items():
            lines = _code_lines(text)
            build = _first_index(lines, BST_BUILD)
            if build is None:
                continue
            build_jobs.append(f"{wf.name}:{job}")
            gen = _first_index(lines, GENERATE)
            assert gen is not None and gen < build, (
                f"{wf.name} job '{job}' runs bst build without `just generate-image-version` "
                f"before it, so the image would ship VERSION_ID=\"{LOCAL_DEFAULT}\""
            )
    # Guard against the check passing vacuously if the build moves or is renamed.
    assert "build-tromso-multirunner.yml:build_final" in build_jobs, build_jobs
    assert "build-tromso-multirunner.yml:build_final_aarch64" in build_jobs, build_jobs


def test_os_release_uses_image_version():
    """elements/oci/integration/os-release.bst and elements/oci/os-release.bst must use %{image-version}."""
    integration_os_release = (REPO / "elements" / "oci" / "integration" / "os-release.bst").read_text()
    assert 'VERSION_ID="%{image-version}"' in integration_os_release
    assert "OSTREE_VERSION='%{image-version}'" in integration_os_release
    assert "20260428" not in integration_os_release

    oci_os_release = (REPO / "elements" / "oci" / "os-release.bst").read_text()
    assert 'VERSION_ID: "%{image-version}"' in oci_os_release
    assert 'IMAGE_VERSION: "%{image-version}"' in oci_os_release


def test_track_sources_workflow():
    """track-bst-sources.yml must include tag refresh and regression checks."""
    content = (WORKFLOWS / "track-bst-sources.yml").read_text()
    assert "Refresh tags in BST source mirrors" in content
    assert "Detect ref regressions" in content
    assert "Capture pre-track refs" in content
