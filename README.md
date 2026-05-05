# Aurora — KDE Linux OCI/bootc Image

Aurora is a BuildStream-based KDE Linux OCI/bootc image, modeled on Project Bluefin's `projectbluefin/dakota`.
It builds KDE Plasma 6 on top of freedesktop-sdk using a two-repo architecture.

**Status: Builds successfully and boots to a working KDE Plasma 6 Wayland desktop.**

## Architecture

```
hanthor/tromso          (this repo — top-level OCI project)
├── elements/
│   ├── kde-build-meta.bst     local junction → kde-build-meta-local/
│   ├── aurora/                Aurora-specific layers (system-config, deps, etc.)
│   └── oci/aurora.bst         top-level build target
└── Justfile

kde-build-meta-local/   (KDE .bst elements, tracked as submodule)
└── elements/kde/
    ├── qt6/        (30 elements — qt6-qtbase, qt6-qtdeclarative, etc.)
    ├── frameworks/  (70 elements — kcoreaddons, kio, kirigami, etc.)
    ├── libs/        (17 elements — libkscreen, qcoro, phonon, etc.)
    ├── plasma/      (41 elements — plasma-workspace, kwin, sddm, etc.)
    └── apps/        (9 elements — dolphin, konsole, kate, gammaray, etc.)
```

## Quick Start

### Prerequisites

- Podman
- `just` (task runner)
- Sufficient disk space (~100 GB recommended for cache)

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
| `just bst-build` | Background build, logs to `/tmp/aurora-build.log` |
| `just build` | Foreground build + OCI export |
| `just log` | Tail the build log |
| `just generate-bootable-image` | Create a bootable raw disk image via bootc |
| `just boot-vm` | Boot the raw image in QEMU (SSH on port 2222, serial on 4444) |
| `just bst <args>` | Run any arbitrary `bst` command inside the build container |

## BuildStream Cache

Aurora uses a prioritized cache configuration:

1. **Local cache** (`grpc://192.168.0.221:11001`) — prioritized for speed
2. **freedesktop-sdk cache** (`https://cache.freedesktop-sdk.io:11001`) — fallback

To push artifacts to local cache after a successful build:

```bash
just bst-cache-push
```

## CI/CD

The project includes a multi-runner GitHub Actions workflow (`.github/workflows/build-aurora-multirunner.yml`) that:

- Splits the build into 10 parallel chunks across GitHub runners
- Uses `ci-build-matrix.py` to discover uncached elements and distribute work
- Caches artifacts between runs to speed up subsequent builds

Triggers: push to `main`, manual dispatch via GitHub UI.

## Updating KDE Packages

KDE package definitions live in `kde-build-meta-local/` (a local junction — no separate repo to push to).
Changes take effect immediately since BST uses a local path junction.

See `AGENTS.md` for detailed conventions and commit workflow.

## References

- **[KDE Linux](https://invent.kde.org/kde-linux/kde-linux)** — authoritative KDE package list
- **[Project Bluefin dakota](https://github.com/projectbluefin/dakota)** — reference OCI/bootc implementation
- **[freedesktop-sdk](https://freedesktop-sdk.io/)** — base SDK
- **[BuildStream](https://www.buildstream.build/)** — build system
