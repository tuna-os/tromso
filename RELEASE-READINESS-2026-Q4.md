# Tromso Release Readiness Strategy — Q4 2026

**Status**: Alpha → Beta Transition Blocked  
**Last Updated**: 2026-09-28  
**Horizon**: Q4 2026 (3-month priority)  
**Owner**: Tromso Maintainers

---

## Executive Summary

Tromso is stuck at Alpha because **0 of 5 Beta release gates are satisfied**. Four gates are blocked on a single root cause: the nightly multi-runner build has never completed successfully in 79 recorded runs (since 2026-05-05). Without a published OCI image, the project cannot validate installations, perform operations testing, or promote to stable.

**Strategic priority**: Unblock the multi-runner build pipeline to publish `ghcr.io/tuna-os/tromso:latest`. This is the critical path to Beta eligibility and community adoption.

---

## Current Release Gates — Evidence Summary

| Gate | Target | Status | Blocker | Issue |
|---|---|---|---|---|
| Build Reliability | 1 successful multi-runner complete | ❌ 0/79 | Chunk build failure ahead of `build_final` | #278 |
| Install Validation (Plain) | Plain install + boot test pass | ❌ 0/49 | No published image to test | #221 |
| Install Validation (LUKS) | Encrypted install + unlock test pass | ❌ 0/71 | No published image to test | #221 |
| Release Operations | Promote to stable, dry-run rollback succeed | ❌ Never executed | `promote-stable.yml` health check fails | #280, #308 |
| Desktop Experience | Plasma + Flatpak smoke test pass | ❌ Not defined | Criteria and evidence record missing | #306 |

**Root cause cascade**:
1. Chunk build fails → `build_final` skipped → no OCI image pushed to GHCR
2. No GHCR image → install tests pull non-existent artifact → both tests fail
3. No artifact to promote → `promote-stable.yml` refuses to proceed
4. No stable release → desktop smoke test criteria undefined

**One fix unblocks four gates.**

---

## Chunk Build Failure — Diagnosis & Remediation

### What we know

- **Failure pattern**: `Build Tromso (Multi-Runner)` runs 270-minute chunks in parallel; 7 of 10 chunks exit at exactly 270 minutes (timeout, no error) in recent runs
- **Current mitigation**: `soft_chunk_budget: true` allows chunks to time out; partial cache is still pushed
- **But** `build_final` guards on `!contains(needs.*.result, 'failure')` — a timed-out chunk does not fail the job, but **any actual build error does**, and that blocks the final assembly
- **Evidence**: No chunk has ever logged a terminal build error that persists across re-runs; all failures are timeout-related or transient infrastructure issues

### Investigation needed

1. **Are chunks hitting a real blocker or just time budget?**
   - Review the last 5 chunk runs: do their logs show a repeating build error (e.g., Python bindings, webkitgtk version conflict) or just "timed out at 270m"?
   - If error: fix the element and re-run one chunk to verify
   - If timeout: proceed to step 2

2. **Can core+chunks complete if we increase the chunk timeout or split them differently?**
   - Autotune script (`scripts/autotune-chunk-grouping.py`) analyzes historical durations
   - Re-analyze the last 10 runs with tighter element grouping
   - Propose new `extra_core_targets` or chunk split ratio to balance load

3. **Can we reduce total run time without changing elements?**
   - Parallel chunk tasks already run on multiple runners
   - `build_final` is single-runner (2-core GitHub-hosted) — assembly, signing, and push take hours
   - Does `build_final` disk space limit cause any re-downloads? (historical issue in run 33295159787)

### Next steps

**Immediate** (1 week):
- [ ] Review last 5 chunk logs for repeating build errors vs. pure timeout
- [ ] File a detailed diagnosis issue if a build error is found; propose element-specific fix
- [ ] If only timeouts: proceed to next phase

**Short-term** (2–3 weeks):
- [ ] Run autotune script on latest 20 runs to identify optimal chunk grouping
- [ ] Test new chunk split locally (if possible) or in a manual workflow_dispatch run
- [ ] Increase chunk timeout if analysis shows no blocker at current limit

**Success criterion**: One complete multi-runner build produces `ghcr.io/tuna-os/tromso:latest` pushed to GHCR.

---

## Gate Unblocking Sequence

Once the image is published, gates unlock in order:

### Phase 1: Build Reliability ✓ (completes with first successful multi-runner run)
- Evidence: Run URL, OCI digest, pushed `ghcr.io/tuna-os/tromso:latest`
- Update ROADMAP.md to record the run

### Phase 2: Install Validation (2–4 days)
- Both plain and encrypted install E2E tests pull `latest`
- If tests fail: debug and fix image issues (missing packages, hardware detection, etc.)
- If tests pass: record test URLs in ROADMAP.md
- **Blocker check**: Do tests need fixes from the build, or are they infrastructure issues?

### Phase 3: Release Operations (3–5 days after Phase 2)
- `promote-stable.yml` validates the candidate and performs dry-run promotion
- First **intentional** move to stable bookmark (not auto-promotion)
- Dry-run rollback against next candidate
- Record decision in GitHub Release notes per template in #279

### Phase 4: User Readiness (in parallel)
- Update README.md to point to actual published `latest` (not a placeholder)
- Publish installation and recovery documentation
- Link support status and known-limitations guidance from release

### Phase 5: Desktop Experience (in parallel)
- Define smoke test criteria (Plasma version, Flatpak integration, input methods)
- Run test suite against candidate image
- Record results in acceptance template

---

## Strategic Decisions & Trade-offs

### Decision 1: Accept soft chunk timeouts for now
**Rationale**: The timeouts are expected given the load (KDE, Qt, webkitgtk build times are inherent). Soft timeouts let us publish partial progress and unblock gates, while the autotune work improves the split for future runs.

**Tradeoff**: `build_final` may assemble partial caches and miss some elements on the first run. If that happens, the next scheduled run resumes with a warmer cache and may complete more of the graph. This is acceptable for nightly builds.

### Decision 2: Release gates document must cite actual run evidence
**Rationale**: The ROADMAP.md explicitly states: "A gate row cites run evidence — a passing run, or an explicit 'never green' with the counts behind it." This prevents gate status from being inferred from workflow existence or issue closure.

**Implication**: Until an actual passing run exists, the gate remains red. Issue closure does not satisfy the gate.

### Decision 3: First Beta decision record must include known limitations
**Per #279**: "The release decision must not be inferred from nightly freshness, from a moving `latest` tag, or from the closure of a tracker."

**Implication**: Beta is a snapshot decision, not a continuous state. Each Beta promotion publishes a decision record with the exact commit, digest, tested architectures, and known limitations. The next build candidate is a new decision cycle.

---

## Risks & Mitigation

| Risk | Impact | Mitigation |
|---|---|---|
| Chunk build errors repeat after timeout fix | Delays Beta indefinitely | Root-cause analysis in Week 1; propose element fix early |
| Install tests reveal image-level bugs | Delays gate 2–3 weeks | Perform early image sanity checks (e.g., boot into emergency shell, test package presence) |
| `promote-stable.yml` health checks continue to fail | Delays gate 3 weeks | Run health check manually on next published image to identify new failures |
| Runner disk space exhausts during `build_final` | Causes multi-hour re-download loops | Monitor free disk space; use `--exclude=sources` in CAS merge (already implemented in latest workflow) |
| Upstream freedesktop-sdk or KDE breaks mid-cycle | Cascades to all gates | Pre-screen upstream changes; pin vulnerable dependencies; have a rollback plan |

---

## Success Metrics

**Q4 2026 Milestone**: Tromso reaches **Beta (2 of 5 gates satisfied)**.

**Minimum viable success**:
- [ ] Gate 1 (Build Reliability): One complete multi-runner run published to GHCR
- [ ] Gate 2 (Install Validation Plain): Plain install E2E test passes against that image
- [ ] Publish first Beta decision record in GitHub Release

**Extended success** (stretch goal):
- [ ] Gate 3 (Release Operations): Stable promotion workflow runs without errors
- [ ] Gate 5 (Desktop Experience): Smoke test criteria defined and test suite passing

---

## Related Issues

- **#278**: Canonical blocker — chunk build never completes
- **#221**: `ghcr.io/tuna-os/tromso:latest` never published
- **#280**: README references non-existent published image
- **#306**: Desktop experience smoke test criteria not defined
- **#308**: `promote-stable.yml` health check failures not root-caused
- **#279**: First Beta decision record template and decision cycle

---

## Appendix: Autotune Analysis Checklist

When re-running the chunk autotune script, verify:

1. **Latest run data captured**: Script pulls the last 20 multi-runner runs from GitHub API
2. **Timeout vs. error distinction**: Filters for wall-clock `duration >= 270m` vs. exit code `!= 0`
3. **Element build times recorded**: For each chunk, sum the `duration` of all element builds
4. **Imbalance ratio calculated**: `(max_chunk_time - min_chunk_time) / avg_chunk_time`
5. **Proposed grouping has no critical path increase**: New split does not exceed current `core_budget_minutes: 300` significantly
6. **High-value core elements identified**: Elements built in 2+ chunks are promoted to core

---

## Timeline

| Week | Action | Owner |
|---|---|---|
| **W1 (Sep 28–Oct 04)** | Chunk failure diagnosis; autotune analysis | Tromso maintainer |
| **W2–3 (Oct 05–18)** | Element fix or chunk split tuning; manual test run | Tromso maintainer |
| **W4 (Oct 19–25)** | Merge fixes; validate next scheduled nightly build | Tromso maintainer + scanner/quality agent |
| **W5–6 (Nov 01–15)** | Install validation tests; release ops workflow tuning | Tromso + QA |
| **W7–8 (Nov 16–30)** | Desktop smoke test definition; Beta decision record | Tromso maintainer |
| **W9 (Dec 01–07)** | Beta 1.0 release; publish decision record | Tromso maintainer |

---

**Approval**: Tromso maintainer  
**Next review**: 2026-10-15 (after diagnostic phase)
