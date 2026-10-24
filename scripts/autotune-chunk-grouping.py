#!/usr/bin/env python3
"""
scripts/autotune-chunk-grouping.py

Analyzes recent GitHub Actions run job timings and build log artifacts for
multi-runner builds (`build-tromso-multirunner.yml`), evaluates chunk duration
imbalance, and generates element/chunk weights for auto-tuning `ci-build-matrix.py`.

Usage:
  python3 scripts/autotune-chunk-grouping.py [--repo OWNER/REPO] [--workflow WORKFLOW_NAME_OR_ID] [--limit N]

Options:
  --repo OWNER/REPO        GitHub repository (default: tuna-os/tromso)
  --workflow WORKFLOW      Workflow ID or filename (default: build-tromso-multirunner.yml)
  --limit N                Number of recent workflow runs to analyze (default: 5)
  --output-json PATH       Optional path to write calculated timing weights JSON
  --output-metrics PATH    Optional path to write Prometheus or OpenTelemetry metrics
  --metrics-format FORMAT  Metric format: prometheus or otel (default: prometheus)
"""

import argparse
import json
import os
import subprocess
import sys
from datetime import datetime


def fetch_json(endpoint):
    """Fetch JSON output from GitHub API via `gh api`."""
    cmd = ["gh", "api", endpoint]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"Error executing {' '.join(cmd)}: {res.stderr.strip()}", file=sys.stderr)
        return None
    try:
        return json.loads(res.stdout)
    except json.JSONDecodeError as e:
        print(f"Failed to parse JSON response from {endpoint}: {e}", file=sys.stderr)
        return None


def parse_iso_time(ts_str):
    if not ts_str:
        return None
    # Python 3.11+ handle ISO strings ending with Z
    return datetime.fromisoformat(ts_str.replace("Z", "+00:00"))


def analyze_runs(repo, workflow, limit):
    print(f"Fetching last {limit} runs for workflow '{workflow}' in {repo}...")
    endpoint = f"repos/{repo}/actions/workflows/{workflow}/runs?per_page={limit}"
    data = fetch_json(endpoint)
    if not data or "workflow_runs" not in data:
        print("No workflow runs found or failed to query GitHub API.", file=sys.stderr)
        return []

    runs = data["workflow_runs"]
    results = []

    for run in runs:
        run_id = run["id"]
        created_at = run.get("created_at")
        conclusion = run.get("conclusion")
        print(f"\n--- Run ID: {run_id} ({created_at}) - Conclusion: {conclusion} ---")

        jobs_endpoint = f"repos/{repo}/actions/runs/{run_id}/jobs"
        jobs_data = fetch_json(jobs_endpoint)
        if not jobs_data or "jobs" not in jobs_data:
            continue

        chunk_jobs = []
        for job in jobs_data["jobs"]:
            name = job["name"]
            # Look for matrix chunk jobs e.g. "multirunner / Build chunk0-libaio"
            if "chunk" in name.lower() and "build" in name.lower():
                started_at = parse_iso_time(job.get("started_at"))
                completed_at = parse_iso_time(job.get("completed_at"))
                duration_sec = 0
                if started_at and completed_at:
                    duration_sec = (completed_at - started_at).total_seconds()

                chunk_jobs.append({
                    "name": name,
                    "conclusion": job.get("conclusion"),
                    "duration_sec": duration_sec,
                    "duration_min": round(duration_sec / 60.0, 1),
                })

        if chunk_jobs:
            imbalance_ratio = 0.0
            durations = [j["duration_min"] for j in chunk_jobs if j["duration_sec"] > 0]
            if durations:
                max_d = max(durations)
                min_d = min(durations)
                avg_d = sum(durations) / len(durations)
                imbalance_ratio = (max_d / min_d) if min_d > 0 else 0
                print(f"  Chunk Jobs ({len(chunk_jobs)}): Min={min_d}m, Max={max_d}m, Avg={avg_d:.1f}m, Imbalance Ratio={imbalance_ratio:.2f}x")
                for j in sorted(chunk_jobs, key=lambda x: x["duration_sec"], reverse=True):
                    print(f"    - {j['name']}: {j['duration_min']} min ({j['conclusion']})")

            results.append({
                "run_id": run_id,
                "created_at": created_at,
                "conclusion": conclusion,
                "chunk_jobs": chunk_jobs,
                "imbalance_ratio": round(imbalance_ratio, 2),
            })

    return results


def _escape_prom_label(val):
    """Escape label values according to Prometheus exposition format."""
    return str(val).replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


def format_prometheus_metrics(runs_data, repo="tuna-os/tromso", workflow="build-tromso-multirunner.yml"):
    """Format analyzed run timings into Prometheus exposition text format.

    Generates gauges:
      - tromso_ci_chunk_duration_seconds: Multi-runner chunk job execution duration in seconds
      - tromso_ci_build_status: Workflow run completion status indicator (1 = success, 0 = failure/other)
      - tromso_ci_chunk_imbalance_ratio: Ratio of max to min chunk duration in a workflow run
    """
    lines = [
        "# HELP tromso_ci_chunk_duration_seconds Multi-runner chunk job execution duration in seconds",
        "# TYPE tromso_ci_chunk_duration_seconds gauge",
    ]
    repo_esc = _escape_prom_label(repo)
    wf_esc = _escape_prom_label(workflow)

    for run in runs_data:
        run_id = str(run.get("run_id", ""))
        run_id_esc = _escape_prom_label(run_id)
        for job in run.get("chunk_jobs", []):
            job_name_esc = _escape_prom_label(job.get("name", ""))
            conclusion_esc = _escape_prom_label(job.get("conclusion") or "unknown")
            duration_sec = float(job.get("duration_sec", 0.0))
            lines.append(
                f'tromso_ci_chunk_duration_seconds{{repo="{repo_esc}",workflow="{wf_esc}",run_id="{run_id_esc}",job="{job_name_esc}",conclusion="{conclusion_esc}"}} {duration_sec}'
            )

    lines.extend([
        "# HELP tromso_ci_build_status Status of the workflow run (1 = success, 0 = failure/other)",
        "# TYPE tromso_ci_build_status gauge",
    ])
    for run in runs_data:
        run_id = str(run.get("run_id", ""))
        run_id_esc = _escape_prom_label(run_id)
        conclusion = run.get("conclusion") or "unknown"
        conclusion_esc = _escape_prom_label(conclusion)
        status_val = 1 if conclusion == "success" else 0
        lines.append(
            f'tromso_ci_build_status{{repo="{repo_esc}",workflow="{wf_esc}",run_id="{run_id_esc}",conclusion="{conclusion_esc}"}} {status_val}'
        )

    lines.extend([
        "# HELP tromso_ci_chunk_imbalance_ratio Ratio of max to min chunk duration in a workflow run",
        "# TYPE tromso_ci_chunk_imbalance_ratio gauge",
    ])
    for run in runs_data:
        run_id = str(run.get("run_id", ""))
        run_id_esc = _escape_prom_label(run_id)
        imbalance = float(run.get("imbalance_ratio", 0.0))
        lines.append(
            f'tromso_ci_chunk_imbalance_ratio{{repo="{repo_esc}",workflow="{wf_esc}",run_id="{run_id_esc}"}} {imbalance}'
        )

    return "\n".join(lines) + "\n"


def format_otel_metrics(runs_data, repo="tuna-os/tromso", workflow="build-tromso-multirunner.yml"):
    """Format analyzed run timings into an OpenTelemetry JSON Metrics payload."""
    duration_datapoints = []
    status_datapoints = []
    imbalance_datapoints = []

    for run in runs_data:
        run_id = str(run.get("run_id", ""))
        conclusion = run.get("conclusion") or "unknown"
        status_val = 1 if conclusion == "success" else 0
        imbalance_val = float(run.get("imbalance_ratio", 0.0))

        status_datapoints.append({
            "attributes": [
                {"key": "run_id", "value": {"stringValue": run_id}},
                {"key": "conclusion", "value": {"stringValue": conclusion}},
            ],
            "asInt": status_val,
        })

        imbalance_datapoints.append({
            "attributes": [
                {"key": "run_id", "value": {"stringValue": run_id}},
            ],
            "asDouble": imbalance_val,
        })

        for job in run.get("chunk_jobs", []):
            duration_datapoints.append({
                "attributes": [
                    {"key": "run_id", "value": {"stringValue": run_id}},
                    {"key": "job", "value": {"stringValue": job.get("name", "")}},
                    {"key": "conclusion", "value": {"stringValue": job.get("conclusion") or "unknown"}},
                ],
                "asDouble": float(job.get("duration_sec", 0.0)),
            })

    return {
        "resourceMetrics": [
            {
                "resource": {
                    "attributes": [
                        {"key": "service.name", "value": {"stringValue": "tromso-ci"}},
                        {"key": "vcs.repository.name", "value": {"stringValue": repo}},
                        {"key": "ci.workflow.name", "value": {"stringValue": workflow}},
                    ]
                },
                "scopeMetrics": [
                    {
                        "scope": {
                            "name": "autotune-chunk-grouping",
                            "version": "1.0.0",
                        },
                        "metrics": [
                            {
                                "name": "tromso_ci_chunk_duration_seconds",
                                "description": "Multi-runner matrix chunk build job duration in seconds",
                                "unit": "s",
                                "gauge": {
                                    "dataPoints": duration_datapoints,
                                },
                            },
                            {
                                "name": "tromso_ci_build_status",
                                "description": "Workflow run completion status indicator (1=success, 0=non-success)",
                                "unit": "1",
                                "gauge": {
                                    "dataPoints": status_datapoints,
                                },
                            },
                            {
                                "name": "tromso_ci_chunk_imbalance_ratio",
                                "description": "Ratio of max chunk duration to min chunk duration in a workflow run",
                                "unit": "1",
                                "gauge": {
                                    "dataPoints": imbalance_datapoints,
                                },
                            },
                        ],
                    }
                ],
            }
        ]
    }


def main():
    parser = argparse.ArgumentParser(description="Analyze build-log timing and auto-tune chunk grouping")
    parser.add_argument("--repo", default="tuna-os/tromso", help="GitHub repository (owner/repo)")
    parser.add_argument("--workflow", default="build-tromso-multirunner.yml", help="Workflow name or ID")
    parser.add_argument("--limit", type=int, default=5, help="Number of recent workflow runs to analyze")
    parser.add_argument("--output-json", help="Optional path to write calculated timing weights JSON")
    parser.add_argument("--output-metrics", help="Optional path to write Prometheus or OpenTelemetry metrics")
    parser.add_argument(
        "--metrics-format",
        choices=["prometheus", "otel"],
        default="prometheus",
        help="Format for --output-metrics: prometheus (default) or otel",
    )

    args = parser.parse_args()
    runs_data = analyze_runs(args.repo, args.workflow, args.limit)

    if args.output_json and runs_data:
        os.makedirs(os.path.dirname(os.path.abspath(args.output_json)), exist_ok=True)
        with open(args.output_json, "w") as f:
            json.dump(runs_data, f, indent=2)
        print(f"\nTiming analysis written to {args.output_json}")

    if args.output_metrics:
        os.makedirs(os.path.dirname(os.path.abspath(args.output_metrics)), exist_ok=True)
        if args.metrics_format == "prometheus":
            content = format_prometheus_metrics(runs_data, args.repo, args.workflow)
        else:
            content = json.dumps(format_otel_metrics(runs_data, args.repo, args.workflow), indent=2) + "\n"
        with open(args.output_metrics, "w") as f:
            f.write(content)
        print(f"\nTiming metrics ({args.metrics_format}) written to {args.output_metrics}")


if __name__ == "__main__":
    main()
