# Tromso Architecture: Reproducible Desktop Images with BuildStream

This document describes **Tromso**, a KDE Plasma 6 operating system that uses BuildStream and freedesktop-sdk. It covers the build graph, sandbox rules, OCI composition, and CI pipeline. The output is a bootable OCI image that uses `bootc`.

Tromso applies **BuildStream 2** and **freedesktop-sdk** to desktop delivery from source.

---

## 1. Context & Motivation

Desktop operating systems must balance development speed, reproducibility, and immutable deployments:

1. **RPM/DEB distributions**: Package updates can cause installations to diverge. Dependencies can conflict, and rollback can be difficult.
2. **Containerfiles**: These builds depend on pre-built packages, package-manager resolution, and network state. These inputs can prevent reproducible output.
3. **Systems composed from source**: These systems build verified sources into content-addressed artifacts. They package the result as immutable OCI/bootc images.

Tromso adopts the third approach:
- **BuildStream 2.5+**: Manages the dependency graph (DAG), isolated sandboxes, content-addressable storage (CAS), and artifact caches.
- **freedesktop-sdk**: Serves as the upstream base runtime, toolchain, and base libraries.
- **bootc**: Provides OS distribution through images and atomic upgrades on target hardware.

---

## 2. High-Level Architecture

BuildStream uses verified tarballs and Git sources to create a bootable desktop image:

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

Earlier versions of Tromso kept definitions of elements in a separate `kde-build-meta` repository. A junction connected it to the image repository.

Nested junctions made desktop updates more complex:
- **Cache invalidation**: A change to a junction reference or tarball invalidated subtrees of the downstream cache.
- **Separate repositories**: Updates to packages needed commits and reviews across repositories.
- **Nested junctions**: Multiple levels made path resolution and source updates more complex in BuildStream.

### Current Design: Unified `elements/` Hierarchy
Tromso consolidated all KDE, Plasma, and desktop elements directly into this repository (`elements/`). Only one external junction remains:
- **`elements/freedesktop-sdk.bst`**: Points to upstream `freedesktop-sdk` (`gitlab.com/freedesktop-sdk/freedesktop-sdk.git`). This external junction preserves the boundary with an independent upstream project.

---

## 4. Element Hierarchy & Package Layout

The repository has definitions of elements for these functional domains:

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
1. **CMake Frameworks**: KDE Frameworks need CMake detection at build time. Dependencies that provide CMake find modules must appear in `build-depends:`, even if they also appear in `depends:`. This makes them available inside the sandbox during configuration.
2. **Options & Flags**: KDE CMake elements use `cmake-local` for architecture-specific flags. Do not use `cmake-options`. This preserves upstream defaults.
3. **Base Modules**: Use SDK components such as `linux-pam-base`, `polkit`, and `networkmanager` directly through the junction. Do not redefine them.

---

## 5. Sandboxing Policies & Upstream Standards

Tromso follows the upstream sandbox rules from freedesktop-sdk (see [ADR 0004](adr/0004-freedesktop-sdk-upstream-practices.md)):

### Fatal Warnings
`project.conf` sets:
```yaml
fatal-warnings:
  - unaliased-url
  - unstaged-files
```
- **`unaliased-url`**: Hardcoded URLs prevent mirror redirection and can corrupt cache keys. Every source must use an alias from `include/aliases.yml`.
- **`unstaged-files`**: Stops a build if an element leaves files outside its target installation tree.

### Source Mirroring & Offline Verification
All aliases map to fallback mirrors in `include/mirrors.yml`. The offline tests in `tests/pytest/test_source_aliases.py` check that every source has an alias and a mirror.

### Controlled System Root Assembly (`elements/oci/tromso.bst`)
During final image composition:
- **`fakecap`**: Sets POSIX capabilities (e.g. `cap_sys_nice` on `kwin_wayland`, `cap_setuid` on `newuidmap`) inside unprivileged user namespaces.
- **Linker cache (`ldconfig`)**: An overlay combines `/parent` and `/layer`. The element runs `ldconfig` against the full library tree. This lets SDDM resolve Qt 6 libraries on first boot.
- **`systemd-sysusers`**: Populates system users and groups deterministically in `/layer/etc` and `/usr/share/factory/etc`.

---

## 6. Container & Bootable Image Delivery (bootc)

Tromso builds bootable OCI images. It does not assemble disk partitions with tools such as `genimage` inside the sandbox.

1. **`build-oci`**: The final element produces an OCI layout with gzip-compressed layers (`gzip: gzip`).
2. **Bootc Annotations**: The OCI image manifest includes `containers.bootc: '1'` and standard OCI annotations.
3. **Composefs Backend**: The installer runs `bootc` with `--composefs-backend`. This enables dm-verity and composefs deduplication without local `bootupd` binaries in the image.
4. **Live Media**: `iso.justfile` builds a UEFI live ISO. Its squashfs contains the OCI image in VFS container storage. The `tuna-installer` tool uses this payload for offline installation.

---

## 7. Distributed Multi-Runner CI Orchestration

A full KDE Plasma build has over 200 elements, plus SDK dependencies. This exceeds the compute and time limits of free CI runners. Tromso uses a multi-runner pipeline (`.github/workflows/build-tromso-multirunner.yml`):

1. **Plan**: The job runs `bst show` to analyze the graph. It separates core dependencies and divides the remaining elements into deterministic chunks.
2. **Core**: The job builds the bootstrap SDK and core dependencies. It pushes the CAS archive to GHCR as an ORAS artifact.
3. **Chunks**: Matrix jobs fetch the core CAS and build their assigned elements in parallel. Each job publishes a CAS tarball with a composite cache key.
4. **Final Assembly**: The final runner downloads and merges the CAS archives. It builds `oci/tromso.bst`, exports the OCI container, and signs the image with Cosign.

---

## 8. Cryptographic Supply Chain Integrity

Tromso checks integrity from source to distribution:
- **Reproducible Elements**: All elements use pinned Git revisions or SHA256 checksums for tarballs.
- **Keyless Signatures**: Cosign signs the OCI images and live ISOs for publication through GitHub Actions OIDC (`https://token.actions.githubusercontent.com`). It records provenance in the Rekor transparency log.

The [README](../README.md#verifying-signatures) contains verification instructions.

---

## References

- [BuildStream Documentation](https://docs.buildstream.build/)
- [freedesktop-sdk](https://freedesktop-sdk.io/)
- [Project Bluefin Dakota](https://github.com/projectbluefin/dakota)
- [gnome-build-meta](https://gitlab.gnome.org/GNOME/gnome-build-meta)
- [CI & ISO Pipeline](ci-and-iso-pipeline.md)
- [ADR 0004: freedesktop-sdk practices adopted](adr/0004-freedesktop-sdk-upstream-practices.md)
