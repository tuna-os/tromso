"""Tests for sibling CI and packaging improvements adopted from sibling repos (issue #312)."""

import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]


def test_project_conf_fatal_warnings():
    """project.conf must enforce fatal-warnings on overlaps, unaliased-url, and unstaged-files."""
    content = (REPO / "project.conf").read_text()
    assert "fatal-warnings:" in content
    assert "- overlaps" in content
    assert "- unaliased-url" in content
    assert "- unstaged-files" in content


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
    assert "include/image-version.yml" in content
    var_match = re.search(r"variables:\s*\n\s*\(@\):[\s\S]*?- include/image-version\.yml", content)
    assert var_match is not None, "variables section must include include/image-version.yml"


def test_image_version_file():
    """include/image-version.yml must define expected defaults."""
    content = (REPO / "include" / "image-version.yml").read_text()
    assert "branch:" in content
    assert "image-version:" in content
    assert "commit:" in content
    assert "commit-date-pretty:" in content


def test_generate_image_version_recipe():
    """just/buildstream.just must provide the generate-image-version recipe."""
    content = (REPO / "just" / "buildstream.just").read_text()
    assert "generate-image-version" in content
    assert "include/image-version.yml" in content


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
    content = (REPO / ".github" / "workflows" / "track-bst-sources.yml").read_text()
    assert "Refresh tags in BST source mirrors" in content
    assert "Detect ref regressions" in content
    assert "Capture pre-track refs" in content
