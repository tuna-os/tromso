# Tromsø Roadmap

**Last updated**: 2026-10-24 | **Status**: Alpha

Part of the [TunaOS](https://tunaos.org) ecosystem. BuildStream-based KDE Linux distribution.

## Current foundation

- KDE Plasma desktop images built from source with BuildStream
- OCI/bootc images published through the multi-runner pipeline
- Live ISO assembly and publishing maintained directly in this repository
- Nightly and stable channels, including promotion and rollback workflows

The scheduled multi-runner pipeline has published an image on `main`.
The release ladder is still incomplete — see [Release readiness](#release-readiness)
for the passing build evidence and the remaining candidate requirements.

## Alpha → Beta

Beta is an evidence-based release decision, not a date. The maintainer records
the decision after every required gate below is demonstrated on one promotion
candidate. Until then, Tromsø remains Alpha even when individual workflows or
nightly images are available.

**Gates currently satisfied for a single promotion candidate: 0 of 5.**

Passing component runs below are progress, but do not establish a common
candidate commit and immutable digest across the release ladder.

Each gate records whether its evidence has been produced, not whether the
machinery that would produce it exists. A row is only green when a run,
identified by URL, has passed.

| Gate | Required evidence | Current evidence (2026-10-24) |
|---|---|---|
| Build reliability | A successful scheduled multi-runner build whose commit is used by the candidate ISO | Partial: [scheduled run 38684318450](https://github.com/tuna-os/tromso/actions/runs/38684318450) passed on `main` at `bf255ceca900117d733f7691f6f8b15c25cd0bbd`, including `build_final`, image push, signing, and scanning. Candidate ISO linkage remains unproven; the latest build is red (see below) |
| Install validation | Successful ISO boot, plain-install, and encrypted-install runs for the same candidate | Partial: [scheduled LUKS run 39230716090](https://github.com/tuna-os/tromso/actions/runs/39230716090) passed. [Plain run 39398183219](https://github.com/tuna-os/tromso/actions/runs/39398183219) failed; [ISO run 40077050721](https://github.com/tuna-os/tromso/actions/runs/40077050721) skipped. No common passing candidate is established |
| Release operations | One non-forced promotion to `stable`, followed by a successful rollback dry run against a known-good digest | Not demonstrated: [promotion run 38431625178](https://github.com/tuna-os/tromso/actions/runs/38431625178) failed. Record a passing promotion and rollback dry run for the candidate |
| User readiness | Installation, update, recovery, support status, and known-limitations guidance linked from the release | Not demonstrated for a release candidate. The image publication blocker in [#221](https://github.com/tuna-os/tromso/issues/221) is resolved; candidate-specific guidance and the release decision record remain required |
| Desktop experience | Supported KDE Plasma version and preconfigured Flatpak experience pass a documented smoke test | Not demonstrated. Criteria and candidate smoke-test evidence still need to be recorded |

### Release readiness

The original “zero successful builds / image never published” finding in
[#278](https://github.com/tuna-os/tromso/issues/278) and
[#347](https://github.com/tuna-os/tromso/issues/347) is historical. Producer
fixes [#356](https://github.com/tuna-os/tromso/pull/356),
[#359](https://github.com/tuna-os/tromso/pull/359), and
[#361](https://github.com/tuna-os/tromso/pull/361) are merged. Scheduled builds
[38117166169](https://github.com/tuna-os/tromso/actions/runs/38117166169),
[38211848371](https://github.com/tuna-os/tromso/actions/runs/38211848371),
[38359745054](https://github.com/tuna-os/tromso/actions/runs/38359745054),
[38515299527](https://github.com/tuna-os/tromso/actions/runs/38515299527), and
[38684318450](https://github.com/tuna-os/tromso/actions/runs/38684318450)
succeeded on `main` from October 11 through October 15. Publication is no
longer an unmeasurable prerequisite for every other gate.

This does not establish current build health: the October 24
[run 40064106136](https://github.com/tuna-os/tromso/actions/runs/40064106136)
failed in `multirunner / build_core` while configuring `sdk/webkitgtk-6.0.bst`;
chunks and `build_final` were skipped. This is a different failure signature
from the reclaimed chunk runner described in #278's September 3 comment.
Diagnose that build error before selecting a fresh candidate; do not weaken
the failure guard to publish an incomplete build.

The remaining sequence has evidence-based exit conditions:

1. Restore a green scheduled build and record its commit and immutable OCI
   digest. Build a candidate ISO from that same commit/image.
2. Pass ISO boot, plain install, and encrypted install for that candidate.
   The isolated LUKS success above does not substitute for all three.
3. Record the desktop/Flatpak smoke test and link candidate-specific user
   guidance, then demonstrate non-forced promotion and a rollback dry run.
4. Have the maintainer record the Beta decision with all evidence below.

No calendar date is committed for these gates: each depends on the preceding
candidate evidence. Tromsø remains Alpha until the complete record exists.

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
