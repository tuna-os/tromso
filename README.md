# KDE Build Metadata

KDE Build Metadata is a [BuildStream](https://docs.buildstream.build/) project for building the
KDE Plasma 6 desktop stack. It follows the same architecture as GNOME's
[gnome-build-meta](https://gitlab.gnome.org/GNOME/gnome-build-meta), adapted for KDE.

This repo produces a **KDE Linux OCI image** — a non-customized desktop closely replicating the
upstream [KDE Linux MKOSI build](https://invent.kde.org/kde-linux/kde-linux). Downstream
distribution projects (like [hanthor/tromso](https://github.com/hanthor/tromso) for Aurora)
junction into this repo and layer their customizations on top.

## Package Coverage

| Category | Elements | Description |
|----------|----------|-------------|
| **Qt6** | 30 | Qt 6 base, declarative, multimedia, and related modules |
| **Frameworks** | 70 | KDE Frameworks 6 (kcoreaddons, kio, kirigami, etc.) |
| **Libs** | 17 | Additional KDE libraries (libkomparediff2, okteta, etc.) |
| **Plasma** | 41 | KDE Plasma 6 (plasma-workspace, kwin, sddm, etc.) |
| **Apps** | 9 | KDE Applications (dolphin, konsole, kate, okular, etc.) |
| **System deps** | ~30 | OS-level packages (bootc, NetworkManager, zram, etc.) |

## Architecture

```
hanthor/kde-build-meta              ← this repo
├── elements/
│   ├── kde/                        # KDE packages (Qt6, Frameworks, Plasma, Apps)
│   ├── gnomeos-deps/               # OS runtime deps (bootc, zram, sddm configs, etc.)
│   ├── components/                 # freedesktop-sdk overrides
│   ├── oci/kde-linux/              # KDE Linux OCI image build targets
│   │   ├── stack.bst               # Full OS composition stack
│   │   ├── image.bst               # OCI image builder
│   │   └── filesystem.bst          # Filesystem composition
│   └── freedesktop-sdk.bst         # Junction → freedesktop-sdk
├── Justfile                        # Build commands (requires podman + just)
├── project.conf                    # BuildStream project configuration
├── include/                        # Shared aliases and mirrors
└── patches/                        # Upstream patches

hanthor/tromso                      ← Aurora OCI (downstream)
├── elements/
│   ├── aurora/                     # Aurora customizations
│   ├── oci/aurora.bst              # Aurora OCI image
│   └── kde-build-meta.bst          # Junction → this repo
```

## Building Standalone

Requires: [podman](https://podman.io/) and [just](https://just.systems/).

```bash
# Build the KDE Linux OCI image
just bst-build oci/kde-linux/image.bst

# Show element dependency tree
just show oci/kde-linux/stack.bst

# Open a build shell for an element
just bst shell kde/plasma/plasma-workspace.bst

# Tail the build log
just log
```

## Using as a Junction (for downstream projects)

After pushing changes to this repo, update the junction in the consuming project:

```bash
SHA=$(git rev-parse --short=7 HEAD)
curl -sL https://github.com/hanthor/kde-build-meta/archive/${SHA}.tar.gz | tee /tmp/kbm.tar.gz | sha256sum
tar tzf /tmp/kbm.tar.gz | head -1   # base-dir name
```

Then update the consuming project's `elements/kde-build-meta.bst`:
```yaml
kind: junction
sources:
- kind: tar
  url: https://github.com/hanthor/kde-build-meta/archive/<SHA>.tar.gz
  ref: <sha256>
  base-dir: kde-build-meta-<full-sha>
```

## Adding New Elements

### CMake-based KDE Packages

```yaml
# kde/frameworks/example.bst
type: cmake

depends:
- kde/frameworks/extra-cmake-modules.bst

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst

source:
  type: https
  url: https://api.github.com/repos/KDE/example/tarball/master

variables:
  cmake-local: -DBUILD_TESTING=OFF
```

### Key Patterns

- **Always include `kde/qt6/qt6-qtbase.bst`** in `build-depends` for Qt6 CMake detection
- **Use `cmake-local`** (not `cmake-options`) for CMake flags
- **KDE framework dependencies needed by CMake** must appear in both `depends:` and `build-depends:`

## References

- **[KDE Linux](https://invent.kde.org/kde-linux/kde-linux)** — authoritative KDE package list
- **[Arch Linux KDE PKGBUILDs](https://github.com/archlinux/svntogit-community/tree/packages/kde-*/trunk/)** — reference for CMake flags
- **[BuildStream Docs](https://docs.buildstream.build/)** — build system documentation
- **[freedesktop-sdk](https://freedesktop-sdk.io/)** — base SDK
