# Aurora Tromso — Technical Architecture

> **Note:** `tuna-os/kde-build-meta` was consolidated directly into this repo's
> `elements/` tree (junction removed, repo archived) — the "two-repo model"
> described below is historical. All KDE `.bst` elements now live in this repo;
> the diagrams below reflect the current single-repo state. See `AGENTS.md`'s
> "Single-Repo Model" section for details.

## Overview

Aurora Tromso is a bootable OCI/bootc image running KDE Plasma 6. It is built with
[BuildStream](https://www.buildstream.build/) on top of freedesktop-sdk, using the same
methodology as [GNOME OS](https://gitlab.gnome.org/GNOME/gnome-build-meta) and
[Project Bluefin dakota](https://github.com/projectbluefin/dakota).

All KDE `.bst` elements (Qt6, Frameworks, Plasma, Apps, base image) live directly in
this repo's `elements/` tree — see `AGENTS.md` for the current structure.

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
├── project.conf                  # BuildStream project config (name: tromso)
├── Justfile                      # Build recipes (bst, build, boot-vm, etc.)
├── include/
│   └── aliases.yml               # URL aliases (kde:, github:, gnome:, etc.)
└── elements/
    ├── freedesktop-sdk.bst       # Junction → freedesktop-sdk (base SDK)
    ├── kde/                      # KDE stack (consolidated in from kde-build-meta)
    │   ├── qt6/                  # Qt6 base, declarative, multimedia, etc.
    │   ├── frameworks/           # kcoreaddons, kio, kirigami, kwin deps, etc.
    │   ├── libs/                 # libkscreen, qcoro, phonon, etc.
    │   ├── plasma/               # plasma-workspace, kwin, sddm, discover, etc.
    │   ├── apps/                 # dolphin, kate, okular, konsole, etc.
    │   └── deps.bst              # Master KDE stack
    ├── kde-linux-deps/           # KDE Linux base deps (consolidated in)
    ├── kde-linux-system/         # KDE Linux system config/initramfs (consolidated in)
    ├── core/                     # Core freedesktop-sdk-facing elements
    ├── core-deps/                # Core dependency elements
    ├── gnomeos-deps/
    │   └── bootc.bst             # bootc compiled from source (Rust)
    ├── sdk/                      # SDK-facing elements
    ├── sdk-deps/
    ├── plugins/                  # BuildStream plugins (junctions)
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
        │   ├── image.bst         # Parent OCI image (Aurora fork, no bootc build)
        │   ├── stack.bst         # KDE Linux full stack
        │   └── filesystem.bst    # Filesystem layout
        └── layers/
            ├── tromso.bst        # Aurora OCI layer (depends on tromso/deps)
            ├── tromso-runtime.bst
            └── tromso-stack.bst  # Combined: kde-linux/stack + tromso/deps
```

All KDE `.bst` elements live directly in this repo — the former
`tuna-os/kde-build-meta` junction was removed and its elements consolidated
into `elements/` (`kde/`, `kde-linux-deps/`, `kde-linux-system/`, `core/`,
`core-deps/`, `patches/`, `files/`, `keys/`, `plugins/`; see `AGENTS.md` for
the full history). The role formerly played by the `kde-build-meta` junction
(`gnome-build-meta` scaffolding rebranded for KDE) is now filled by this
repo's own `elements/` tree plus the `freedesktop-sdk` junction.

---

## Build Pipeline

```
freedesktop-sdk (base SDK, via elements/freedesktop-sdk.bst junction)
    └── elements/kde/              # Qt6, Frameworks 6, Plasma 6, KDE Applications
    └── elements/kde-linux-deps/   # KDE Linux base deps
    └── elements/kde-linux-system/ # system config, initramfs, signed modules
            └── oci/kde-linux/     # KDE Linux base image
                    └── elements/tromso/deps.bst   # Aurora additions
                            └── oci/tromso.bst     # Final OCI image
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

### Updating KDE elements

All KDE elements live in this repo now (the `kde-build-meta` junction was removed), so updating a KDE stack element is an ordinary commit to `elements/kde/…` — no separate repo or junction-bump step:

```bash
cd /path/to/tromso
# edit elements/kde/<stack>/<element>.bst (bump url/ref, patch, etc.)
TMPDIR=/var/tmp git commit -m "Update <element> to <version>"
git push origin main
```

For the `freedesktop-sdk` base SDK junction, bump `elements/freedesktop-sdk.bst` (`url`, `ref`, `base-dir`) the same way.

---

## CI/CD

**Only image-build workflow**: `.github/workflows/build-tromso-multirunner.yml`

```
GitHub Actions runners
  → shared bst-ci planning/core/dependency chunks
  → merge chunk CAS archives
  → build_final: just bst build oci/tromso.bst + just export
  → sign and push ghcr.io/tuna-os/tromso tags
```

Triggers: push to `main` (elements/**, project.conf, include/**), daily at 06:00 UTC, manual dispatch.

The multi-runner workflow splits the build into parallel chunks across GitHub
runners using the shared [tuna-os/bst-ci](https://github.com/tuna-os/bst-ci)
reusable workflow (`scripts/ci-build-matrix.py` no longer lives in this repo).
It is triggered manually or by the daily schedule and is the only workflow
permitted to build or publish the Tromsø OCI image.

---

## Packages Not Yet in Aurora

The following packages from the KDE Linux package list require new `.bst` elements
that have not yet been written:

| Package | Notes |
|---------|-------|
| `openrazer-daemon` | DKMS-based; needs special handling |
| `yubikey-full-disk-encryption` | Hardware security key disk encryption |
| `vpl-gpu-rt` | Intel VPL GPU runtime |
| Python bindings (Shiboken6/PySide6) | Requires packaging from scratch — see [investigation](docs/kde-python-bindings-investigation.md) (#2) for what that entails |
