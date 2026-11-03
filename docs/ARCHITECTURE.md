# Tromso Architecture: Reproducible Desktop Images with BuildStream

This document provides a technical overview of **Tromso**, a desktop operating system based on BuildStream and KDE Plasma 6. Tromso targets images in bootable OCI format that `bootc` manages. This document covers the architecture, build graph, sandbox policies, container composition, and distributed CI pipeline.

Tromso serves as a production reference for **BuildStream 2** and **freedesktop-sdk**. It applies them to large-scale delivery of desktop operating systems from source.

---

## 1. Context & Motivation

Modern desktop operating systems must balance **developer agility**, **reproducibility**, and **operational immutability**:

1. **Traditional distribution packages (RPM/DEB)**: Package updates can cause state divergence across installations, fragmented dependencies, and difficult rollbacks.
2. **Containerized desktops (ad-hoc Containerfiles)**: Standard `Containerfile` layers depend on pre-built package repositories and nondeterministic resolution of packages. They also depend on external network state at build time. These dependencies do undermine cryptographic reproducibility.
3. **Source-composed image-based systems**: These systems build entire operating systems from verified source trees into content-addressed artifacts. They then package the result into immutable OCI/bootc images.

Tromso adopts the third approach:
- **BuildStream 2.5+**: Controls the directed acyclic graph (DAG) of dependencies, hermetic sandboxes, content-addressable storage (CAS), and artifact caches.
- **freedesktop-sdk**: Provides the upstream base runtime, toolchain, and base libraries.
- **bootc (bootable OCI containers)**: Standardizes distribution of OS images and transaction-safe atomic upgrades on target hardware.

---

## 2. High-Level Architecture

The build process transforms sources from verified upstream projects into a bootable desktop image through discrete BuildStream stages. Sources include tarballs and Git repositories:

```
Upstream Sources (KDE, freedesktop-sdk, system utilities)
               │
               ▼
┌────────────────────────────────────────────────────────┐
│               BuildStream Dependency DAG               │
│                                                        │
│   freedesktop-sdk.bst (Base SDK & Toolchain Junction)  │
│                           │                            │
│   kde-linux-deps/ & core-deps/ (Mesa, Audio, Plumbing) │
│                           │                            │
│   kde/ (Qt6, Frameworks, Libs, Plasma 6, Apps)         │
│                           │                            │
│   kde-linux-system/ (Initramfs, Kernel modules, Repart)│
│                           │                            │
│   tromso/ (Configuration, Branding, Desktop Overlays)  │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│                  OCI Layer Assembly                    │
│                                                        │
│               elements/oci/tromso.bst                  │
│   (fakecap, ldconfig overlay, sysusers, build-oci)     │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│             Published OCI Container Image              │
│               ghcr.io/tuna-os/tromso:latest            │
│               (Signed keyless via Cosign OIDC)         │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│                Deployment & Live Media                 │
│                                                        │
│   Live UEFI ISO (systemd-boot + dmsquash + fisherman)  │
│   Bare-metal / VM target via `bootc install to-disk`   │
└────────────────────────────────────────────────────────┘
```

---

## 3. The Single-Repository Model

Earlier versions of Tromso had element definitions across multiple repositories. A separate `kde-build-meta` repository served as a junction into the image repository.

In practice, nested junctions for desktop environments that evolve rapidly were a source of significant friction:
- **Junction cache invalidation**: Changes to a junction reference or tarball caused invalidation of large subtrees in the downstream cache.
- **Staleness checks**: Separate Git repositories and PR reviews for package updates were a source of overhead for cross-repository coordination.
- **Bugs with nested junctions**: Complex multi-level junctions were a source of complications in path resolution and source updates in BuildStream.

### Current Design: Unified `elements/` Hierarchy
Tromso consolidated all KDE, Plasma, and desktop elements directly into this repository (`elements/`). Only one external junction remains:
- **`elements/freedesktop-sdk.bst`**: Points to upstream `freedesktop-sdk` (`gitlab.com/freedesktop-sdk/freedesktop-sdk.git`). This project is independent upstream. It remains a clean junction, in line with standard architectural practices for BuildStream.

---

## 4. Element Hierarchy & Package Layout

The repository organizes definitions of elements across clear functional domains:

```
elements/
├── freedesktop-sdk.bst      # External upstream junction to freedesktop-sdk
├── core/ & core-deps/       # Core operating system utilities, accountsservice, PAM
├── kde/                     # KDE software stack (Qt 6, Frameworks 6, Plasma 6, Apps)
│   ├── qt6/                 # Qt 6 base libraries and modules (~30 elements)
│   ├── frameworks/          # KDE Frameworks 6 (~70 elements)
│   ├── libs/                # Shared KDE libraries (~17 elements)
│   ├── plasma/              # KDE Plasma desktop shell and services (~41 elements)
│   └── apps/                # Essential KDE desktop applications (~9 elements)
├── kde-linux-deps/          # Graphics (Mesa, DRM), audio (PipeWire, WirePlumber), Wayland
├── kde-linux-system/        # Boot assets, dracut modules, systemd repart configuration
├── tromso/                  # Tromso desktop customization, session configuration, flatpaks
└── oci/tromso.bst           # Final composition element generating the bootc OCI image
```

### Key Build Patterns
1. **CMake Frameworks**: KDE Frameworks need detection of CMake configuration at build time. Frameworks in `depends:` that provide CMake find modules must also appear in `build-depends:`. This makes them available in the configure-time sandbox.
2. **Options & Flags**: All KDE CMake elements use `cmake-local` instead of `cmake-options` for architecture-specific flags. This preserves upstream defaults.
3. **No Redefinition of Base Modules**: Tromso consumes packages from `freedesktop-sdk` directly through the SDK junction, without re-declarations. Examples include `linux-pam-base`, `polkit`, `networkmanager`.

---

## 5. Sandboxing Policies & Upstream Standards

Tromso enforces rules for strict BuildStream sandboxes. These align with upstream practices for freedesktop-sdk (see [ADR 0004](adr/0004-freedesktop-sdk-upstream-practices.md)):

### Fatal Warnings
`project.conf` sets:
```yaml
fatal-warnings:
  - unaliased-url
  - unstaged-files
```
- **`unaliased-url`**: Hardcoded URLs in `.bst` files prevent source redirects through mirrors and corrupt cache keys. Every source must use an alias from `include/aliases.yml`.
- **`unstaged-files`**: Prevents elements from silently excluding files from target installation trees.

### Source Mirroring & Offline Verification
All aliases map to fallback mirrors in `include/mirrors.yml`. The test suite runs `tests/pytest/test_source_aliases.py` offline. This guarantees that no unaliased or un-mirrored sources enter the build graph.

### Controlled System Root Assembly (`elements/oci/tromso.bst`)
During final image composition:
- **`fakecap`**: Enforces capabilities for POSIX files inside unprivileged user namespaces. Examples include `cap_sys_nice` on `kwin_wayland`, and `cap_setuid` on `newuidmap`.
- **Linker cache (`ldconfig`)**: Composes `/parent` and `/layer` in an overlay filesystem. It executes `ldconfig` against the full library tree of the system. This ensures SDDM can resolve Qt 6 dynamic libraries on first boot.
- **`systemd-sysusers`**: Populates system users and groups deterministically in `/layer/etc` and `/usr/share/factory/etc`.

---

## 6. Container & Bootable Image Delivery (bootc)

Tromso targets containers with standard OCI images that are bootable. It does not assemble images of bare disks with partitions in the sandbox (such as `genimage`):

1. **`build-oci` Tooling**: The final element produces a layout for an OCI image with gzip-compressed layers (`gzip: gzip`).
2. **Bootc Annotations**: The manifest for the OCI image includes `containers.bootc: '1'` and standard OCI annotations.
3. **Composefs Backend**: Disk installation uses `bootc` with `--composefs-backend`. This enables dm-verity and composefs deduplication without local `bootupd` binaries in the image payload.
4. **Live Media**: `iso.justfile` builds a live ISO for UEFI. It embeds an OCI layout and media receipt inside squashfs. The live system exposes the layout through a read-only mount. This enables reliable installation on bare metal offline via `tuna-installer`.

---

## 7. Distributed Multi-Runner CI Orchestration

A full source build of KDE Plasma and its dependencies has over 200 elements. It exceeds the compute and time limits of standard free runners for CI. Tromso solves this with a multi-runner pipeline for BuildStream (`.github/workflows/build-tromso-multirunner.yml`):

1. **Plan Phase**: Uses `bst show` to analyze the BuildStream graph. It separates core elements for bootstrap from application dependencies, then partitions the remaining elements into deterministic chunks.
2. **Core Phase**: Builds the bootstrap SDK and core dependencies. It pushes the CAS archive from this build to GHCR as an ORAS artifact.
3. **Chunk Matrix**: Concurrent matrix jobs on CI runners fetch the core CAS and build their respective chunk elements. They publish tarballs of chunk CAS with composite cache keys as tags.
4. **Final Assembly & CAS Merge**: The final runner downloads all archives of chunk CAS. It merges them into a unified local CAS. It builds `oci/tromso.bst`, exports the OCI container, and signs the image with Cosign.

---

## 8. Cryptographic Supply Chain Integrity

Tromso validates integrity of the software supply chain from source to distribution:
- **Reproducible Elements**: All elements have pinned Git revisions and SHA256 tarball checksums.
- **Keyless Signatures**: Cosign signs the published images in OCI format and Live ISO media. It uses the OIDC identity from GitHub Actions (`https://token.actions.githubusercontent.com`). It records provenance in the public transparency log, Rekor.

The [README](../README.md#verifying-signatures) contains verification instructions.

---

## References

- [BuildStream Documentation](https://docs.buildstream.build/)
- [freedesktop-sdk](https://freedesktop-sdk.io/)
- [Project Bluefin Dakota](https://github.com/projectbluefin/dakota)
- [gnome-build-meta](https://gitlab.gnome.org/GNOME/gnome-build-meta)
- [CI & ISO Pipeline](ci-and-iso-pipeline.md)
- [ADR 0004: freedesktop-sdk practices adopted](adr/0004-freedesktop-sdk-upstream-practices.md)
