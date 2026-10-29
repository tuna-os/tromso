# Tromsø Roadmap

**Last updated**: 2026-10-24 | **Status**: Alpha

Part of the [TunaOS](https://tunaos.org) ecosystem. BuildStream-based KDE Linux distribution.

## Current foundation

- KDE Plasma desktop images built from source with BuildStream
- OCI/bootc images published through the multi-runner pipeline
- Live ISO assembly and publishing maintained directly in this repository
- Nightly and stable channels, including promotion and rollback workflows

The OCI build and publish foundation is proven: `Build Tromso (Multi-Runner)`
has completed successfully on `main` and publishes images to
`ghcr.io/tuna-os/tromso:latest`. However, live ISO assembly and promotion
workflows have not yet completed successfully on `main` — see
[Release readiness](#release-readiness) for run-level evidence.

## Alpha → Beta

Beta is an evidence-based release decision, not a date. The maintainer records
the decision after every required gate below is demonstrated on one promotion
candidate. Until then, Tromsø remains Alpha even when individual workflows or
nightly images are available.

**Gates currently satisfied: 0 of 5.**

Each gate records whether its evidence has been produced, not whether the
machinery that would produce it exists. A row is only green when a run,
identified by URL, has passed.

| Gate | Required evidence | Current evidence (2026-10-24) |
|---|---|---|
| Build reliability | A successful scheduled multi-runner build whose commit is used by the candidate ISO | ❌ In progress (partial). 12 successful runs (11 scheduled nightlies, 1 dispatch) of `Build Tromso (Multi-Runner)` recorded out of 136 total runs since 2026-05-05. First green run: [37165877326](https://github.com/tuna-os/tromso/actions/runs/37165877326) (2026-10-04); first nightly: [37182042690](https://github.com/tuna-os/tromso/actions/runs/37182042690); latest green nightly: [38684318450](https://github.com/tuna-os/tromso/actions/runs/38684318450) (2026-10-15). `build_final` executes and pushes `ghcr.io/tuna-os/tromso:latest`. However, candidate ISO assembly (`build-iso.yml`) is 0 of 100, so no candidate ISO has completed from a build commit |
| Install validation | Successful ISO boot, plain-install, and encrypted-install runs for the same candidate | ❌ Not met (1 of 3 components green). `LUKS Install End-to-End Test` succeeded against published `ghcr.io/tuna-os/tromso:latest` on 2026-10-19 ([39230716090](https://github.com/tuna-os/tromso/actions/runs/39230716090), 1 of 100 runs passed). `Plain Install End-to-End Test` is 0 of 78 (resolves and installs `:latest`, but boot readiness times out, e.g. [39398183219](https://github.com/tuna-os/tromso/actions/runs/39398183219)). `Build and Publish Tromsø Live ISO` is 0 of 100 (runs fail at Flatpak installation, e.g. [38745970085](https://github.com/tuna-os/tromso/actions/runs/38745970085)). The missing image blocker ([#221](https://github.com/tuna-os/tromso/issues/221)) was resolved and closed on 2026-10-17 |
| Release operations | One non-forced promotion to `stable`, followed by a successful rollback dry run against a known-good digest | ❌ Never green. `promote-stable.yml` failed its health check on 13 of 13 scheduled runs (2026-07-21 → 10-13; run [38431625178](https://github.com/tuna-os/tromso/actions/runs/38431625178) passed the build check but aborted because ISO and Plain install were red). No `stable` branch exists, and the repository has no releases and no tags |
| User readiness | Installation, update, recovery, support status, and known-limitations guidance linked from the release | ❌ Not met. `ghcr.io/tuna-os/tromso:latest` is now published and verifiable, resolving the image availability issue in [#280](https://github.com/tuna-os/tromso/issues/280), but live ISO publication is not yet green and release guidance is not linked from a release |
| Desktop experience | Supported KDE Plasma version and preconfigured Flatpak experience pass a documented smoke test | ❌ Not met. Criteria and evidence record still need to be defined; Flatpak preconfiguration currently fails during live ISO assembly (`install-flatpaks.sh` machine-id error) |

### Release readiness

The single root-cause blocker documented in September — chunk build timeouts in
`Build Tromso (Multi-Runner)` preventing image publication ([#278](https://github.com/tuna-os/tromso/issues/278)) —
was resolved in October. Commit `7ada604` ([#354](https://github.com/tuna-os/tromso/pull/354))
introduced a 200-minute build budget for chunks, followed by CAS streaming and
image build fixes ([#355](https://github.com/tuna-os/tromso/pull/355),
[#356](https://github.com/tuna-os/tromso/pull/356),
[#359](https://github.com/tuna-os/tromso/pull/359),
[#361](https://github.com/tuna-os/tromso/pull/361)).

The multi-runner workflow subsequently achieved 12 successful runs (including 11
scheduled nightlies between 2026-10-04 and 2026-10-15) and published
`ghcr.io/tuna-os/tromso:latest` (manifest digest `sha256:2b89f634081fa2b9221d35af67ba3ba20f3d2ad37a056a6fb38e6d3064e581aa`),
closing [#221](https://github.com/tuna-os/tromso/issues/221).

Publishing the OCI image unblocked downstream consumers:
- On 2026-10-19, `LUKS Install End-to-End Test` ([39230716090](https://github.com/tuna-os/tromso/actions/runs/39230716090))
  passed end-to-end against real artifacts, demonstrating bootc installation, LUKS
  encryption, and graphical boot.
- Downstream blockers are no longer unified under a missing image. Instead, the
  remaining hurdles for Beta readiness have decoupled into distinct follow-ups:
  1. **Candidate Live ISO assembly (`build-iso.yml`)**: No longer skipped;
     triggers via `workflow_run` on successful nightly builds, but fails during
     Flatpak installation in `install-flatpaks.sh` due to an invalid/missing
     machine-id (`Cannot spawn a message bus without a machine-id`, e.g. run
     [38745970085](https://github.com/tuna-os/tromso/actions/runs/38745970085)).
  2. **Plain install boot readiness (`test-plain-install.yml`)**: Installs
     successfully from `:latest`, but the booted QEMU system does not signal
     ready state within 5 minutes (`ERROR: installed system did not reach a ready
     state after 5m`, e.g. run [39398183219](https://github.com/tuna-os/tromso/actions/runs/39398183219)).
  3. **Multi-runner build consistency**: Chunks remain resource-intensive and
     runs post-2026-10-15 have encountered runner reclaims, timeouts, or dependency
     bumps.
  4. **Release promotion**: Gated on upstream checks passing (`promote-stable.yml`
     verified `build ok=0` on run [38431625178](https://github.com/tuna-os/tromso/actions/runs/38431625178),
     but correctly refused promotion due to ISO and plain-install failures).

[#278](https://github.com/tuna-os/tromso/issues/278) remains open as the historical
tracker, but its initial symptom ("zero images ever published") has been cleared.
[#279](https://github.com/tuna-os/tromso/issues/279) continues to track the first stable
candidate.

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
