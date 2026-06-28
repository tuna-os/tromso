# Aurora Tromso — Technical Architecture

## Overview

Aurora Tromso is a bootable OCI/bootc image running KDE Plasma 6. It is built with
[BuildStream](https://www.buildstream.build/) on top of freedesktop-sdk, using the same
methodology as [GNOME OS](https://gitlab.gnome.org/GNOME/gnome-build-meta) and
[Project Bluefin dakota](https://github.com/projectbluefin/dakota).

The project uses a two-repo model:

| Repo | Role |
|------|------|
| [`tuna-os/tromso`](https://github.com/tuna-os/tromso) | This repo — Aurora-specific layers, OCI composition, CI |
| [`hanthor/kde-build-meta`](https://github.com/hanthor/kde-build-meta) | KDE `.bst` elements — Qt6, Frameworks, Plasma, Apps, base image |

Reference sources used during development:

| Source | Purpose |
|--------|---------|
| [`invent.kde.org/kde-linux/kde-linux`](https://invent.kde.org/kde-linux/kde-linux) | Authoritative KDE package list and versions |
| [`projectbluefin/dakota`](https://github.com/projectbluefin/dakota) | OCI/bootc composition patterns, Justfile |
| [`GNOME/gnome-build-meta`](https://gitlab.gnome.org/GNOME/gnome-build-meta) | Build infrastructure patterns (bootc, initramfs, etc.) |
| [`freedesktop-sdk`](https://freedesktop-sdk.io/) | Base SDK — Qt6, systemd, kernel, Mesa, pipewire, etc. |

---

## Repository Structure

```
tuna-os/tromso (this repo)
├── project.conf                  # BuildStream project config (name: aurora)
├── Justfile                      # Build recipes (bst, build, boot-vm, etc.)
├── include/
│   └── aliases.yml               # URL aliases (kde:, github:, etc.)
└── elements/
    ├── kde-build-meta.bst        # Junction → hanthor/kde-build-meta (tarball ref)
    ├── gnomeos-deps/
    │   └── bootc.bst             # bootc compiled from source (Rust)
    ├── test.bst                  # Minimal test element
    ├── tromso/                   # Aurora-specific additions over KDE Linux base
    │   ├── deps.bst              # Master stack of all Aurora additions
    │   ├── system-config.bst     # dbus, sshd, networkd, system users
    │   ├── containers-config.bst # containers policy.json for bootc runtime
    │   ├── ldconfig-paths.bst    # ld.so.conf.d for Qt6 libraries in /usr/lib
    │   ├── hardware-enablement.bst  # android-udev, iio-sensor-proxy, etc.
    │   ├── bluefin-common.bst    # Bluefin-compatible common payload
    │   ├── common.bst            # Aurora branding and config
    │   ├── logos.bst             # Aurora logos
    │   ├── wallpapers.bst        # Aurora wallpapers
    │   ├── docs.bst              # Documentation
    │   ├── brew.bst              # Homebrew (Linuxbrew) integration
    │   ├── tailscale.bst         # Tailscale VPN
    │   ├── image-overlay.bst     # Aurora image overlay files
    │   ├── multimedia-overrides.bst  # Codec/multimedia config overrides
    │   ├── fcitx5-cluster.bst    # Input method support (CJK, etc.)
    │   ├── sudo-rs.bst           # sudo-rs to preserve setuid binary
    │   ├── kcm_ublue.bst         # KDE Control Module for ublue-style settings
    │   ├── krunner-bazaar.bst    # KRunner plugin for Bazaar
    │   └── kde-linux-noto-fontconfig.bst  # Noto font configuration for SDDM
    └── oci/
        ├── tromso.bst            # ← Main build target
        ├── tromso-ostree.bst     # OSTree variant
        ├── os-release.bst        # Aurora os-release (overrides KDE Linux)
        ├── kde-linux/            # KDE Linux base image composition
        │   ├── image.bst         # Parent OCI image (from kde-build-meta)
        │   ├── stack.bst         # KDE Linux full stack
        │   └── filesystem.bst    # Filesystem layout
        └── layers/
            ├── tromso.bst        # Aurora OCI layer (depends on tromso/deps)
            ├── tromso-runtime.bst
            └── tromso-stack.bst  # Combined: kde-linux/stack + tromso/deps
```

`hanthor/kde-build-meta` mirrors the role of `gnome-build-meta`:

```
hanthor/kde-build-meta
└── elements/kde/
    ├── qt6/         (~30 elements — Qt6 base, declarative, multimedia, etc.)
    ├── frameworks/  (~70 elements — kcoreaddons, kio, kirigami, kwin deps, etc.)
    ├── libs/        (~17 elements — libkscreen, qcoro, phonon, etc.)
    ├── plasma/      (~41 elements — plasma-workspace, kwin, sddm, discover, etc.)
    ├── apps/        (~9 elements  — dolphin, kate, okular, konsole, etc.)
    └── deps.bst     # Master KDE Linux stack (200+ packages)
```

---

## Build Pipeline

```
freedesktop-sdk (base SDK)
    └── kde-build-meta junction
            ├── kde/qt6/         # Qt6 compiled from source
            ├── kde/frameworks/  # KDE Frameworks 6
            ├── kde/plasma/      # KDE Plasma 6 (kwin, sddm, plasma-workspace, etc.)
            ├── kde/apps/        # KDE Applications
            └── oci/kde-linux/   # KDE Linux base image
                    └── tromso/deps.bst      # Aurora additions
                            └── oci/tromso.bst  # Final OCI image
                                    └── ghcr.io/tuna-os/tromso:latest
```

The build is fully reproducible: all sources are pinned by git ref or tarball SHA256.
BuildGrid is used for distributed compilation — build jobs run on the home cluster
over Tailscale and results are cached as content-addressable artifacts.

---

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Display protocol | Wayland-only | Matches KDE Linux upstream; no X11 session |
| Display manager | SDDM | KDE's preferred DM; integrates with KWallet PAM |
| Init system | systemd | Via freedesktop-sdk |
| Bootloader | systemd-boot | Via bootc install |
| Image format | OCI/bootc | Enables atomic upgrades via `bootc upgrade` |
| Build system | BuildStream 2 | Same as GNOME OS and dakota; hermetic builds |
| Artifact cache | BuildGrid (gRPC) | Home cluster via Tailscale; survives runner restarts |

---

## Key `.bst` Patterns

### KDE cmake element

```yaml
kind: cmake

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst     # required at configure time for Qt6 CMake detection

variables:
  cmake-local: >-
    -DBUILD_TESTING=OFF
    -DWITH_X11=OFF            # most frameworks use this; kwindowsystem uses -DKWINDOWSYSTEM_X11=OFF
```

> **Note**: Use `cmake-local` (not `cmake-options`) for cmake flags in this project.

### Transitive build-depends

BuildStream does not automatically propagate CMake config files through `depends`.
If `foo.bst` calls `find_package(KF6Bar)` at configure time, then `kde/frameworks/bar.bst`
**must** appear in `foo.bst`'s `build-depends`, even if it's already in `depends`.

### Updating the junction

```bash
# 1. Commit + push kde-build-meta
cd /path/to/kde-build-meta
TMPDIR=/var/tmp git commit -m "..."
git push origin master

# 2. Compute new SHA (re-download — GitHub archive hashes are non-deterministic)
SHA=$(git rev-parse --short=7 HEAD)
curl -sL https://github.com/hanthor/kde-build-meta/archive/${SHA}.tar.gz | tee /tmp/kbm.tar.gz | sha256sum
tar tzf /tmp/kbm.tar.gz | head -1    # verify base-dir

# 3. Update elements/kde-build-meta.bst: url, ref, base-dir

# 4. Commit + push tromso
cd /path/to/tromso
TMPDIR=/var/tmp git commit -m "Update junction to kde-build-meta ${SHA}"
git push origin main
```

---

## CI/CD

**Primary workflow**: `.github/workflows/build-buildgrid.yml`

```
GitHub Actions runner
  → Generate CI BuildStream config
  → bst2 container pull (pinned image SHA)
  → just bst build oci/tromso.bst     (local CASD build)
  → just export                        (exports OCI tarball)
  → skopeo push ghcr.io/tuna-os/tromso:latest
```

Triggers: push to `main` (elements/**, project.conf, include/**), daily at 06:00 UTC, manual dispatch.

**Experimental parallel workflow**: `.github/workflows/build-tromso-multirunner.yml`
Splits the build into 10 parallel chunks across GitHub runners using `scripts/ci-build-matrix.py`.
Triggered manually or by daily schedule.

---

## Packages Not Yet in Aurora

The following packages from the KDE Linux package list require new `.bst` elements
that have not yet been written:

| Package | Notes |
|---------|-------|
| `openrazer-daemon` | DKMS-based; needs special handling |
| `yubikey-full-disk-encryption` | Hardware security key disk encryption |
| `vpl-gpu-rt` | Intel VPL GPU runtime |
| Python bindings (Shiboken6/PySide6) | Requires packaging from scratch |
