# Observability Stack Audit & Telemetry Guidelines: Tromso

This document describes the observability architecture, telemetry baseline, and recommendations for `tuna-os/tromso`.

---

## 1. Executive Summary & Architecture Context

`tuna-os/tromso` builds KDE Plasma 6 on `freedesktop-sdk` with BuildStream (`bst2`). It produces a bootc-compatible OCI image (`ghcr.io/tuna-os/tromso`) and companion live ISOs.

The KDE stack has about 180 packages, plus SDK dependencies. The multi-runner pipeline (`.github/workflows/build-tromso-multirunner.yml`) calls `tuna-os/bst-ci`. It divides uncached elements into a core set (`CORE_SPLIT=200`, plus `extra_core_targets`) and parallel chunks. Matrix jobs use GHCR to publish intermediate caches. These caches use content-addressable storage (CAS).

This audit describes existing observability tools and privacy boundaries. It recommends ways to measure build durations, trace steps, and collect metrics.

---

## 2. Telemetry Stack Audit & Baseline Status

### 2.1 Remote Backend Configuration
- **Status**: Operators have configured no external backend or remote collector. Operator targets: open-source=none, kube-native=none, commercial=none.
- **Data Policy**: TunaOS allows no off-box telemetry export by default. Operators must configure exporters for telemetry, OTLP endpoints, external daemons, or network beacons. This applies to the OS image and CI jobs.

### 2.2 Local Logging & Interactive Dashboards
- **BuildStream Logs**: Element builds write to `/tmp/tromso-build.log`. Use `just log` to watch them. BuildStream archives logs for elements under `~/.cache/buildstream/logs/<project>/<element-name>/<key>.log`.
- **Local Dashboard**: `just dashboard` starts a local web UI at `http://localhost:8765`. It uses `bst-dashboard.py`, cached at `~/.cache/bst-dashboard/`. It reads `/tmp/tromso-build.log` and the local graph. It exposes no external endpoints.
- **Systemd User Service**: `just dashboard-service` creates `~/.config/systemd/user/bst-dashboard.service`. It uses `loginctl enable-linger $USER` to keep the dashboard active on build workstations.
- **E2E Diagnostics**: The plain and LUKS install gates write serial output to `/tmp/tromso-qemu-live-serial.log` and `/tmp/tromso-qemu-installed-serial.log`. The `test-plain-install.yml` and `test-luks-install.yml` workflows archive these logs as job artifacts.

### 2.3 CI Timing & Code Coverage Infrastructure
- **Chunk Durations**: `scripts/autotune-chunk-grouping.py` queries recent runs of `build-tromso-multirunner.yml` through `gh api`. Use `just autotune-chunks limit=N` to call it. It calculates minimum, maximum, and average chunk durations. The imbalance ratio (`Max / Min`) helps to identify slow chunks.
- **Code Coverage**: `codecov.yml` sets a 45% project target and a 70% informational patch target. No CI workflow uploads reports to Codecov yet. Issue [#303](https://github.com/tuna-os/tromso/issues/303) tracks this gap.

---

## 3. Telemetry & Observability Recommendations

### 3.1 Recommendation 1: CI Build Timing & Matrix Metric Structured Output
`scripts/autotune-chunk-grouping.py` exports metrics through `--output-metrics`. It supports Prometheus text and OpenTelemetry (OTel) JSON. The `just export-ci-metrics` recipe also exposes this feature.

#### Metric Schema Definition

| Metric Name | Type | Unit | Description | Labels / Attributes |
|---|---|---|---|---|
| `tromso_ci_chunk_duration_seconds` | Gauge | seconds | Wall-clock execution duration of a matrix chunk job | `repo`, `workflow`, `run_id`, `job`, `conclusion` |
| `tromso_ci_build_status` | Gauge | boolean (0/1) | Overall workflow run completion status (1 = success, 0 = failure/other) | `repo`, `workflow`, `run_id`, `conclusion` |
| `tromso_ci_chunk_imbalance_ratio` | Gauge | ratio | Ratio of maximum chunk duration to minimum chunk duration (`Max / Min`) | `repo`, `workflow`, `run_id` |

#### Prometheus Exposition Format Example
```text
# HELP tromso_ci_chunk_duration_seconds Multi-runner chunk job execution duration in seconds
# TYPE tromso_ci_chunk_duration_seconds gauge
tromso_ci_chunk_duration_seconds{repo="tuna-os/tromso",workflow="build-tromso-multirunner.yml",run_id="31235013863",job="multirunner / Build chunk0-libaio",conclusion="success"} 1800.0

# HELP tromso_ci_build_status Status of the workflow run (1 = success, 0 = failure/other)
# TYPE tromso_ci_build_status gauge
tromso_ci_build_status{repo="tuna-os/tromso",workflow="build-tromso-multirunner.yml",run_id="31235013863",conclusion="success"} 1

# HELP tromso_ci_chunk_imbalance_ratio Ratio of max to min chunk duration in a workflow run
# TYPE tromso_ci_chunk_imbalance_ratio gauge
tromso_ci_chunk_imbalance_ratio{repo="tuna-os/tromso",workflow="build-tromso-multirunner.yml",run_id="31235013863"} 1.45
```

#### OpenTelemetry ResourceMetrics Schema
OpenTelemetry JSON (`--metrics-format otel`) follows the OTLP ResourceMetrics specification. It adds these service attributes:
- `service.name`: `tromso-ci`
- `vcs.repository.name`: `tuna-os/tromso`
- `ci.workflow.name`: `build-tromso-multirunner.yml`

#### CLI & Automation Usage
```bash
# Export Prometheus metrics to a file
python3 scripts/autotune-chunk-grouping.py --limit 10 --output-metrics /tmp/metrics.prom --metrics-format prometheus

# Or use the Just recipe
just export-ci-metrics output=/tmp/tromso-ci.prom format=prometheus limit=5

# Export OpenTelemetry JSON metrics
python3 scripts/autotune-chunk-grouping.py --limit 5 --output-metrics /tmp/metrics.json --metrics-format otel
```

---

### 3.2 Recommendation 2: BuildStream Step Tracing & Cache Instrumentation

To measure cache efficiency and find slow elements:
1. **Cache Ratios**: Record cache status (`cached`, `buildable`, `waiting`) in the plan and build jobs. A drop in hit ratio can show cache-key churn. Check changes to `project.conf` or junction references such as `freedesktop-sdk.bst`.
2. **Slow Elements**: Monitor durations of the heavy elements from `build-tromso-multirunner.yml`:
   - `sdk/webkitgtk-6.0.bst` (~249 min)
   - `freedesktop-sdk.bst:components/llvm.bst` (~126 min)
   - `kde/qt6/qt6-qtdeclarative.bst` (~57 min)
   - `kde/qt6/qt6-qtbase.bst` (~43 min)
   - `freedesktop-sdk.bst:components/rust.bst` (~35 min)
   Move elements that take over 30 minutes into `extra_core_targets` if multiple chunks build them. Then `build_core` builds them once and shares them through CAS.
3. **Remote Execution**: After operators configure `CASD_CLIENT_CERT` and `CASD_CLIENT_KEY` (tromso#311), record remote execution and local fallback. This helps to detect unexpected builds on local runners.

---

### 3.3 Recommendation 3: Dashboard & Alert Definitions

Operators must authorize a Prometheus/Grafana or OpenTelemetry backend before use. After authorization, apply these dashboard panels and alert rules:

#### Recommended Grafana Dashboard Panels
1. **Chunk Durations**: A bar chart or heatmap shows durations for each chunk (`chunk0` through `chunk9`) across runs.
2. **Chunk Imbalance Trend**: Line chart of `tromso_ci_chunk_imbalance_ratio` over time. Targets should remain below `2.0x`.
3. **Build Success**: A percentage gauge shows `tromso_ci_build_status` over the trailing 14 days.
4. **Slow Elements**: Show the ten slowest elements for each build.

#### Recommended Prometheus Alert Rules
```yaml
groups:
  - name: tromso_ci_alerts
    rules:
      - alert: TromsoCIChunkImbalanceHigh
        expr: tromso_ci_chunk_imbalance_ratio > 2.5
        for: 1h
        labels:
          severity: warning
        annotations:
          summary: "Tromso CI chunk duration imbalance is elevated (> 2.5x)"
          description: "One or more matrix chunks are taking significantly longer than others. Run `just autotune-chunks` to rebalance chunk weights in `ci-build-matrix.py`."

      - alert: TromsoCIChunkDurationExceeded
        expr: tromso_ci_chunk_duration_seconds > 14400
        for: 15m
        labels:
          severity: critical
        annotations:
          summary: "Matrix chunk execution time exceeded 4 hours"
          description: "Chunk job duration is approaching GitHub Actions runner limits (6 hours). Inspect element cache hits or promote straggler elements to core."

      - alert: TromsoCIBuildFailure
        expr: tromso_ci_build_status == 0
        for: 1h
        labels:
          severity: warning
        annotations:
          summary: "Tromso scheduled multi-runner build failed"
          description: "Daily scheduled run of build-tromso-multirunner.yml failed. Check runner step logs."
```

---

## 4. Governance, Privacy & Security Rules

1. **Secrets**: Never include secrets in telemetry exports, logs, or labels. These secrets include:
   - `GITHUB_TOKEN` and repository write credentials
   - Cosign certificates and ephemeral tokens
   - Authentication tokens for container registries (`ghcr.io`)
   - CAS client keys and mTLS certificates
2. **Label Cardinality**: Bound the values of `repo`, `workflow`, `run_id`, `job`, and `conclusion`. Never use unbounded data such as raw commit messages, full diffs, or stack traces as Prometheus label values.
3. **Change Control**: Changes that add remote exporters or network endpoints need review and approval from maintainers. Standard PR hold gates apply.
