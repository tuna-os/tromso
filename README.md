# Aurora Tromso — KDE Linux OCI/bootc Image

**Aurora Tromso** is a BuildStream-based KDE Linux OCI/bootc image, modeled on Project Bluefin's
[`projectbluefin/dakota`](https://github.com/projectbluefin/dakota). It builds KDE Plasma 6 on top
of freedesktop-sdk and publishes a bootable OCI image to `ghcr.io/hanthor/tromso`.

**Status: Builds successfully and boots to a working KDE Plasma 6 Wayland desktop.**

## Architecture

Aurora Tromso uses a two-repo model:

```
hanthor/tromso          (this repo — Aurora customizations + OCI composition)
├── elements/
│   ├── kde-build-meta.bst    junction → hanthor/kde-build-meta
│   ├── tromso/               Aurora Tromso-specific layers (theming, apps, overlays)
│   └── oci/tromso.bst        top-level build target → ghcr.io/hanthor/tromso
└── Justfile

hanthor/kde-build-meta  (KDE .bst elements — KDE Linux base image)
└── elements/kde/
    ├── qt6/        (~30 elements — qt6-qtbase, qt6-qtdeclarative, etc.)
    ├── frameworks/  (~70 elements — kcoreaddons, kio, kirigami, etc.)
    ├── libs/        (~17 elements — libkscreen, qcoro, phonon, etc.)
    ├── plasma/      (~41 elements — plasma-workspace, kwin, sddm, etc.)
    └── apps/        (~9 elements — dolphin, kate, okular, gammaray, etc.)
```

`kde-build-meta` mirrors the role of `gnome-build-meta` in the GNOME ecosystem — it builds a
complete KDE Linux desktop that can be used standalone or as the base for derived images like
Aurora Tromso.

## Quick Start

### Prerequisites

- Podman
- [`just`](https://github.com/casey/just) (task runner)
- ~100 GB free disk space for build cache

### Build

```bash
git clone https://github.com/hanthor/tromso.git
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
| `just bst <args>` | Run any arbitrary `bst` command inside the build container |

## CI/CD — BuildGrid

The CI workflow (`.github/workflows/build-buildgrid.yml`) builds `oci/tromso.bst` on a home
BuildGrid cluster via Tailscale, then pushes the result to GHCR:

```
ghcr.io/hanthor/tromso:latest
ghcr.io/hanthor/tromso:<date>
ghcr.io/hanthor/tromso:<git-sha>
```

**How it works:**
1. GitHub Actions runner joins the home network via Tailscale OAuth
2. BuildStream submits build jobs to BuildGrid (remote execution over gRPC)
3. BuildGrid compiles all elements on the home cluster, caching artifacts
4. Completed artifacts are exported as an OCI image and pushed to GHCR

**Cold builds** (no artifacts cached) take multiple runs — each run pushes newly-built artifacts
to the BuildGrid artifact cache. Subsequent runs pull those from cache and only build what remains.

Triggers: push to `main` (element changes), daily at 06:00 UTC, manual dispatch.

## Updating KDE Packages

KDE package `.bst` definitions live in [`hanthor/kde-build-meta`](https://github.com/hanthor/kde-build-meta).
After committing there, update the junction ref in `elements/kde-build-meta.bst`:

```bash
# 1. Commit + push kde-build-meta
cd /path/to/kde-build-meta
TMPDIR=/var/tmp git commit -m "..."
git push origin master

# 2. Get new SHA and hash
SHA=$(git rev-parse --short=7 HEAD)
curl -sL https://github.com/hanthor/kde-build-meta/archive/${SHA}.tar.gz | tee /tmp/kbm.tar.gz | sha256sum

# 3. Update elements/kde-build-meta.bst with new url/ref/base-dir

# 4. Commit tromso
cd /path/to/tromso
TMPDIR=/var/tmp git commit -m "Update junction to kde-build-meta ${SHA}"
```

See `AGENTS.md` for full conventions and workflows.

## References

- **[KDE Linux](https://invent.kde.org/kde-linux/kde-linux)** — authoritative KDE package list
- **[hanthor/kde-build-meta](https://github.com/hanthor/kde-build-meta)** — KDE .bst elements
- **[Project Bluefin dakota](https://github.com/projectbluefin/dakota)** — reference OCI/bootc implementation
- **[gnome-build-meta](https://gitlab.gnome.org/GNOME/gnome-build-meta)** — build patterns reference
- **[freedesktop-sdk](https://freedesktop-sdk.io/)** — base SDK
- **[BuildStream](https://www.buildstream.build/)** — build system
