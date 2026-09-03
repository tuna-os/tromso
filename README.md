# Aurora Tromso — KDE Linux OCI/bootc Image

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](https://github.com/tuna-os/tromso/blob/main/LICENSE)

**Aurora Tromso** is a BuildStream-based KDE Linux OCI/bootc image, modeled on Project Bluefin's
[`projectbluefin/dakota`](https://github.com/projectbluefin/dakota). It builds KDE Plasma 6 on top
of freedesktop-sdk and publishes a bootable OCI image to `ghcr.io/tuna-os/tromso`.

**Status: Builds successfully and boots to a working KDE Plasma 6 Wayland desktop.**

## Architecture

Aurora Tromso is a single repo — all KDE/Plasma/freedesktop-sdk `.bst` elements
live directly in `elements/`, consolidated in from the former `tuna-os/kde-build-meta`
junctioned repo (now archived) to remove a class of junction-nesting bugs and
separate-repo staleness tracking:

```
tuna-os/tromso
├── elements/
│   ├── kde/                  qt6 (~30), frameworks (~70), libs (~17), plasma (~41), apps (~9)
│   ├── kde-linux-deps/       KDE-Linux-specific system dependencies
│   ├── kde-linux-system/     image/initramfs/repart config
│   ├── core-deps/, core/     shared core OS dependencies
│   ├── freedesktop-sdk.bst   external junction (still a real junction — freedesktop-sdk
│   │                         is genuinely upstream, unlike the retired kde-build-meta one)
│   ├── tromso/                Aurora Tromso-specific layers (theming, apps, overlays)
│   └── oci/tromso.bst        top-level build target → ghcr.io/tuna-os/tromso
└── Justfile
```

## Quick Start

### Prerequisites

- Podman
- [`just`](https://github.com/casey/just) (task runner)
- ~100 GB free disk space for build cache

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

# SSH in (password: aurora)
ssh -p 2222 root@localhost
```

### Useful Justfile recipes

| Recipe | Description |
|---|---|
| `just bst-build` | Background build, logs to `/var/tmp/aurora-build.log` |
| `just build` | Foreground build + OCI export |
| `just log` | Tail the build log |
| `just generate-bootable-image` | Create a bootable raw disk image via bootc |
| `just boot-vm` | Boot the raw image in QEMU (SSH on port 2222, serial on 4444) |
| `just test` | Run local BATS and Pytest unit test suites |
| `just lint` | Run bootc container lint on the built OCI image |
| `just bst <args>` | Run any arbitrary `bst` command inside the build container |

## CI/CD — multi-runner BuildStream

The sole image-build workflow (`.github/workflows/build-tromso-multirunner.yml`)
splits the BuildStream graph across runners, merges the resulting CAS, builds
the final target, and pushes the result to GHCR:

```
ghcr.io/tuna-os/tromso:latest
ghcr.io/tuna-os/tromso:<date>
ghcr.io/tuna-os/tromso:<git-sha>
```

**How it works:** planning, core, and dependency chunks run through the shared
`tuna-os/bst-ci` reusable workflow; `build_final` merges the chunk CAS archives,
exports the OCI image, signs it, and publishes the nightly or stable tags.
The workflow runs on its scheduled/manual triggers; it is intentionally the
single BuildStream publication path so every successful image uses the same
convergent cache and signing identity.

## Updating KDE Packages

KDE package `.bst` definitions live directly in `elements/kde/`, `elements/kde-linux-deps/`,
etc. — edit them in place and commit, same as any other element. No separate repo or junction
update step.

See `AGENTS.md` for full conventions and workflows.

## Verifying Signatures

OCI images and live ISOs are signed keylessly with [cosign](https://github.com/sigstore/cosign)
via GitHub Actions OIDC (Sigstore/Fulcio) — no long-lived signing key to leak or rotate.

**OCI images:**

```bash
cosign verify ghcr.io/tuna-os/tromso:latest \
  --certificate-identity-regexp 'https://github.com/tuna-os/tromso/\.github/workflows/build-tromso-multirunner\.yml@.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

**Live ISOs** (`.sig`/`.cert` are published alongside each dated ISO, e.g.
`tromso-live-<date>-<sha>.iso.sig`):

```bash
cosign verify-blob tromso-live-<date>-<sha>.iso \
  --certificate tromso-live-<date>-<sha>.iso.cert \
  --signature tromso-live-<date>-<sha>.iso.sig \
  --certificate-identity-regexp 'https://github.com/tuna-os/tromso/\.github/workflows/build-iso\.yml@.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

## References

- **[KDE Linux](https://invent.kde.org/kde-linux/kde-linux)** — the real official KDE Linux project (mkosi + Arch, not BuildStream); tromso tracks its package selection as a reference point, not its build tooling
- **[Project Bluefin dakota](https://github.com/projectbluefin/dakota)** — reference OCI/bootc implementation
- **[gnome-build-meta](https://gitlab.gnome.org/GNOME/gnome-build-meta)** — build patterns reference
- **[freedesktop-sdk](https://freedesktop-sdk.io/)** — base SDK
- **[BuildStream](https://www.buildstream.build/)** — build system

## ISO Builder (merged from tromso-iso)

The live-ISO tooling is maintained in this repository. Build a systemd-boot
UEFI ISO from the published Tromso payload, then boot it in QEMU:

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

Part of the [TunaOS](https://tunaos.org) ecosystem. [Docs](https://tunaos.org) · [Contributing](CONTRIBUTING.md)
