# Tromso issues sweep

Goal: from this fork, work the open tuna-os/tromso issues, open one focused PR per actionable
issue in HuntedRaven7/tromso-1, then revisit every PR and fix CI failures. No local builds.

- [ ] Inspect all open issues and current main state; classify each (actionable / owner-decision / already covered / out of scope)
- [ ] #495 gate ISO publish + self-check to main — investigate
- [ ] #495 implement, verify (no build), open PR
- [ ] #489 remove stable-ref second writer — investigate
- [ ] #489 implement, verify, open PR
- [ ] #487 cover upstream payload paths in policy tests — investigate
- [ ] #487 implement, verify, open PR
- [ ] #479 remove unpinned chunkah checkout — investigate
- [ ] #479 implement, verify, open PR
- [ ] #478 signature policy on installed image — investigate, choose option, implement, open PR
- [ ] #477 development access defaults — investigate, choose option, implement, open PR
- [ ] #472 cross-repo toolchain ownership — classify scope, take feasible local action or report blocked
- [ ] #392 stale build alert — classify (auto-closing), no PR
- [ ] #306 cancel-in-progress eviction — investigate, implement, open PR
- [ ] #286 stable ISO publication gaps — investigate, implement, open PR
- [ ] #284 proto-installer provenance — investigate, implement, open PR
- [ ] Revisit every opened PR: check CI status, fix failures in place, report
