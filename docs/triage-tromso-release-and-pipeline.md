# Tromso Release, Junction, and Multi-Runner Autotune Triage

## Overview

This document gives the technical status and decisions for four areas:
release management, upstream junction migration, multi-runner CI optimization,
and namespace cleanup.

## 1. Stable Release Promotion and Nightly Pipeline (Issues #83, #139)

### Status and release gate

The release pipeline for Tromso needs these gates before the first stable
release and publication of its OCI and R2 ISO artifacts:

1. **Multi-runner nightly build (`build-tromso-multirunner.yml`)**: The build
   must complete through `build_final`. It must produce
   `ghcr.io/tuna-os/tromso:latest` and publish the chunk cache packages
   (`cache-tromso-*`).
2. **Live ISO generation (`build-iso.yml`)**: The command
   `just iso-sd-boot tromso` must complete with the payload container.
3. **Automated installation verification**:
   - Run the plain QEMU install test (`Plain Install End-to-End Test`).
   - Run the encrypted LUKS install and unlock test
     (`LUKS Install End-to-End Test`).

### Historical root cause and remediation

- Mismatches in the Shiboken type system blocked generation of the Qt6 and
  PySide6 framework bindings. The affected element is
  `kde/qt6/qt6-pyside6.bst`. The project turned off the Python bindings on
  `kcoreaddons` and `kwidgetsaddons` to unblock the core build graph.
- The team confirmed that the intermittent weekly failures in OpenSSF Scorecard
  came from the upstream action. Consecutive runs completed without changes to
  the code.
- The `promote-stable.yml` workflow runs on a schedule or manual dispatch. It
  validates the latest nightly artifacts before it moves the release bookmark.

## 2. Evaluation of the Upstream KDE BuildStream Junction (Issue #85)

### Findings

- The team evaluated `invent.kde.org/packaging/kde-buildstream` as a possible
  replacement for downstream element maintenance.
- **Evaluation decision**: [ADR 0003](adr/0003-kde-buildstream-upstream-watch.md)
  records the decision to keep it as a watch item. The upstream project is at
  an early stage and does not have the full dependency set for Plasma. It also
  continues to use mkosi to assemble the ISO.
- **Gates for another evaluation**:
  1. A complete native graph of dependencies in BuildStream for the Plasma
     desktop.
  2. Native generation of the ISO in BuildStream without an external mkosi step.
  3. Support for the Tromso boot image, including Plymouth, dracut, and the
     installer.

## 3. Multi-Runner Chunk Autotune and Coverage (Issues #95, #167)

### Implementation

- `scripts/autotune-chunk-grouping.py` uses the GitHub CLI API to analyze the
  durations in historical build logs.
- It gets wall-clock durations for the `build_deps` matrix jobs. It calculates
  the minimum, maximum, average, and imbalance ratio, then writes JSON with
  structured time weights.
- `tests/pytest/test_autotune_chunk_grouping.py` gives test coverage for:
  - ISO-8601 timestamps in UTC, with offsets, or with invalid input.
  - The subprocess wrapper for `gh api`, including errors and invalid JSON.
  - Selection of chunk jobs and wall-clock calculations with mock run data.
  - CLI execution and JSON output.

## 4. Organizational Namespace Migration (Issue #164)

### Updates

- The templates in `files/os-release/os-release.oci.in` use
  `https://github.com/tuna-os/tromso` for `HOME_URL` and `BUG_REPORT_URL`.
- Build recipes and vendor references in `Justfile` and the `.bst` elements
  refer to repositories in the `tuna-os` organization.
