# Observability audit and telemetry guidelines: TunaOS Tromsø

This document describes logs, metrics, privacy boundaries, and proposed diagnostics for `tuna-os/tromso`.

---

## 1. Executive Summary & Architecture Context

TunaOS Tromsø is an Alpha OS with KDE Plasma 6.
BuildStream (`bst2`) builds it on `freedesktop-sdk` and packages an OCI image for `bootc` (`ghcr.io/tuna-os/tromso`).
The project also produces live ISOs. These outputs do not establish installation or release readiness.

The KDE stack has about 180 packages, plus SDK dependencies.
The workflow, `.github/workflows/build-tromso-multirunner.yml`, uses `tuna-os/bst-ci` across multiple runners.
It separates uncached elements into a core set (`CORE_SPLIT=200`, plus `extra_core_targets`) and parallel chunks.
The chunks publish caches for content-addressable storage (CAS) to GHCR.

The audit below separates local tools from proposals that need approval.

---

## 2. Telemetry Stack Audit & Baseline Status

### 2.1 Remote Backend Configuration
- **Status**: The audit found no external backend or remote collector. Operator targets were none for open-source, kube-native, and commercial services.
- **Data policy**: Do not export telemetry off the host without explicit operator configuration.
  This restriction covers exporters, OTLP endpoints, external daemons, and network beacons in OS images and CI jobs.

### 2.2 Local logs and dashboards
- **BuildStream logs**: Builds write to `/tmp/tromso-build.log`; `just log` follows this file.
  BuildStream stores logs for each element under `~/.cache/buildstream/logs/<project>/<element-name>/<key>.log`.
- **Local dashboard**: `just dashboard` starts a web UI at `http://localhost:8765` through `bst-dashboard.py`.
  The script uses `~/.cache/bst-dashboard/` as its cache.
  It reads `/tmp/tromso-build.log` and the local graph without external endpoints.
- **User service**: `just dashboard-service` creates `~/.config/systemd/user/bst-dashboard.service`.
  It uses `loginctl enable-linger $USER` to keep the service active on dedicated build hosts.
- **Serial diagnostics**: The plain and LUKS gates use `test-plain-install.yml` and `test-luks-install.yml`.
  They write serial output to `/tmp/tromso-qemu-live-serial.log` and `/tmp/tromso-qemu-installed-serial.log`.
  CI retains these logs as job artifacts. Logs are evidence, not proof that a gate passed.

### 2.3 CI durations and coverage
- **Matrix analysis**: `scripts/autotune-chunk-grouping.py` queries recent runs of `build-tromso-multirunner.yml` through `gh api`.
  Invoke it with `just autotune-chunks limit=N`.
  It calculates minimum, maximum, and average durations for chunks, plus the imbalance ratio (`Max / Min`).
- **Coverage**: `codecov.yml` sets targets for test coverage: 45% for the project and 70% for patches, informational.
  The audit found no CI upload to Codecov. These targets have no data.
  [#303](https://github.com/tuna-os/tromso/issues/303) tracks this gap.

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
With `--metrics-format otel`, the tool exports JSON for OTLP `ResourceMetrics` with these service attributes:
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
1. **Cache hits and misses**: Add instrumentation to the plan and build jobs.
   Record the cache status of elements (`cached`, `buildable`, `waiting`).
   A lower hit ratio can show changes to cache keys.
   Check `project.conf` and junction references such as `freedesktop-sdk.bst`.
2. **Slow elements**: Measure durations for these elements from `build-tromso-multirunner.yml`.
   The approximate durations below are historical observations, not current guarantees:
   - `sdk/webkitgtk-6.0.bst`: 249 minutes.
   - `freedesktop-sdk.bst:components/llvm.bst`: 126 minutes.
   - `kde/qt6/qt6-qtdeclarative.bst`: 57 minutes.
   - `kde/qt6/qt6-qtbase.bst`: 43 minutes.
   - `freedesktop-sdk.bst:components/rust.bst`: 35 minutes.

   Consider `extra_core_targets` for elements above 30 minutes that occur in multiple chunks.
   Then `build_core` can build them once and share artifacts through CAS.
3. **Remote execution**: If operators configure `CASD_CLIENT_CERT` and `CASD_CLIENT_KEY` (tromso#311), record remote execution and local fallback.
   This makes unintended fallback visible.

---

### 3.3 Recommendation 3: Dashboard & Alert Definitions

Use these proposed panels and alerts only after operators approve a Prometheus/Grafana backend or an OpenTelemetry collector.

#### Proposed Grafana panels
1. **Chunk durations**: Show each chunk (`chunk0` through `chunk9`) across runs in a bar chart or heatmap.
2. **Imbalance trend**: Plot `tromso_ci_chunk_imbalance_ratio` over time. The proposed target is below `2.0x`.
3. **Success rate**: Show the percentage from `tromso_ci_build_status` over the previous 14 days.
4. **Slow elements**: Show the ten elements with the longest durations per run.

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

1. **Secrets**: Never put credentials in telemetry exports, structured logs, or metric labels. This includes:
   - `GITHUB_TOKEN` and credentials for repository writes.
   - Cosign certificates and ephemeral tokens.
   - Authentication tokens for container registries (`ghcr.io`).
   - CAS client keys and mTLS certificates.
2. **Cardinality**: Use only approved label keys: `repo`, `workflow`, `run_id`, `job`, and `conclusion`.
   Bound label values and retention; run IDs and job names can grow across runs.
   Never use commit messages, full diffs, or stack traces as Prometheus labels.
3. **Change control**: New remote exporters or network endpoints need explicit review and approval from maintainers.
   Preserve the standard PR hold gates.
