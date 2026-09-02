# Tromsø Roadmap

**Last updated**: 2026-09-02 | **Status**: Alpha

Part of the [TunaOS](https://tunaos.org) ecosystem. BuildStream-based KDE Linux distribution.

## Current foundation

- KDE Plasma desktop images built from source with BuildStream
- OCI/bootc images published through the multi-runner pipeline
- Live ISO assembly and publishing maintained directly in this repository
- Nightly and stable channels, including promotion and rollback workflows

The workflows above are implemented. None of them has yet completed
successfully on `main` — see [Release readiness](#release-readiness) for the
run-level evidence and the single blocker behind it.

## Alpha → Beta

Beta is an evidence-based release decision, not a date. The maintainer records
the decision after every required gate below is demonstrated on one promotion
candidate. Until then, Tromsø remains Alpha even when individual workflows or
nightly images are available.

**Gates currently satisfied: 0 of 5.**

Each gate records whether its evidence has been produced, not whether the
machinery that would produce it exists. A row is only green when a run,
identified by URL, has passed.

| Gate | Required evidence | Current evidence (2026-09-02) |
|---|---|---|
| Build reliability | A successful scheduled multi-runner build whose commit is used by the candidate ISO | ❌ Never green. 79 recorded runs of `Build Tromso (Multi-Runner)` since 2026-05-05, 0 successes; `build_final` has never executed because a chunk build fails ahead of it |
| Install validation | Successful ISO boot, plain-install, and encrypted-install runs for the same candidate | ❌ Never green. `Plain Install End-to-End Test` 0 of 49 runs passed; `LUKS Install End-to-End Test` 0 of 71. Both pull `ghcr.io/tuna-os/tromso:latest`, which has never been published ([#221](https://github.com/tuna-os/tromso/issues/221)) |
| Release operations | One non-forced promotion to `stable`, followed by a successful rollback dry run against a known-good digest | ❌ Never green. `promote-stable.yml` failed its health check on 7 of 7 scheduled runs (2026-07-21 → 09-01). No `stable` branch exists, and the repository has no releases and no tags |
| User readiness | Installation, update, recovery, support status, and known-limitations guidance linked from the release | ❌ Not met. Pipeline documentation exists; README still documents pulling and verifying an image that has never been published ([#280](https://github.com/tuna-os/tromso/issues/280)) |
| Desktop experience | Supported KDE Plasma version and preconfigured Flatpak experience pass a documented smoke test | ❌ Not met. Criteria and evidence record still need to be defined |

### Release readiness

Four of the five gates are blocked on one root cause, not four independent
problems. A chunk failure in `Build Tromso (Multi-Runner)` skips `build_final`,
so no OCI image is pushed; the ISO workflow chains off that build and skips; the
two end-to-end install tests pull the image that was never pushed and fail; and
`promote-stable.yml` correctly refuses to promote against those results.

[#278](https://github.com/tuna-os/tromso/issues/278) is the canonical tracker
for that blocker. Until one image is published, no other gate can be measured,
and no roadmap row below `Build reliability` can move.

### First Beta decision record

The first Beta promotion should publish a short decision record in the GitHub
Release notes containing:

- the candidate commit and immutable OCI digest;
- links to the build, ISO boot, plain-install, and encrypted-install evidence;
- the architectures and hardware/VM configurations actually tested;
- known limitations, support expectations, and rollback instructions; and
- the maintainer approving the promotion.

[#279](https://github.com/tuna-os/tromso/issues/279) tracks the first stable
candidate and replaces [#83](https://github.com/tuna-os/tromso/issues/83), which
was closed as completed on 2026-08-30 while none of the promotion it describes
had happened. The release decision must not be inferred from nightly freshness,
from a moving `latest` tag, or from the closure of a tracker.

### Keeping this file honest

Two rules apply to every change here:

1. A gate row cites run evidence — a passing run, or an explicit "never green"
   with the counts behind it. The existence of a workflow is not evidence that
   the gate is satisfied.
2. When an issue cited by a gate row is closed, that row is revisited in the
   same change that closes it. This file must never name a closed issue as a
   canonical tracker.

See [CI & ISO pipeline](docs/ci-and-iso-pipeline.md) for the implemented build,
publishing, promotion, and rollback architecture.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
