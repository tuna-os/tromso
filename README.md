# Tromso — KDE Linux OCI/bootc Image

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](https://github.com/tuna-os/tromso/blob/main/LICENSE)

**Tromso** is a BuildStream-based KDE Linux OCI/bootc image, modeled on Project Bluefin's
[`projectbluefin/dakota`](https://github.com/projectbluefin/dakota). It builds KDE Plasma 6 on top
of freedesktop-sdk and publishes a bootable OCI image to `ghcr.io/tuna-os/tromso`.

**Status: Builds successfully and boots to a functional KDE Plasma 6 Wayland desktop.**

> **Attribution.** Tromso reuses configuration and helper scripts derived from
> [`ublue-os/aurora`](https://github.com/ublue-os/aurora) and the former
> `get-aurora-dev` org, under their original licenses. Tromso is **not affiliated
> with Aurora**, and Aurora does not endorse it. The image ships none of Aurora's
> artwork, logos, wallpapers or trademarks. The desktop uses stock KDE Breeze.

## Architecture

Tromso uses one repository. All KDE, Plasma, and freedesktop-sdk `.bst`
elements are in `elements/`. They came from the former `tuna-os/kde-build-meta`
junction repository, which is now archived. This structure prevents nested
junction bugs and stale references between repositories:

```
tuna-os/tromso
├── elements/
│   ├── kde/                  qt6 (~30), frameworks (~70), libs (~17), plasma (~41), apps (~9)
│   ├── kde-linux-deps/       KDE-Linux-specific system dependencies
│   ├── kde-linux-system/     image/initramfs/repart config
│   ├── core-deps/, core/     shared core OS dependencies
│   ├── freedesktop-sdk.bst   external junction (still a real junction — freedesktop-sdk
│   │                         is genuinely upstream, unlike the retired kde-build-meta one)
│   ├── tromso/                Tromso-specific layers (theming, apps, overlays)
│   └── oci/tromso.bst        top-level build target → ghcr.io/tuna-os/tromso
└── Justfile
```

## Quick Start

### Prerequisites

- Podman
- [`just`](https://github.com/casey/just) (task runner)
- ~100 GB of free disk space for the build cache

### Build

```bash
git clone https://github.com/tuna-os/tromso.git
cd tromso

# Background build with live log tailing
just bst-build

# Or foreground build + OCI export
just build
```

### Boot a VM for testing

```bash
# Generate a bootable disk image (requires a completed build)
just generate-bootable-image

# Boot the image in QEMU
just boot-vm

# SSH in (password: tromso)
ssh -p 2222 root@localhost
```

### Useful Justfile recipes

| Recipe | Description |
|---|---|
| `just bst-build` | Background build, logs to `/var/tmp/tromso-build.log` |
| `just build` | Foreground build + OCI export |
| `just log` | Tail the build log |
| `just generate-bootable-image` | Create a bootable raw disk image via bootc |
| `just boot-vm` | Boot the raw image in QEMU (SSH on port 2222, serial on 4444) |
| `just test` | Run local BATS and Pytest unit test suites |
| `just lint` | Run bootc container lint on the built OCI image |
| `just bst <args>` | Run any arbitrary `bst` command inside the build container |

## CI/CD — multi-runner BuildStream

The sole image-build workflow (`.github/workflows/build-tromso-multirunner.yml`)
splits the BuildStream graph across runners, merges the output CAS, builds
the final target, and pushes the result to GHCR:

```
ghcr.io/tuna-os/tromso:latest
ghcr.io/tuna-os/tromso:<date>
ghcr.io/tuna-os/tromso:<git-sha>
```

**How it works:** the plan, core, and dependency chunks run through the shared
`tuna-os/bst-ci` reusable workflow. The `build_final` job merges the chunk CAS
archives, exports the OCI image, adds a signature, and publishes the nightly or
stable tags. Scheduled and manual triggers start this workflow. It is the only
BuildStream publication path, so each successful image uses the same convergent
cache and signer identity.

## Updating KDE Packages

KDE package `.bst` definitions live directly in `elements/kde/`, `elements/kde-linux-deps/`,
etc. — edit them in place and commit, same as any other element. No separate repo or junction
update step.

See `AGENTS.md` for full conventions and workflows.

## Verifying Signatures

GitHub Actions OIDC uses [cosign](https://github.com/sigstore/cosign) to sign OCI
images and live ISOs without a key. Thus, no long-lived signer key can leak or
need rotation.

**OCI images:**

```bash
cosign verify ghcr.io/tuna-os/tromso:latest \
  --certificate-identity-regexp 'https://github.com/tuna-os/tromso/\.github/workflows/build-tromso-multirunner\.yml@.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

**Live ISOs** (the workflow publishes `.sig` and `.cert` beside each dated ISO,
for example `tromso-live-<date>-<sha>.iso.sig`):

```bash
cosign verify-blob tromso-live-<date>-<sha>.iso \
  --certificate tromso-live-<date>-<sha>.iso.cert \
  --signature tromso-live-<date>-<sha>.iso.sig \
  --certificate-identity-regexp 'https://github.com/tuna-os/tromso/\.github/workflows/build-iso\.yml@.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

## References

- **[KDE Linux](https://invent.kde.org/kde-linux/kde-linux)** — the official project for KDE Linux uses mkosi and Arch, not BuildStream. Tromso uses its package selection as a reference, but does not use its build tools.
- **[Project Bluefin dakota](https://github.com/projectbluefin/dakota)** — reference OCI/bootc implementation
- **[gnome-build-meta](https://gitlab.gnome.org/GNOME/gnome-build-meta)** — build patterns reference
- **[freedesktop-sdk](https://freedesktop-sdk.io/)** — base SDK
- **[BuildStream](https://www.buildstream.build/)** — build system

## ISO Builder (merged from tromso-iso)

This repository contains and maintains the tools for the live ISO. Build a
systemd-boot UEFI ISO from the published Tromso payload, then boot it in QEMU:

```bash
just iso-sd-boot tromso
just boot-iso-vnc tromso
```

The default artifact is `output/tromso-live.iso`. Set a different output
directory with `just output_dir=/path/to/output iso-sd-boot tromso`. For the
pipeline architecture, debugging options, and install end-to-end tests, see
[CI & ISO pipeline](docs/ci-and-iso-pipeline.md). To restore a bad `stable`
release, follow
[Roll back a bad stable release](runbooks/rollback-a-bad-stable-release.md).

---

Part of the [TunaOS](https://tunaos.org) ecosystem. [Docs](https://tunaos.org) · [Contribution guide](CONTRIBUTING.md)
