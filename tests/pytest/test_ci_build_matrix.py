"""Tests for scripts/ci-build-matrix.py.

Tests the pure functions (chunk_list, make_chunk_name, compute_cache_key)
and the get_build_plan function with a mock plan file.
"""

import hashlib
import importlib.util
import os
import sys
import tempfile
from pathlib import Path

# Load ci-build-matrix.py as a module (hyphen in filename prevents regular import)
SCRIPT_PATH = str(Path(__file__).resolve().parent.parent.parent / "scripts" / "ci-build-matrix.py")
spec = importlib.util.spec_from_file_location("ci_build_matrix", SCRIPT_PATH)
ci_build_matrix = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ci_build_matrix)

chunk_list = ci_build_matrix.chunk_list
make_chunk_name = ci_build_matrix.make_chunk_name
compute_cache_key = ci_build_matrix.compute_cache_key
get_build_plan = ci_build_matrix.get_build_plan


class TestChunkList:
    """Tests for chunk_list() — round-robin distribution."""

    def test_empty_list(self):
        assert chunk_list([], 3) == [[], [], []]

    def test_single_chunk(self):
        data = [1, 2, 3]
        result = chunk_list(data, 1)
        assert result == [[1, 2, 3]]

    def test_two_chunks(self):
        data = [1, 2, 3, 4]
        result = chunk_list(data, 2)
        # Round-robin: [1, 3], [2, 4]
        assert result == [[1, 3], [2, 4]]

    def test_more_chunks_than_items(self):
        data = [1, 2]
        result = chunk_list(data, 4)
        assert len(result) == 4
        assert result[0] == [1]
        assert result[1] == [2]
        assert result[2] == []
        assert result[3] == []

    def test_odd_items(self):
        data = [1, 2, 3, 4, 5]
        result = chunk_list(data, 3)
        # Round-robin: [1, 4], [2, 5], [3]
        assert result == [[1, 4], [2, 5], [3]]


class TestMakeChunkName:
    """Tests for make_chunk_name() — descriptive chunk naming."""

    def test_empty_elements(self):
        assert make_chunk_name(0, []) == "chunk0"

    def test_single_element(self):
        elements = [{"name": "oci/layers/bluefin.bst", "state": "wait", "key": "abc"}]
        name = make_chunk_name(1, elements)
        assert name == "chunk1-bluefin"

    def test_extracts_label_from_path(self):
        elements = [{"name": "components/nested/devel/base.bst", "state": "cached", "key": ""}]
        name = make_chunk_name(3, elements)
        assert name == "chunk3-base"


class TestComputeCacheKey:
    """Tests for compute_cache_key() — composite SHA-256."""

    def test_empty_elements(self):
        assert compute_cache_key([]) == ""

    def test_elements_without_keys(self):
        elements = [{"name": "a", "key": ""}, {"name": "b", "key": ""}]
        assert compute_cache_key(elements) == ""

    def test_single_key(self):
        elements = [{"name": "a", "key": "abc123"}]
        expected = hashlib.sha256(b"abc123").hexdigest()
        assert compute_cache_key(elements) == expected

    def test_multiple_keys_sorted(self):
        elements = [
            {"name": "b", "key": "bbb"},
            {"name": "a", "key": "aaa"},
        ]
        # Keys should be sorted
        combined = "aaa\nbbb"
        expected = hashlib.sha256(combined.encode()).hexdigest()
        assert compute_cache_key(elements) == expected

    def test_mixed_keys(self):
        elements = [
            {"name": "a", "key": "aaa"},
            {"name": "b", "key": ""},
            {"name": "c", "key": "ccc"},
        ]
        # Empty keys are filtered out
        combined = "aaa\nccc"
        expected = hashlib.sha256(combined.encode()).hexdigest()
        assert compute_cache_key(elements) == expected


class TestGetBuildPlan:
    """Tests for get_build_plan() — build plan parsing."""

    def test_parse_plan_file(self):
        with tempfile.NamedTemporaryFile(mode="w", suffix=".txt", delete=False) as f:
            f.write(
                "core/glibc.bst||wait||key1\n"
                "core/systemd.bst||wait||key2\n"
                "core/gcc.bst||cached||key3\n"
            )
            plan_file = f.name

        try:
            elements = get_build_plan("target", plan_file=plan_file)
            # Only non-cached elements should be returned
            assert len(elements) == 2
            assert elements[0]["name"] == "core/glibc.bst"
            assert elements[0]["state"] == "wait"
            assert elements[0]["key"] == "key1"
            assert elements[1]["name"] == "core/systemd.bst"
        finally:
            os.unlink(plan_file)

    def test_parse_empty_plan_file(self):
        with tempfile.NamedTemporaryFile(mode="w", suffix=".txt", delete=False) as f:
            f.write("")
            plan_file = f.name

        try:
            elements = get_build_plan("target", plan_file=plan_file)
            assert elements == []
        finally:
            os.unlink(plan_file)

    def test_parse_all_cached(self):
        with tempfile.NamedTemporaryFile(mode="w", suffix=".txt", delete=False) as f:
            f.write("core/all.bst||cached||key1\n")
            plan_file = f.name

        try:
            elements = get_build_plan("target", plan_file=plan_file)
            assert elements == []
        finally:
            os.unlink(plan_file)

    def test_skip_malformed_lines(self):
        with tempfile.NamedTemporaryFile(mode="w", suffix=".txt", delete=False) as f:
            f.write(
                "valid.bst||wait||k1\n"
                "||bad||\n"
                "also-valid.bst||wait||k2\n"
            )
            plan_file = f.name

        try:
            elements = get_build_plan("target", plan_file=plan_file)
            assert len(elements) == 2
            assert elements[0]["name"] == "valid.bst"
            assert elements[1]["name"] == "also-valid.bst"
        finally:
            os.unlink(plan_file)
