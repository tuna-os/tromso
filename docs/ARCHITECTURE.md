# Tromso Architecture: Reproducible Desktop Images with BuildStream

This document provides a technical overview of **Tromso**, a BuildStream-based KDE Plasma 6 desktop operating system targeting bootable OCI container images managed with `bootc`. It documents the system architecture, build graph design, sandboxing policies, container composition, and distributed CI pipeline.

Tromso serves as a production reference implementation of **BuildStream 2** and **freedesktop-sdk** applied to large-scale, source-based desktop operating system delivery.

---

## 1. Context & Motivation

Modern desktop operating systems face a challenge in balancing **developer agility**, **reproducibility**, and **operational immutability**:

1. **Traditional distribution packaging (RPM/DEB)**: Package updates can lead to state divergence across installations, dependency fragmentation, and difficult rollbacks.
2. **Containerized desktops (ad-hoc Containerfiles)**: Standard `Containerfile` layers depend on pre-built package repositories, nondeterministic package-manager resolution, and external network state at build time, undermining cryptographic reproducibility.
3. **Source-composed image-based systems**: Systems that build entire operating systems from verified source trees into content-addressed artifacts, then package the result into immutable OCI/bootc images.

Tromso adopts the third approach:
- **BuildStream 2.5+**: Orchestrates the dependency directed acyclic graph (DAG), hermetic sandboxing, content-addressable storage (CAS), and artifact caching.
- **freedesktop-sdk**: Serves as the upstream base runtime, toolchain, and base libraries.
- **bootc (bootable OCI containers)**: Standardizes OS image distribution and transaction-safe atomic upgrades on target hardware.

---

## 2. High-Level Architecture

The build process transforms verified upstream source tarballs and Git repositories into a bootable desktop image through discrete BuildStream stages:

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

Earlier iterations of Tromso split element definitions across multiple repositories: a separate `kde-build-meta` repository junctioned into the image repository.

In practice, nested junctions for rapidly evolving desktop environments introduced significant friction:
- **Junction cache invalidation**: Bumping a junction reference or tarball invalidated large subtrees of the downstream cache.
- **Staleness tracking**: Maintaining separate Git repositories and PR reviews for packaging updates introduced cross-repository coordination overhead.
- **Junction-nesting bugs**: Complex multi-level junctions complicated BuildStream path resolution and source tracking.

### Current Design: Unified `elements/` Hierarchy
Tromso consolidated all KDE, Plasma, and desktop elements directly into this repository (`elements/`). Only one external junction remains:
- **`elements/freedesktop-sdk.bst`**: Points to upstream `freedesktop-sdk` (`gitlab.com/freedesktop-sdk/freedesktop-sdk.git`). Because freedesktop-sdk is an independent upstream project, maintaining it as a clean junction aligns with standard BuildStream architectural practices.

---

## 4. Element Hierarchy & Package Layout

The repository organizes element definitions across clear functional domains:

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
1. **CMake Frameworks**: KDE Frameworks require CMake configuration detection at build time. Frameworks listed in `depends:` that provide CMake find modules must also appear in `build-depends:` so they are present in the configure-time sandbox.
2. **Options & Flags**: All KDE CMake elements standardize on `cmake-local` rather than `cmake-options` to inject architecture-specific flags without overriding upstream defaults.
3. **No Redefinition of Base Modules**: Packages provided by `freedesktop-sdk` (such as `linux-pam-base`, `polkit`, `networkmanager`) are consumed directly from the SDK junction rather than re-declared.

---

## 5. Sandboxing Policies & Upstream Standards

Tromso enforces strict BuildStream sandboxing rules aligned with freedesktop-sdk upstream practices (see [ADR 0004](adr/0004-freedesktop-sdk-upstream-practices.md)):

### Fatal Warnings
`project.conf` sets:
```yaml
fatal-warnings:
  - unaliased-url
  - unstaged-files
```
- **`unaliased-url`**: Hardcoded URLs in `.bst` files prevent redirecting sources through mirrors and corrupt cache keys. Every source must use an alias declared in `include/aliases.yml`.
- **`unstaged-files`**: Prevents elements from silently omitting files from target installation trees.

### Source Mirroring & Offline Verification
All aliases map to fallback mirrors in `include/mirrors.yml`. The test suite runs `tests/pytest/test_source_aliases.py` offline to guarantee that no unaliased or un-mirrored sources enter the build graph.

### Controlled System Root Assembly (`elements/oci/tromso.bst`)
During final image composition:
- **`fakecap`**: Enforces POSIX file capabilities (e.g. `cap_sys_nice` on `kwin_wayland`, `cap_setuid` on `newuidmap`) inside unprivileged user namespaces.
- **Linker cache (`ldconfig`)**: Composes `/parent` and `/layer` in an overlay filesystem to execute `ldconfig` against the full system library tree, ensuring SDDM can resolve Qt 6 dynamic libraries on first boot.
- **`systemd-sysusers`**: Populates system users and groups deterministically in `/layer/etc` and `/usr/share/factory/etc`.

---

## 6. Container & Bootable Image Delivery (bootc)

Rather than assembling bare partition disk images in the sandbox (such as `genimage`), Tromso targets standard bootable OCI container images:

1. **`build-oci` Tooling**: The final element produces an OCI image layout with gzip-compressed layers (`gzip: gzip`).
2. **Bootc Annotations**: The OCI image manifest includes `containers.bootc: '1'` and standard OCI annotations.
3. **Composefs Backend**: Disk installation utilizes `bootc` with `--composefs-backend`, enabling dm-verity and composefs deduplication without requiring local `bootupd` binaries in the image payload.
4. **Live Media**: `iso.justfile` builds a UEFI live ISO embedding the OCI container image into VFS container storage inside squashfs, enabling reliable offline bare-metal installation via `tuna-installer`.

---

## 7. Distributed Multi-Runner CI Orchestration

A full source build of KDE Plasma and its dependencies comprises over 200 elements and exceeds the compute and time limits of standard free CI runners. Tromso solves this with a multi-runner BuildStream pipeline (`.github/workflows/build-tromso-multirunner.yml`):

1. **Plan Phase**: Analyzes the BuildStream graph using `bst show`, separates the core bootstrap elements from application dependencies, and partitions the remaining elements into deterministic chunks.
2. **Core Phase**: Builds the bootstrap SDK and core dependencies, pushing the resulting CAS archive to GHCR as an ORAS artifact.
3. **Chunk Matrix**: Concurrent CI runner matrix jobs fetch the core CAS, build their respective chunk elements, and publish chunk CAS tarballs tagged with composite cache keys.
4. **Final Assembly & CAS Merge**: The final runner downloads and merges all chunk CAS archives into a unified local CAS, builds `oci/tromso.bst`, exports the OCI container, and signs the image with Cosign.

---

## 8. Cryptographic Supply Chain Integrity

Tromso validates software supply chain integrity from source to distribution:
- **Reproducible Elements**: Pinned Git revisions and SHA256 tarball checksums for all elements.
- **Keyless Signing**: Published OCI images and Live ISO media are signed via **Cosign** using GitHub Actions OIDC identity (`https://token.actions.githubusercontent.com`), recording provenance in the Rekor public transparency log.

Verification instructions are maintained in the [README](../README.md#verifying-signatures).

---

## References

- [BuildStream Documentation](https://docs.buildstream.build/)
- [freedesktop-sdk](https://freedesktop-sdk.io/)
- [Project Bluefin Dakota](https://github.com/projectbluefin/dakota)
- [gnome-build-meta](https://gitlab.gnome.org/GNOME/gnome-build-meta)
- [CI & ISO Pipeline](ci-and-iso-pipeline.md)
- [ADR 0004: freedesktop-sdk practices adopted](adr/0004-freedesktop-sdk-upstream-practices.md)
