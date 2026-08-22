# Tromsø Roadmap

**Last updated**: 2026-08-22 | **Status**: Alpha

Part of the [TunaOS](https://tunaos.org) ecosystem. BuildStream-based KDE Linux distribution.

## Current foundation

- KDE Plasma desktop images built from source with BuildStream
- OCI/bootc images published through the multi-runner pipeline
- Live ISO assembly and publishing maintained directly in this repository
- Nightly and stable channels, including promotion and rollback workflows

## Alpha → Beta

- **Build reliability** — keep scheduled multi-runner builds converging and
  promote the full image build to a required gate when it is consistently green
- **Install validation** — expand boot, plain-install, and encrypted-install
  end-to-end coverage across supported architectures
- **Release operations** — exercise stable promotion and rollback regularly and
  document recovery procedures
- **User documentation** — publish installation, update, recovery, and known
  limitations guidance
- **KDE Plasma 6.x** — continue tracking supported upstream releases
- **Flatpak integration** — validate the preconfigured application experience

See [CI & ISO pipeline](docs/ci-and-iso-pipeline.md) for the implemented build,
publishing, promotion, and rollback architecture.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
