# Tromsø Roadmap

**Last updated**: 2026-08-29 | **Status**: Alpha

Part of the [TunaOS](https://tunaos.org) ecosystem. BuildStream-based KDE Linux distribution.

## Current foundation

- KDE Plasma desktop images built from source with BuildStream
- OCI/bootc images published through the multi-runner pipeline
- Live ISO assembly and publishing maintained directly in this repository
- Nightly and stable channels, including promotion and rollback workflows

## Alpha → Beta

Beta is an evidence-based release decision, not a date. The maintainer records
the decision after every required gate below is demonstrated on one promotion
candidate. Until then, Tromsø remains Alpha even when individual workflows or
nightly images are available.

| Gate | Required evidence | Current signal (2026-08-29) |
|---|---|---|
| Build reliability | A successful scheduled multi-runner build whose commit is used by the candidate ISO | Implemented; retain the run URL in the release decision |
| Install validation | Successful ISO boot, plain-install, and encrypted-install runs for the same candidate | Workflows exist; stable E2E checks remain the release blocker tracked in [#83](https://github.com/tuna-os/tromso/issues/83) |
| Release operations | One non-forced promotion to `stable`, followed by a successful rollback dry run against a known-good digest | Promotion and rollback workflows exist; no GitHub Release has been published yet |
| User readiness | Installation, update, recovery, support status, and known-limitations guidance linked from the release | Pipeline documentation exists; user-facing guidance is incomplete |
| Desktop experience | Supported KDE Plasma version and preconfigured Flatpak experience pass a documented smoke test | Criteria and evidence record still need to be defined |

### First Beta decision record

The first Beta promotion should publish a short decision record in the GitHub
Release notes containing:

- the candidate commit and immutable OCI digest;
- links to the build, ISO boot, plain-install, and encrypted-install evidence;
- the architectures and hardware/VM configurations actually tested;
- known limitations, support expectations, and rollback instructions; and
- the maintainer approving the promotion.

Issue [#83](https://github.com/tuna-os/tromso/issues/83) is the canonical tracker
for this first stable candidate. The release decision must not be inferred from
nightly freshness or from a moving `latest` tag.

See [CI & ISO pipeline](docs/ci-and-iso-pipeline.md) for the implemented build,
publishing, promotion, and rollback architecture.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
