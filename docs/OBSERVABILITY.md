# Observability Stack Audit & Telemetry Guidelines: Tromso

This document provides the observability architecture, audit baseline for telemetry, and recommendations for monitors in `tuna-os/tromso`.

---

## 1. Executive Summary & Architecture Context

`tuna-os/tromso` produces an OS image with KDE Plasma 6 on top of `freedesktop-sdk` through BuildStream (`bst2`). It packages this bootable Linux image as a bootc-compatible OCI image (`ghcr.io/tuna-os/tromso`) and companion live installation ISOs.

The KDE Plasma stack has about 180 KDE packages and SDK dependencies. Because of this size, the pipeline for image builds uses a distributed multi-runner architecture (`.github/workflows/build-tromso-multirunner.yml`). It calls `tuna-os/bst-ci`. The pipeline partitions the uncached elements into a core set (`CORE_SPLIT=200`, plus `extra_core_targets`) and parallel matrix chunks. These chunks publish the intermediate caches of Content Addressable Storage (CAS) to GHCR.

This document audits the current observability facilities and establishes privacy and security boundaries. It provides actionable recommendations for diagnostics of build durations, traces, and metric collection.

---

## 2. Telemetry Stack Audit & Baseline Status

### 2.1 Remote Backend Configuration
- **Status**: No external backend for telemetry or remote collector has a configuration (Operator targets: open-source=none, kube-native=none, commercial=none).
- **Data Flow Policy**: Strict compliance with the TunaOS policy for zero off-box export of data. The OS image ships no telemetry exporter, OTLP endpoint, external daemon, or network beacon without explicit operator configuration. No such component is active in CI jobs on runners without explicit operator configuration.

### 2.2 Local Logging & Interactive Dashboards
- **BuildStream Log Stream**: Detailed element builds write to `/tmp/tromso-build.log`. Use `just log` to monitor this in real time. BuildStream archives logs for individual elements under `~/.cache/buildstream/logs/<project>/<element-name>/<key>.log`.
- **Local Web Dashboard**: `just dashboard` launches an interactive local UI for the web (`http://localhost:8765`) through `bst-dashboard.py` (cached at `~/.cache/bst-dashboard/`). It reads `/tmp/tromso-build.log` and the local project graph without external endpoints.
- **Systemd User Service**: `just dashboard-service` provisions a persistent user unit for systemd (`~/.config/systemd/user/bst-dashboard.service`). It uses user linger mode (`loginctl enable-linger $USER`) to monitor dedicated build workstations in the background.
- **E2E Serial & QEMU Diagnostics**: The plain and LUKS install gates (`test-plain-install.yml`, `test-luks-install.yml`) stream output from serial consoles to `/tmp/tromso-qemu-live-serial.log` and `/tmp/tromso-qemu-installed-serial.log`. CI archives these logs as job artifacts.

### 2.3 CI Timing & Code Coverage Infrastructure
- **Matrix Duration Analysis**: `scripts/autotune-chunk-grouping.py` (invoked via `just autotune-chunks limit=N`) queries the API for GitHub Actions via `gh api`. It inspects recent runs of `build-tromso-multirunner.yml`. It calculates wall-clock durations of chunks (min, max, average) and the duration imbalance ratio (`Max / Min`) to identify stragglers.
- **Code Coverage**: `codecov.yml` defines thresholds for repository test coverage (project target: 45%, patch target: 70% informational). CI has no workflow that uploads coverage reports to Codecov yet, so these targets receive no data. [#303](https://github.com/tuna-os/tromso/issues/303) tracks this gap.

---

## 3. Telemetry & Observability Recommendations

### 3.1 Recommendation 1: CI Build Timing & Matrix Metric Structured Output
`scripts/autotune-chunk-grouping.py` provides exportable schemas for metrics in Prometheus text exposition and OpenTelemetry (OTel) JSON formats. Use the `--output-metrics` flag (and `just export-ci-metrics`).

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
In OpenTelemetry JSON format (`--metrics-format otel`), the metrics conform to the OTLP ResourceMetrics specification. They attach service attributes:
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

To measure build cache efficiency and pinpoint bottleneck elements:
1. **Cache Hit / Miss Ratio**: Instrument the matrix plan and build jobs to record cache status for elements (`cached`, `buildable`, `waiting`). A sudden drop in hit ratio shows cache-key churn. Examples include changes to `project.conf` or refs for upstream junctions like `freedesktop-sdk.bst`.
2. **Durations of Heavy Elements**: Monitor build durations of heavyweight elements from `build-tromso-multirunner.yml`:
   - `sdk/webkitgtk-6.0.bst` (~249 min)
   - `freedesktop-sdk.bst:components/llvm.bst` (~126 min)
   - `kde/qt6/qt6-qtdeclarative.bst` (~57 min)
   - `kde/qt6/qt6-qtbase.bst` (~43 min)
   - `freedesktop-sdk.bst:components/rust.bst` (~35 min)
   Promote elements that need > 30 minutes and appear in multiple build paths for chunks to `extra_core_targets`. Then `build_core` builds them once and shares them via CAS.
3. **Remote Execution Telemetry**: Remote execution credentials (`CASD_CLIENT_CERT`, `CASD_CLIENT_KEY`) can have a configuration (tromso#311). If so, record offload or fallback to local execution for build steps. This ensures builds do not quietly fall back to slow local execution.

---

### 3.3 Recommendation 3: Dashboard & Alert Definitions

Operators must designate an authorized backend for a Prometheus/Grafana or OpenTelemetry collector first. Then apply the following dashboard layout and alert rules:

#### Recommended Grafana Dashboard Panels
1. **Distribution of Matrix Chunk Durations**: Bar chart / heatmap of durations for each chunk (`chunk0` through `chunk9`) across workflow runs.
2. **Chunk Imbalance Trend**: Line chart of `tromso_ci_chunk_imbalance_ratio` over time. Targets should remain below `2.0x`.
3. **Build Success Rate**: Single-stat percentage gauge for `tromso_ci_build_status` over the trailing 14 days.
4. **Identification of Straggler Elements**: Top 10 elements with the longest durations per build run.

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

1. **Zero Credential Leakage**: Telemetry exports and structured log entries must never log or label secrets, including:
   - `GITHUB_TOKEN` and repository write credentials
   - Cosign certificates for signatures and ephemeral tokens
   - Authentication tokens for container registries (`ghcr.io`)
   - CAS client keys and mTLS certificates
2. **Label Cardinality Bounds**: All metric label keys (`repo`, `workflow`, `run_id`, `job`, `conclusion`) have strict bounds. Never use dynamic unbounded parameters as label values for Prometheus. Examples include raw commit messages, full diff payloads, or stack traces.
3. **PR & Change Control**: Changes that introduce exporters for remote metrics or network endpoints need explicit review and approval from maintainers. Standard PR hold gates apply.
