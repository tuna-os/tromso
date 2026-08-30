# Tromso Release, Junction, and Multi-Runner Autotune Triage

## Overview

This document summarizes the technical status, evaluation, and resolution details for Tromso release management, upstream junction migration, multi-runner CI optimization, and namespace cleanup.

## 1. Stable Release Promotion & Nightly Pipeline (Issues #83, #139)

### Status & Release Gate
The Tromso release pipeline requires the following sequential gates before cutting the initial stable release (`:stable` / `:stable-YYYYMMDD` OCI tags and R2 ISO publishing):
1. **Multi-runner nightly build (`build-tromso-multirunner.yml`)**: Unbroken execution through `build_final`, producing `ghcr.io/tuna-os/tromso:latest` and publishing chunk cache packages (`cache-tromso-*`).
2. **Live ISO generation (`build-iso.yml`)**: Successful execution of `just iso-sd-boot tromso` embedding the payload container.
3. **Automated End-to-End Installation Verification**:
   - Plain QEMU install test (`Plain Install End-to-End Test`).
   - LUKS encrypted installation and unlock test (`LUKS Install End-to-End Test`).

### Historical Root Cause & Remediation
- Nightly build blockers were identified in the Qt6/PySide6 framework bindings generation (`kde/qt6/qt6-pyside6.bst` shiboken typesystem mismatches). Python bindings were disabled on affected framework elements (`kcoreaddons`, `kwidgetsaddons`) to unblock the core build graph.
- OpenSSF Scorecard intermittent weekly failures were verified as upstream action flakes that resolved cleanly on consecutive runs without codebase modifications.
- Release promotion workflow `promote-stable.yml` operates on dispatch/cron and automatically validates that latest nightly artifacts are healthy before advancing the release bookmark branch.

## 2. Upstream KDE BuildStream Junction Evaluation (Issue #85)

### Findings
- Upstream project `invent.kde.org/packaging/kde-buildstream` was evaluated for potential junction adoption to replace downstream element maintenance.
- **Evaluation Decision**: Recorded in [ADR 0003](adr/0003-kde-buildstream-upstream-watch.md). Maintained as a watch item because upstream remains in early development, lacks the full Plasma element dependency set (~140+ elements), and continues to depend on mkosi for ISO assembly.
- **Re-evaluation Gates**:
  1. Complete native BuildStream dependency graph covering Plasma desktop components.
  2. Native BuildStream ISO generation without external mkosi wrapping.
  3. Parity with Tromso bootable image requirements (Plymouth, dracut, and installer integration).

## 3. Multi-Runner Chunk Timing Auto-Tuning & Coverage (Issues #95, #167)

### Implementation
- `scripts/autotune-chunk-grouping.py` provides historical build log timing analysis via the GitHub CLI API (`gh api repos/<repo>/actions/runs/<run_id>/jobs`).
- It extracts wall-clock durations for matrix chunk jobs (`build_deps`), calculates duration spread (min, max, average, imbalance ratio), and outputs structured timing weights JSON.
- Unit test suite `tests/pytest/test_autotune_chunk_grouping.py` provides comprehensive test coverage:
  - ISO-8601 timestamp parsing across formats (UTC Z-suffix, offsets, malformed inputs).
  - Subprocess execution wrapper for `gh api` (success, non-zero exits, JSON parsing error resilience).
  - Chunk job filtering and wall-clock calculation logic with mocked run payloads.
  - CLI execution and output JSON serialization.

## 4. Organizational Namespace Migration (Issue #164)

### Updates
- Shipped `files/os-release/os-release.oci.in` templates point to `https://github.com/tuna-os/tromso` for `HOME_URL` and `BUG_REPORT_URL`.
- Build recipe configurations and vendor references across `Justfile` and `.bst` elements reference the `tuna-os` organization repositories.
