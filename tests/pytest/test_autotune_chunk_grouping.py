"""Unit tests for scripts/autotune-chunk-grouping.py (PR #166).

Covers the pure/isolated logic of the chunk-grouping autotuner added in
tuna-os/tromso#166: ISO timestamp parsing, the ``gh api`` subprocess wrapper,
and the chunk-job filtering/duration/imbalance analysis — all without hitting
the GitHub API (subprocess and module functions are patched).
"""

import importlib.util
import io
import json
import os
import subprocess
import sys
import unittest
from contextlib import redirect_stdout
from datetime import datetime, timedelta, timezone
from unittest.mock import patch

_SCRIPT = os.path.abspath(os.path.join(
    os.path.dirname(__file__), "../../scripts/autotune-chunk-grouping.py"))
_spec = importlib.util.spec_from_file_location("autotune_chunk_grouping", _SCRIPT)
autotune = importlib.util.module_from_spec(_spec)
sys.modules["autotune_chunk_grouping"] = autotune
_spec.loader.exec_module(autotune)


# ── parse_iso_time ───────────────────────────────────────────────────────────

class TestParseIsoTime(unittest.TestCase):
    def test_none_returns_none(self):
        self.assertIsNone(autotune.parse_iso_time(None))

    def test_empty_string_returns_none(self):
        self.assertIsNone(autotune.parse_iso_time(""))

    def test_plain_iso_timestamp(self):
        ts = autotune.parse_iso_time("2026-06-01T10:30:00")
        self.assertEqual(ts, datetime(2026, 6, 1, 10, 30, 0))

    def test_z_suffix_treated_as_utc(self):
        ts = autotune.parse_iso_time("2026-06-01T10:30:00Z")
        self.assertEqual(ts, datetime(2026, 6, 1, 10, 30, 0, tzinfo=timezone.utc))

    def test_offset_timestamp_preserved(self):
        ts = autotune.parse_iso_time("2026-06-01T10:30:00+02:00")
        self.assertEqual(ts.utcoffset(), timedelta(hours=2))

    def test_garbage_string_raises_value_error(self):
        with self.assertRaises(ValueError):
            autotune.parse_iso_time("not-a-timestamp")


# ── fetch_json ───────────────────────────────────────────────────────────────

class TestFetchJson(unittest.TestCase):
    def _fake_run(self, rc, stdout, stderr=""):
        return subprocess.CompletedProcess(
            args=["gh", "api", "x"], returncode=rc,
            stdout=stdout, stderr=stderr)

    def test_success_returns_parsed_json(self):
        payload = {"workflow_runs": [{"id": 1}]}
        with patch("subprocess.run", return_value=self._fake_run(0, json.dumps(payload))):
            self.assertEqual(autotune.fetch_json("repos/x"), payload)

    def test_nonzero_exit_returns_none(self):
        with patch("subprocess.run", return_value=self._fake_run(1, "", "boom")):
            self.assertIsNone(autotune.fetch_json("repos/x"))

    def test_invalid_json_returns_none(self):
        with patch("subprocess.run", return_value=self._fake_run(0, "not json {")):
            self.assertIsNone(autotune.fetch_json("repos/x"))

    def test_builds_expected_endpoint(self):
        with patch("subprocess.run", return_value=self._fake_run(0, "{}")) as run:
            autotune.fetch_json("repos/tuna-os/tromso/actions/runs/42/jobs")
            run.assert_called_once_with(
                ["gh", "api", "repos/tuna-os/tromso/actions/runs/42/jobs"],
                capture_output=True, text=True)


# ── analyze_runs ─────────────────────────────────────────────────────────────

def _chunk_job(name, started, completed, conclusion="success"):
    return {
        "name": name,
        "conclusion": conclusion,
        "started_at": started,
        "completed_at": completed,
    }


def _run(run_id, jobs, created_at="2026-06-01T00:00:00Z", conclusion="success"):
    return {
        "run_id": run_id,
        "created_at": created_at,
        "conclusion": conclusion,
        "jobs": jobs,
    }


class TestAnalyzeRuns(unittest.TestCase):
    def test_none_response_returns_empty(self):
        with patch.object(autotune, "fetch_json", return_value=None):
            self.assertEqual(autotune.analyze_runs("o/r", "wf.yml", 5), [])

    def test_missing_workflow_runs_key_returns_empty(self):
        with patch.object(autotune, "fetch_json", return_value={}):
            self.assertEqual(autotune.analyze_runs("o/r", "wf.yml", 5), [])

    def test_filters_non_chunk_jobs(self):
        data = {"workflow_runs": [{
            "id": 1, "created_at": "2026-06-01T00:00:00Z", "conclusion": "success",
        }]}
        jobs = {"jobs": [
            _chunk_job("multirunner / Build chunk0-libaio",
                       "2026-06-01T10:00:00Z", "2026-06-01T10:30:00Z"),
            _chunk_job("multirunner / Package",           # no "chunk"
                       "2026-06-01T10:00:00Z", "2026-06-01T10:05:00Z"),
            _chunk_job("multirunner / Chunk sync",          # no "build"
                       "2026-06-01T10:00:00Z", "2026-06-01T10:10:00Z"),
        ]}

        def fake_fetch(endpoint):
            return jobs if "jobs" in endpoint else data
        with patch.object(autotune, "fetch_json", side_effect=fake_fetch):
            results = autotune.analyze_runs("o/r", "wf.yml", 5)

        self.assertEqual(len(results), 1)
        chunk_names = [j["name"] for j in results[0]["chunk_jobs"]]
        self.assertEqual(chunk_names, ["multirunner / Build chunk0-libaio"])

    def test_duration_computation(self):
        data = {"workflow_runs": [{
            "id": 7, "created_at": "2026-06-01T00:00:00Z", "conclusion": "success",
        }]}
        jobs = {"jobs": [
            _chunk_job("Build chunk0-libaio",
                       "2026-06-01T10:00:00Z", "2026-06-01T10:30:00Z"),
        ]}

        def fake_fetch(endpoint):
            return jobs if "jobs" in endpoint else data
        with patch.object(autotune, "fetch_json", side_effect=fake_fetch):
            results = autotune.analyze_runs("o/r", "wf.yml", 5)

        chunk = results[0]["chunk_jobs"][0]
        self.assertEqual(chunk["duration_sec"], 1800)
        self.assertEqual(chunk["duration_min"], 30.0)

    def test_imbalance_ratio_reported(self):
        data = {"workflow_runs": [{
            "id": 7, "created_at": "2026-06-01T00:00:00Z", "conclusion": "success",
        }]}
        jobs = {"jobs": [
            _chunk_job("Build chunk0-slow",
                       "2026-06-01T10:00:00Z", "2026-06-01T11:00:00Z"),   # 60m
            _chunk_job("Build chunk1-fast",
                       "2026-06-01T10:00:00Z", "2026-06-01T10:30:00Z"),   # 30m
        ]}

        def fake_fetch(endpoint):
            return jobs if "jobs" in endpoint else data

        buf = io.StringIO()
        with patch.object(autotune, "fetch_json", side_effect=fake_fetch), \
                redirect_stdout(buf):
            results = autotune.analyze_runs("o/r", "wf.yml", 5)

        self.assertEqual(len(results), 1)
        self.assertEqual(len(results[0]["chunk_jobs"]), 2)
        # 60 / 30 -> 2.00x imbalance
        self.assertIn("Imbalance Ratio=2.00x", buf.getvalue())

    def test_zero_duration_jobs_excluded_from_stats(self):
        data = {"workflow_runs": [{
            "id": 7, "created_at": "2026-06-01T00:00:00Z", "conclusion": "success",
        }]}
        jobs = {"jobs": [
            _chunk_job("Build chunk0-libaio",
                       "2026-06-01T10:00:00Z", None),  # never completed
            _chunk_job("Build chunk1-decks",
                       "2026-06-01T10:00:00Z", "2026-06-01T10:30:00Z"),
        ]}

        def fake_fetch(endpoint):
            return jobs if "jobs" in endpoint else data

        buf = io.StringIO()
        with patch.object(autotune, "fetch_json", side_effect=fake_fetch), \
                redirect_stdout(buf):
            results = autotune.analyze_runs("o/r", "wf.yml", 5)

        self.assertEqual(len(results), 1)
        # durations list only contains the completed job (1800s -> 30.0m)
        self.assertIn("Min=30.0m", buf.getvalue())
        self.assertIn("Max=30.0m", buf.getvalue())
        chunk = results[0]["chunk_jobs"]
        self.assertEqual(chunk[0]["duration_sec"], 0)

    def test_run_without_jobs_is_skipped(self):
        data = {"workflow_runs": [{
            "id": 9, "created_at": "2026-06-01T00:00:00Z", "conclusion": "failure",
        }]}

        def fake_fetch(endpoint):
            return {} if "jobs" in endpoint else data
        with patch.object(autotune, "fetch_json", side_effect=fake_fetch):
            self.assertEqual(autotune.analyze_runs("o/r", "wf.yml", 5), [])

    def test_run_without_chunk_jobs_produces_no_result(self):
        data = {"workflow_runs": [{
            "id": 9, "created_at": "2026-06-01T00:00:00Z", "conclusion": "success",
        }]}
        jobs = {"jobs": [
            _chunk_job("multirunner / Package",
                       "2026-06-01T10:00:00Z", "2026-06-01T10:05:00Z"),
        ]}

        def fake_fetch(endpoint):
            return jobs if "jobs" in endpoint else data
        with patch.object(autotune, "fetch_json", side_effect=fake_fetch):
            self.assertEqual(autotune.analyze_runs("o/r", "wf.yml", 5), [])

    def test_multiple_runs_all_analyzed(self):
        data = {"workflow_runs": [
            {"id": 1, "created_at": "2026-06-01T00:00:00Z", "conclusion": "success"},
            {"id": 2, "created_at": "2026-06-02T00:00:00Z", "conclusion": "failure"},
        ]}
        jobs_by_id = {
            1: {"jobs": [_chunk_job("Build chunk0-a",
                                    "2026-06-01T10:00:00Z", "2026-06-01T10:15:00Z")]},
            2: {"jobs": [_chunk_job("Build chunk0-b",
                                    "2026-06-02T10:00:00Z", "2026-06-02T10:20:00Z")]},
        }

        def fake_fetch(endpoint):
            if "jobs" in endpoint:
                return jobs_by_id[int(endpoint.split("/runs/")[1].split("/")[0])]
            return data
        with patch.object(autotune, "fetch_json", side_effect=fake_fetch):
            results = autotune.analyze_runs("o/r", "wf.yml", 5)

        self.assertEqual(len(results), 2)
        self.assertEqual([r["run_id"] for r in results], [1, 2])


if __name__ == "__main__":
    unittest.main()
