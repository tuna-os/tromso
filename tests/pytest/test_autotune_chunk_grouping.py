"""Unit tests for scripts/autotune-chunk-grouping.py.

The script analyzes GitHub Actions run/job timings to auto-tune chunk
grouping for multi-runner builds. It is pure Python (no containers,
no display), so the tests run anywhere pytest runs — see the `pytest`
job in .github/workflows/test.yml.

Drafted for issue #167: lands once PR #166 merges the script.
"""

import importlib.util
import os
import subprocess
import sys
from datetime import datetime, timezone

import pytest

# scripts/autotune-chunk-grouping.py has hyphens in its name, so it cannot
# be imported by module name — load it via importlib like test_luks_unlock.py.
_SCRIPT = os.path.abspath(os.path.join(
    os.path.dirname(__file__), "..", "..", "scripts", "autotune-chunk-grouping.py"))

_spec = importlib.util.spec_from_file_location("autotune_chunk_grouping", _SCRIPT)
autotune = importlib.util.module_from_spec(_spec)
sys.modules["autotune_chunk_grouping"] = autotune
_spec.loader.exec_module(autotune)


# ─── parse_iso_time ──────────────────────────────────────────────────────────

def test_parse_iso_time_none_returns_none():
    assert autotune.parse_iso_time(None) is None


def test_parse_iso_time_plain_iso():
    assert autotune.parse_iso_time("2026-08-10T23:11:05") == datetime(2026, 8, 10, 23, 11, 5)


def test_parse_iso_time_z_suffix_is_utc():
    parsed = autotune.parse_iso_time("2026-08-10T23:11:05Z")
    assert parsed == datetime(2026, 8, 10, 23, 11, 5, tzinfo=timezone.utc)


def test_parse_iso_time_garbage_raises():
    # Current behavior: an unparseable timestamp propagates ValueError.
    # (A future hardening pass may want to return None instead.)
    with pytest.raises(ValueError):
        autotune.parse_iso_time("not-a-date")


# ─── fetch_json ──────────────────────────────────────────────────────────────

def test_fetch_json_success(monkeypatch):
    fake = subprocess.CompletedProcess(args=["gh", "api", "x"], returncode=0,
                                       stdout='{"ok": true}', stderr="")
    monkeypatch.setattr(subprocess, "run", lambda *a, **k: fake)
    assert autotune.fetch_json("repos/o/r/actions") == {"ok": True}


def test_fetch_json_nonzero_exit_returns_none(monkeypatch):
    fake = subprocess.CompletedProcess(args=["gh", "api", "x"], returncode=1,
                                       stdout="", stderr="boom")
    monkeypatch.setattr(subprocess, "run", lambda *a, **k: fake)
    assert autotune.fetch_json("repos/o/r/actions") is None


def test_fetch_json_invalid_json_returns_none(monkeypatch):
    fake = subprocess.CompletedProcess(args=["gh", "api", "x"], returncode=0,
                                       stdout="not json", stderr="")
    monkeypatch.setattr(subprocess, "run", lambda *a, **k: fake)
    assert autotune.fetch_json("repos/o/r/actions") is None


def test_fetch_json_empty_stdout_returns_none(monkeypatch):
    fake = subprocess.CompletedProcess(args=["gh", "api", "x"], returncode=0,
                                       stdout="", stderr="")
    monkeypatch.setattr(subprocess, "run", lambda *a, **k: fake)
    assert autotune.fetch_json("repos/o/r/actions") is None


# ─── analyze_runs ────────────────────────────────────────────────────────────

def _run_data(jobs):
    """Build a fake API responder: runs envelope for the runs endpoint,
    job payload for the per-run jobs endpoint."""
    def responder(endpoint):
        if "/jobs" in endpoint:
            return {
                "id": 123,
                "created_at": "2026-08-10T23:00:00Z",
                "conclusion": "success",
                "jobs": jobs,
            }
        return {
            "workflow_runs": [{
                "id": 123,
                "created_at": "2026-08-10T23:00:00Z",
                "conclusion": "success",
            }],
        }
    return responder


def test_analyze_runs_no_data(monkeypatch):
    monkeypatch.setattr(autotune, "fetch_json", lambda endpoint: None)
    assert autotune.analyze_runs("o/r", "wf.yml", 5) == []


def test_analyze_runs_empty_runs(monkeypatch):
    monkeypatch.setattr(autotune, "fetch_json",
                        lambda endpoint: {"workflow_runs": []})
    assert autotune.analyze_runs("o/r", "wf.yml", 5) == []


def test_analyze_runs_filters_non_chunk_jobs(monkeypatch):
    jobs = [
        {"name": "multirunner / Build chunk0-libaio",
         "conclusion": "success",
         "started_at": "2026-08-10T23:00:00Z",
         "completed_at": "2026-08-10T23:02:30Z"},
        {"name": "multirunner / lint",  # not a chunk job -> excluded
         "conclusion": "success",
         "started_at": "2026-08-10T23:00:00Z",
         "completed_at": "2026-08-10T23:01:00Z"},
    ]
    monkeypatch.setattr(autotune, "fetch_json", _run_data(jobs))
    results = autotune.analyze_runs("o/r", "wf.yml", 5)
    assert len(results) == 1
    assert len(results[0]["chunk_jobs"]) == 1
    chunk = results[0]["chunk_jobs"][0]
    assert chunk["name"] == "multirunner / Build chunk0-libaio"
    assert chunk["duration_sec"] == 150.0
    assert chunk["duration_min"] == 2.5


def test_analyze_runs_run_without_chunk_jobs_omitted(monkeypatch):
    jobs = [
        {"name": "multirunner / lint", "conclusion": "success",
         "started_at": "2026-08-10T23:00:00Z",
         "completed_at": "2026-08-10T23:01:00Z"},
    ]
    monkeypatch.setattr(autotune, "fetch_json", _run_data(jobs))
    assert autotune.analyze_runs("o/r", "wf.yml", 5) == []


def test_analyze_runs_missing_timestamps_zero_duration(monkeypatch):
    jobs = [
        {"name": "multirunner / Build chunk0", "conclusion": "success",
         "started_at": None, "completed_at": None},
    ]
    monkeypatch.setattr(autotune, "fetch_json", _run_data(jobs))
    results = autotune.analyze_runs("o/r", "wf.yml", 5)
    assert len(results) == 1
    assert results[0]["chunk_jobs"][0]["duration_sec"] == 0
    assert results[0]["chunk_jobs"][0]["duration_min"] == 0.0


def test_analyze_runs_multiple_chunks_kept(monkeypatch):
    jobs = [
        {"name": "Build chunk0", "conclusion": "success",
         "started_at": "2026-08-10T23:00:00Z",
         "completed_at": "2026-08-10T23:02:00Z"},
        {"name": "Build chunk1", "conclusion": "success",
         "started_at": "2026-08-10T23:00:00Z",
         "completed_at": "2026-08-10T23:04:00Z"},
    ]
    monkeypatch.setattr(autotune, "fetch_json", _run_data(jobs))
    results = autotune.analyze_runs("o/r", "wf.yml", 5)
    assert len(results[0]["chunk_jobs"]) == 2
    durs = sorted(j["duration_sec"] for j in results[0]["chunk_jobs"])
    assert durs == [120.0, 240.0]
