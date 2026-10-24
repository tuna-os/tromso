# Tromsø Roadmap

**Last updated**: 2026-09-17 | **Status**: Alpha

September checkpoint refreshed; release evidence audited on **2026-10-24**.

Part of the [TunaOS](https://tunaos.org) ecosystem. BuildStream-based KDE Linux distribution.

## Current foundation

- KDE Plasma desktop images built from source with BuildStream
- OCI/bootc images published through the multi-runner pipeline
- Live ISO assembly and publishing maintained directly in this repository
- Nightly and stable channels, including promotion and rollback workflows

The workflows above are implemented. Scheduled OCI builds have now passed,
but the full release path has not passed for one promotion candidate.
See [Release readiness](#release-readiness) for evidence and open dependencies.

Since the September checkpoint, the repository has also removed Aurora artwork
and branding ([#301](https://github.com/tuna-os/tromso/pull/301)) and adopted the
shared prose check ([#295](https://github.com/tuna-os/tromso/pull/295)). These
changes improve project identity and CI consistency; they do not satisfy a
release gate.

## Alpha → Beta

Beta is an evidence-based release decision, not a date. The maintainer records
the decision after every required gate below is demonstrated on one promotion
candidate. Until then, Tromsø remains Alpha even when individual workflows or
nightly images are available.

**Gates currently satisfied: 0 of 5.**

Each gate records whether its evidence has been produced, not whether the
machinery that would produce it exists. A row is only green when a run,
identified by URL, has passed.

| Gate | Required evidence | Current evidence (audit: 2026-10-24) |
|---|---|---|
| Build reliability | A successful scheduled multi-runner build whose commit is used by the candidate ISO | Pending candidate link. 12 successful `main` runs are recorded. [Scheduled run 38684318450](https://github.com/tuna-os/tromso/actions/runs/38684318450) passed `build_final` on commit `bf255ceca900117d733f7691f6f8b15c25cd0bbd`; ARM64 jobs were skipped. The latest [October 24 build](https://github.com/tuna-os/tromso/actions/runs/40064106136) failed. No matching candidate ISO evidence is recorded here. |
| Install validation | Successful ISO boot, plain-install, and encrypted-install runs for the same candidate | Not met. Latest [ISO run](https://github.com/tuna-os/tromso/actions/runs/40077050721) was skipped; [plain-install run](https://github.com/tuna-os/tromso/actions/runs/39398183219) failed. [LUKS run](https://github.com/tuna-os/tromso/actions/runs/39230716090) passed, but does not establish all three checks for one candidate. Track validation in [#369](https://github.com/tuna-os/tromso/issues/369). |
| Release operations | One non-forced promotion to `stable`, followed by a successful rollback dry run against a known-good digest | Not met. Latest [promotion run](https://github.com/tuna-os/tromso/actions/runs/38431625178) failed. No `main` rollback runs or GitHub releases are recorded. Candidate evidence matching remains tracked by [#309](https://github.com/tuna-os/tromso/issues/309); publication ordering by [#286](https://github.com/tuna-os/tromso/issues/286). |
| User readiness | Installation, update, recovery, support status, and known-limitations guidance linked from the release | Not met. No release exists to carry this guidance. Reconcile README claims with verified artifacts in [#280](https://github.com/tuna-os/tromso/issues/280) and [#362](https://github.com/tuna-os/tromso/issues/362). |
| Desktop experience | Supported KDE Plasma version and preconfigured Flatpak experience pass a documented smoke test | Not met. No candidate smoke-test record is linked. Define criteria and record results with the first candidate in [#279](https://github.com/tuna-os/tromso/issues/279). |

### Release readiness

The September 2 baseline was 0 successful builds out of 79, 0 plain installs
out of 49, and 0 encrypted installs out of 71. Those counts are historical,
not current totals. The build pipeline can now publish an image:
[run 38684318450](https://github.com/tuna-os/tromso/actions/runs/38684318450)
passed its final build job. The resolution of
[#221](https://github.com/tuna-os/tromso/issues/221#issuecomment-6230690079)
also records that both install tests could pull the GHCR image.
The pipeline has published `latest`.

Build reliability still needs attention: the most recent build failed, and
[#392](https://github.com/tuna-os/tromso/issues/392) tracks publication staleness.
[#278](https://github.com/tuna-os/tromso/issues/278) remains open as the historical
build tracker, but is no longer the single dependency for every gate.
[#369](https://github.com/tuna-os/tromso/issues/369) tracks the next step: ISO and
install validation against a published candidate. The successful LUKS result does
not replace a plain-install pass or an ISO boot pass.

The five gates remain unproven **as a set for one promotion candidate**. Record
the candidate commit, immutable image digest, and matching run URLs before
you mark a row satisfied. In particular, resolve the cross-commit evidence risk
in [#309](https://github.com/tuna-os/tromso/issues/309) and the risk from early ISO publication in [#334](https://github.com/tuna-os/tromso/issues/334). A successful
workflow that tested a different image is not candidate evidence.

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

1. Each gate row cites a successful run or states what evidence is missing.
   Include counts and an audit date. The existence of a workflow is not evidence that
   the gate is satisfied.
2. When an issue cited by a gate row is closed, that row is revisited in the
   same change that closes it. This file must never name a closed issue as a
   canonical tracker.

See [CI & ISO pipeline](docs/ci-and-iso-pipeline.md) for the implemented build,
publishing, promotion, and rollback architecture.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
