#!/usr/bin/env python3
"""Summarize successful multi-runner chunk durations from Actions API data.

The planner currently lives in tuna-os/bst-ci, so this report is deliberately
read-only.  It produces a small JSON profile that can be used when a weighted
planner is introduced, without allowing failed or timed-out jobs to skew the
baseline.
"""

from __future__ import annotations

import argparse
import json
import statistics
from pathlib import Path
from typing import Any


def flatten_runs(raw: Any) -> list[dict[str, Any]]:
    """Flatten the page array returned by ``gh api --paginate --slurp``."""
    if isinstance(raw, dict):
        return [raw]
    if not isinstance(raw, list):
        return []
    result: list[dict[str, Any]] = []
    for item in raw:
        result.extend(flatten_runs(item))
    return result


def duration_seconds(job: dict[str, Any]) -> float | None:
    started = job.get("started_at")
    completed = job.get("completed_at")
    if not started or not completed:
        return None
    # GitHub timestamps are ISO-8601 UTC; fromisoformat handles the Z suffix
    # on supported Python versions used by GitHub-hosted runners.
    from datetime import datetime

    start = datetime.fromisoformat(started.replace("Z", "+00:00"))
    end = datetime.fromisoformat(completed.replace("Z", "+00:00"))
    seconds = (end - start).total_seconds()
    return seconds if seconds >= 0 else None


def chunk_name(job_name: str) -> str | None:
    prefix = "multirunner / Build "
    if not job_name.startswith(prefix):
        return None
    name = job_name.removeprefix(prefix)
    return name or None


def build_profile(
    runs: list[dict[str, Any]],
    jobs_by_run: dict[str, list[dict[str, Any]]],
    min_samples: int,
) -> dict[str, Any]:
    samples: dict[str, list[float]] = {}
    source_runs: list[int] = []

    for run in runs:
        run_id = str(run.get("id", ""))
        if not run_id or run.get("status") != "completed":
            continue
        run_used = False
        for job in jobs_by_run.get(run_id, []):
            # Failed jobs are often timeout-censored and would make a chunk
            # look artificially expensive. Only successful observations form
            # the tuning baseline.
            if job.get("conclusion") != "success":
                continue
            name = chunk_name(str(job.get("name", "")))
            duration = duration_seconds(job) if name else None
            if name and duration is not None:
                samples.setdefault(name, []).append(duration)
                run_used = True
        if run_used:
            source_runs.append(int(run_id))

    summary: dict[str, dict[str, float | int]] = {}
    for name, values in sorted(samples.items()):
        summary[name] = {
            "samples": len(values),
            "median_seconds": round(statistics.median(values), 1),
            "p95_seconds": round(statistics.quantiles(values, n=20, method="inclusive")[18], 1)
            if len(values) >= 2
            else round(values[0], 1),
        }

    ready = bool(summary) and all(
        item["samples"] >= min_samples for item in summary.values()
    )
    if ready:
        reason = "enough successful observations for every observed chunk"
    elif not summary:
        reason = "no successful chunk observations found"
    else:
        reason = f"need at least {min_samples} successful observations per chunk"

    return {
        "schema": 1,
        "source_runs": sorted(set(source_runs), reverse=True),
        "summary": summary,
        "ready_for_weighted_planner": ready,
        "reason": reason,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--runs", type=Path, required=True)
    parser.add_argument("--jobs-dir", type=Path, required=True)
    parser.add_argument("--min-samples", type=int, default=3)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    runs = flatten_runs(json.loads(args.runs.read_text()))
    jobs_by_run: dict[str, list[dict[str, Any]]] = {}
    for path in args.jobs_dir.glob("*.json"):
        jobs_by_run[path.stem] = json.loads(path.read_text()).get("jobs", [])

    profile = build_profile(runs, jobs_by_run, args.min_samples)
    rendered = json.dumps(profile, indent=2) + "\n"
    if args.output:
        args.output.write_text(rendered)
    print(rendered, end="")


if __name__ == "__main__":
    main()
