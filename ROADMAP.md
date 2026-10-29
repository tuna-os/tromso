# Tromsø Roadmap

**Last updated**: 2026-10-25 | **Status**: Alpha

Part of the [TunaOS](https://tunaos.org) ecosystem. BuildStream-based KDE Linux distribution.

## Current foundation

- KDE Plasma desktop images built from source with BuildStream
- OCI/bootc images published through the multi-runner pipeline
- Live ISO assembly and publishing maintained directly in this repository
- Nightly and stable channels, including promotion and rollback workflows

The workflows above are implemented. The scheduled image build has now
succeeded on `main`; the release ladder remains incomplete. See
[Release readiness](#release-readiness) for dated evidence.

## Alpha → Beta

Beta is an evidence-based release decision, not a date. The maintainer records
the decision after every required gate below is demonstrated on one promotion
candidate. Until then, Tromsø remains Alpha even when individual workflows or
nightly images are available.

**Gates demonstrated for one promotion candidate: 0 of 5.**

The table preserves the 2026-09-02 baseline; newer evidence follows below.

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

The zero-green finding in [#278](https://github.com/tuna-os/tromso/issues/278)
is no longer current. The scheduled [2026-10-15 main build](https://github.com/tuna-os/tromso/actions/runs/38684318450)
succeeded, including `build_final`, at commit
`bf255ceca900117d733f7691f6f8b15c25cd0bbd`. The
[2026-10-19 LUKS run](https://github.com/tuna-os/tromso/actions/runs/39230716090)
also succeeded independently. As of 2026-10-25, queries for successful `main`
ISO and plain-install runs still return no results. These independent runs
do not satisfy all five gates for one promotion candidate.

**Release-blocking priority:** restore a fresh successful `build_final` on
`main`, then collect the remaining evidence for that candidate. The
[2026-10-24 build](https://github.com/tuna-os/tromso/actions/runs/40064106136)
failed in `build_core`. Inspect current logs before applying the September
runner-reclaim diagnosis or changing `chunk6-cryptsetup-base`. Other roadmap
work remains secondary until publication is healthy.

The daily `Build Staleness Check` fails when no successful `main` build is
available within 48 hours and maintains an alert issue. While that alert is
open, Tromsø is **not Beta-eligible**. Closure of the historical
[#211](https://github.com/tuna-os/tromso/issues/211) does not permanently clear
freshness: consult the current alert and run evidence. Freshness is a
prerequisite, not a substitute for the five gates or approval to promote.

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
