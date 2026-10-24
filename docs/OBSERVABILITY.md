# Observability Stack Audit & Telemetry Guidelines: Tromso

This document provides the observability architecture, telemetry audit baseline, and monitoring recommendations for `tuna-os/tromso`.

---

## 1. Executive Summary & Architecture Context

`tuna-os/tromso` produces a bootable KDE Plasma 6 Linux OS image on top of `freedesktop-sdk` using BuildStream (`bst2`), packaged as a bootc-compatible OCI image (`ghcr.io/tuna-os/tromso`) and companion live installation ISOs.

Due to the size of the KDE Plasma stack (~180 KDE packages plus SDK dependencies), the image build pipeline relies on a distributed multi-runner architecture (`.github/workflows/build-tromso-multirunner.yml`) calling `tuna-os/bst-ci`. Uncached elements are partitioned into a core set (`CORE_SPLIT=200`, plus `extra_core_targets`) and parallel matrix chunks that publish intermediate Content Addressable Storage (CAS) caches to GHCR.

This document audits the current observability facilities, establishes privacy and security boundaries, and provides actionable recommendations for build timing diagnostics, tracing, and metric collection.

---

## 2. Telemetry Stack Audit & Baseline Status

### 2.1 Remote Backend Configuration
- **Status**: No external telemetry backend or remote collector is configured (Operator targets: open-source=none, kube-native=none, commercial=none).
- **Data Flow Policy**: Strict compliance with the TunaOS zero off-box data export policy. No telemetry exporter, OTLP endpoint, external daemon, or network beacon is shipped in the OS image or active in CI runner jobs without explicit operator configuration.

### 2.2 Local Logging & Interactive Dashboards
- **BuildStream Log Stream**: Detailed element builds write to `/var/tmp/tromso-build.log` (monitored in real time via `just log`). Element-specific build logs are archived under `~/.cache/buildstream/logs/<project>/<element-name>/<key>.log`.
- **Local Web Dashboard**: `just dashboard` launches an interactive local web UI (`http://localhost:8765`) using `bst-dashboard.py` (cached at `~/.cache/bst-dashboard/`). It reads `/var/tmp/tromso-build.log` and the local project graph without exposing external endpoints.
- **Systemd User Service**: `just dashboard-service` provisions a persistent systemd user unit (`~/.config/systemd/user/bst-dashboard.service`) with user lingering (`loginctl enable-linger $USER`) for background monitoring on dedicated build workstations.
- **E2E Serial & QEMU Diagnostics**: The plain and LUKS install gates (`test-plain-install.yml`, `test-luks-install.yml`) stream serial console output to `/tmp/tromso-qemu-live-serial.log` and `/tmp/tromso-qemu-installed-serial.log`, archived as CI job artifacts.

### 2.3 CI Timing & Code Coverage Infrastructure
- **Matrix Timing Analysis**: `scripts/autotune-chunk-grouping.py` (invoked via `just autotune-chunks limit=N`) queries the GitHub Actions API via `gh api` to inspect recent runs of `build-tromso-multirunner.yml`. It calculates chunk wall-clock durations (min, max, average) and the duration imbalance ratio (`Max / Min`) to identify stragglers.
- **Code Coverage**: `codecov.yml` defines repository test coverage thresholds (project target: 45%, patch target: 70% informational). Coverage is submitted strictly via standard CI actions without persistent host daemons.

---

## 3. Telemetry & Observability Recommendations

### 3.1 Recommendation 1: CI Build Timing & Matrix Metric Structured Output
`scripts/autotune-chunk-grouping.py` provides exportable metric schemas for Prometheus text exposition and OpenTelemetry (OTel) JSON format via the `--output-metrics` flag (and `just export-ci-metrics`).

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
When formatted as OpenTelemetry JSON (`--metrics-format otel`), the metrics conform to the OTLP ResourceMetrics specification, attaching service attributes:
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
1. **Cache Hit / Miss Ratio Tracking**: Instrument the matrix planning and build jobs to record element cache status (`cached`, `buildable`, `waiting`). A sudden drop in hit ratio indicates cache-key churn (e.g. changes to `project.conf` or upstream junction refs like `freedesktop-sdk.bst`).
2. **Heavy-Element Duration Tracing**: Monitor build durations of heavyweight elements identified in `build-tromso-multirunner.yml`:
   - `sdk/webkitgtk-6.0.bst` (~249 min)
   - `freedesktop-sdk.bst:components/llvm.bst` (~126 min)
   - `kde/qt6/qt6-qtdeclarative.bst` (~57 min)
   - `kde/qt6/qt6-qtbase.bst` (~43 min)
   - `freedesktop-sdk.bst:components/rust.bst` (~35 min)
   Elements requiring > 30 minutes that appear in multiple chunk build paths should be promoted to `extra_core_targets` so they are built once in `build_core` and shared via CAS.
3. **Remote Execution Telemetry**: When remote execution credentials (`CASD_CLIENT_CERT`, `CASD_CLIENT_KEY`) are configured (tromso#311), record build step execution offload vs. local fallback to ensure builds do not quietly fall back to slow local execution.

---

### 3.3 Recommendation 3: Dashboard & Alert Definitions

When an authorized Prometheus/Grafana or OpenTelemetry collector backend is designated by operators, apply the following dashboard layout and alert rules:

#### Recommended Grafana Dashboard Panels
1. **Matrix Chunk Duration Distribution**: Bar chart / heatmap tracking duration of each chunk (`chunk0` through `chunk9`) across workflow runs.
2. **Chunk Imbalance Trend**: Line chart of `tromso_ci_chunk_imbalance_ratio` over time. Targets should remain below `2.0x`.
3. **Build Success Rate**: Single-stat percentage gauge for `tromso_ci_build_status` over the trailing 14 days.
4. **Straggler Element Identification**: Top 10 longest-running elements per build run.

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
   - Cosign signing certificates and ephemeral tokens
   - Container registry authentication tokens (`ghcr.io`)
   - CAS client keys and mTLS certificates
2. **Label Cardinality Bounds**: All metric label keys (`repo`, `workflow`, `run_id`, `job`, `conclusion`) are strictly bounded. Dynamic unbounded parameters (such as raw commit messages, full diff payloads, or stack traces) must never be used as Prometheus label values.
3. **PR & Change Control**: Any change introducing remote metric exporters or network endpoints requires explicit maintainer review and approval under standard PR hold gates.
