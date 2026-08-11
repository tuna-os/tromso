"""Unit tests for scripts/autotune-chunk-grouping.py (PR #166).

The autotune script analyses GitHub Actions run timings and emits chunk
grouping weights that influence ci-build-matrix.py. It is pure-ish: the
three core functions (parse_iso_time / fetch_json / analyze_runs) are
isolated and testable with mocked subprocess / API responses.

The script only exists once PR #166 merges; until then these tests skip.
"""

import importlib.util
import sys
from datetime import datetime, timezone
from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "scripts" / "autotune-chunk-grouping.py"

autotune = None
if SCRIPT.exists():
    _spec = importlib.util.spec_from_file_location("autotune_chunk_grouping", SCRIPT)
    autotune = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(autotune)

pytestmark = pytest.mark.skipif(
    autotune is None,
    reason="scripts/autotune-chunk-grouping.py not present (lands with PR #166)",
)


# ─── parse_iso_time ────────────────────────────────────────────────────────────

class TestParseIsoTime:
    def test_none_and_empty_return_none(self):
        assert autotune.parse_iso_time(None) is None
        assert autotune.parse_iso_time("") is None

    def test_z_suffix_parses_as_utc(self):
        dt = autotune.parse_iso_time("2026-08-11T00:22:00Z")
        assert dt == datetime(2026, 8, 11, 0, 22, 0, tzinfo=timezone.utc)
        assert dt.tzinfo is not None

    def test_explicit_offset_parses(self):
        dt = autotune.parse_iso_time("2026-08-11T00:22:00+00:00")
        assert dt == datetime(2026, 8, 11, 0, 22, 0, tzinfo=timezone.utc)

    def test_garbage_raises_value_error(self):
        with pytest.raises(ValueError):
            autotune.parse_iso_time("not-a-timestamp")


# ─── fetch_json ───────────────────────────────────────────────────────────────

class TestFetchJson:
    def test_success_returns_parsed_json(self, monkeypatch):
        class FakeResult:
            returncode = 0
            stdout = '{"ok": true}'
            stderr = ""

        monkeypatch.setattr("subprocess.run", lambda *a, **k: FakeResult())
        assert autotune.fetch_json("repos/x/y") == {"ok": True}

    def test_nonzero_exit_returns_none(self, monkeypatch):
        class FakeResult:
            returncode = 1
            stdout = ""
            stderr = "boom"

        monkeypatch.setattr("subprocess.run", lambda *a, **k: FakeResult())
        assert autotune.fetch_json("repos/x/y") is None

    def test_invalid_json_returns_none(self, monkeypatch):
        class FakeResult:
            returncode = 0
            stdout = "not json"
            stderr = ""

        monkeypatch.setattr("subprocess.run", lambda *a, **k: FakeResult())
        assert autotune.fetch_json("repos/x/y") is None


# ─── analyze_runs ─────────────────────────────────────────────────────────────

def _fake_fetch(runs):
    """Build a fetch_json replacement keyed on the endpoint suffix."""
    jobs_by_run = {str(r["id"]): r.pop("_jobs", []) for r in runs}

    def fetch(endpoint):
        if "/jobs" in endpoint:
            run_id = endpoint.rsplit("/", 2)[-2]
            return {"jobs": jobs_by_run.get(run_id, [])}
        return {"workflow_runs": runs}

    return fetch


class TestAnalyzeRuns:
    def test_no_runs_returns_empty(self, monkeypatch):
        monkeypatch.setattr(autotune, "fetch_json", lambda *a, **k: None)
        assert autotune.analyze_runs("tuna-os/tromso", "wf.yml", 5) == []

    def test_empty_workflow_runs_returns_empty(self, monkeypatch):
        monkeypatch.setattr(autotune, "fetch_json", lambda *a, **k: {"workflow_runs": []})
        assert autotune.analyze_runs("tuna-os/tromso", "wf.yml", 5) == []

    def test_filters_chunk_build_jobs(self, monkeypatch):
        runs = [{
            "id": 100,
            "created_at": "2026-08-11T00:00:00Z",
            "conclusion": "success",
            "_jobs": [
                # Included: name contains both "chunk" and "build" (case-insensitive).
                {"name": "multirunner / Build chunk0-libaio",
                 "started_at": "2026-08-11T00:00:00Z",
                 "completed_at": "2026-08-11T00:05:00Z", "conclusion": "success"},
                {"name": "multirunner / Build chunk1-kmod",
                 "started_at": "2026-08-11T00:00:00Z",
                 "completed_at": "2026-08-11T00:10:00Z", "conclusion": "success"},
                # Excluded: no "chunk".
                {"name": "multirunner / Lint",
                 "started_at": "2026-08-11T00:00:00Z",
                 "completed_at": "2026-08-11T00:01:00Z", "conclusion": "success"},
                # Excluded: no "build".
                {"name": "multirunner / chunk-only-name",
                 "started_at": "2026-08-11T00:00:00Z",
                 "completed_at": "2026-08-11T00:02:00Z", "conclusion": "success"},
            ],
        }]
        monkeypatch.setattr(autotune, "fetch_json", _fake_fetch(runs))
        results = autotune.analyze_runs("tuna-os/tromso", "wf.yml", 5)

        assert len(results) == 1
        chunk_jobs = results[0]["chunk_jobs"]
        assert [j["name"] for j in chunk_jobs] == [
            "multirunner / Build chunk0-libaio",
            "multirunner / Build chunk1-kmod",
        ]

    def test_duration_computation(self, monkeypatch):
        runs = [{
            "id": 200,
            "created_at": "2026-08-11T00:00:00Z",
            "conclusion": "success",
            "_jobs": [
                {"name": "Build chunk0",
                 "started_at": "2026-08-11T00:00:00Z",
                 "completed_at": "2026-08-11T00:05:30Z", "conclusion": "success"},
                {"name": "Build chunk1",
                 "started_at": "2026-08-11T00:00:00Z",
                 "completed_at": "2026-08-11T00:02:45Z", "conclusion": "success"},
            ],
        }]
        monkeypatch.setattr(autotune, "fetch_json", _fake_fetch(runs))
        jobs = autotune.analyze_runs("tuna-os/tromso", "wf.yml", 5)[0]["chunk_jobs"]

        durations = {j["name"]: (j["duration_sec"], j["duration_min"]) for j in jobs}
        assert durations["Build chunk0"] == (330.0, 5.5)
        assert durations["Build chunk1"] == (165.0, 2.8)

    def test_missing_timestamps_yield_zero_duration(self, monkeypatch):
        runs = [{
            "id": 300,
            "created_at": "2026-08-11T00:00:00Z",
            "conclusion": "success",
            "_jobs": [
                {"name": "Build chunk0",
                 "started_at": None, "completed_at": None, "conclusion": "success"},
            ],
        }]
        monkeypatch.setattr(autotune, "fetch_json", _fake_fetch(runs))
        jobs = autotune.analyze_runs("tuna-os/tromso", "wf.yml", 5)[0]["chunk_jobs"]
        assert jobs[0]["duration_sec"] == 0
        assert jobs[0]["duration_min"] == 0

    def test_run_without_jobs_is_skipped(self, monkeypatch):
        runs = [{
            "id": 400,
            "created_at": "2026-08-11T00:00:00Z",
            "conclusion": "success",
            "_jobs": [],  # no chunk jobs → not reported at all
        }]
        monkeypatch.setattr(autotune, "fetch_json", _fake_fetch(runs))
        assert autotune.analyze_runs("tuna-os/tromso", "wf.yml", 5) == []

    def test_results_carry_run_metadata(self, monkeypatch):
        runs = [{
            "id": 500,
            "created_at": "2026-08-11T00:00:00Z",
            "conclusion": "failure",
            "_jobs": [
                {"name": "Build chunk0",
                 "started_at": "2026-08-11T00:00:00Z",
                 "completed_at": "2026-08-11T00:01:00Z", "conclusion": "failure"},
            ],
        }]
        monkeypatch.setattr(autotune, "fetch_json", _fake_fetch(runs))
        result = autotune.analyze_runs("tuna-os/tromso", "wf.yml", 5)[0]
        assert result["run_id"] == 500
        assert result["conclusion"] == "failure"
        assert result["created_at"] == "2026-08-11T00:00:00Z"


# ─── main (output-json path) ──────────────────────────────────────────────────

class TestMain:
    def test_output_json_writes_file(self, monkeypatch, tmp_path):
        out = tmp_path / "timing.json"
        monkeypatch.setattr(
            autotune,
            "analyze_runs",
            lambda *a, **k: [{"run_id": 1, "chunk_jobs": []}],
        )
        monkeypatch.setattr(
            sys, "argv", ["autotune", "--output-json", str(out), "--limit", "1"]
        )
        autotune.main()
        assert out.exists()
        assert json_load(out) == [{"run_id": 1, "chunk_jobs": []}]


def json_load(path):
    import json
    with open(path) as f:
        return json.load(f)
