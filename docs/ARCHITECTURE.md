# TunaOS Tromsø architecture

TunaOS Tromsø is an Alpha desktop OS with KDE Plasma 6. It uses BuildStream and `freedesktop-sdk` to produce OCI images for `bootc`.
This document describes the build graph, sandbox policies, image composition, and CI.
It does not establish reproducibility or production readiness.

Plain and LUKS installations remain unqualified because the install gates fail with a composefs EOF error.
A UEFI ready result for a live ISO does not qualify disk installation.
The software comes from KDE upstream; this document does not imply KDE endorsement.

---

## 1. Context and motivation

Desktop systems need a balance between development speed, repeatable builds, and controlled updates.

1. **RPM and DEB packages**: Updates can cause differences between installations, dependency conflicts, and difficult rollbacks.
2. **Containerfiles**: Layers can depend on prebuilt packages, package resolution, and network state. These inputs can prevent repeatable builds.
3. **Images from source**: Build tools turn source trees into content-addressed artifacts. A later stage packages these artifacts as OCI images.

Tromsø uses the third approach:
- **BuildStream 2.5+**: Controls a directed acyclic graph (DAG) of dependencies, isolated sandboxes, content-addressable storage (CAS), and artifact caches.
- **freedesktop-sdk**: Supplies the base runtime, toolchain, and libraries.
- **bootc**: Distributes bootable images through OCI registries and supports atomic upgrades.

---

## 2. High-Level Architecture

The build graph converts tarballs from upstream and Git repositories into a desktop image:

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

Earlier versions used a separate `kde-build-meta` repository through a junction.
Junctions at multiple levels had these problems:
- A change to a junction reference invalidated much of the cache.
- Reviews needed coordination across repositories for package updates.
- Multiple levels of junctions complicated the resolution of paths and updates to sources in BuildStream.

### Current design: one `elements/` hierarchy

The repository now contains KDE, Plasma, and desktop elements in `elements/`.
The external junction, `elements/freedesktop-sdk.bst`, points to `gitlab.com/freedesktop-sdk/freedesktop-sdk.git`.
This keeps the SDK separate from local elements.

---

## 4. Element Hierarchy & Package Layout

Elements have the layout below:

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
1. **CMake modules**: KDE Frameworks need CMake modules at configure time. Put dependencies that supply these modules in both `depends:` and `build-depends:`.
2. **Options and flags**: Use `cmake-local`, not `cmake-options`, for architecture-specific flags. This preserves upstream defaults.
3. **Base modules**: Use SDK packages directly through the junction. Do not redeclare `linux-pam-base`, `polkit`, or `networkmanager`.

---

## 5. Sandboxing Policies & Upstream Standards

Tromsø follows sandbox policies from `freedesktop-sdk` (see [ADR 0004](adr/0004-freedesktop-sdk-upstream-practices.md)):

### Fatal Warnings
`project.conf` sets:
```yaml
fatal-warnings:
  - unaliased-url
  - unstaged-files
```
- **`unaliased-url`**: Direct URLs prevent mirror redirection and affect cache keys. Each source must use an alias from `include/aliases.yml`.
- **`unstaged-files`**: Fails the build if an element omits files from its target tree.

### Source mirrors and offline checks
Aliases map to fallback mirrors in `include/mirrors.yml`.
The offline test, `tests/pytest/test_source_aliases.py`, checks aliases and mirrors in the build graph.

### Controlled System Root Assembly (`elements/oci/tromso.bst`)
During final image composition:
- **`fakecap`**: Sets POSIX capabilities inside unprivileged user namespaces. Examples include `cap_sys_nice` on `kwin_wayland` and `cap_setuid` on `newuidmap`.
- **Linker cache (`ldconfig`)**: Combines `/parent` and `/layer` through an overlay filesystem. It runs `ldconfig` against the combined libraries so SDDM can resolve Qt 6 libraries.
- **`systemd-sysusers`**: Creates system users and groups in `/layer/etc` and `/usr/share/factory/etc`.

---

## 6. Container & Bootable Image Delivery (bootc)

Tromsø targets OCI images for `bootc`, not partitioned disk images from tools such as `genimage`.

1. **`build-oci`**: Produces an OCI layout with gzip-compressed layers (`gzip: gzip`).
2. **Annotations**: The manifest includes `containers.bootc: '1'` and standard OCI annotations.
3. **Composefs**: The install path uses `bootc` with `--composefs-backend`. This selects dm-verity and composefs deduplication without local `bootupd` binaries in the payload. Installation remains unqualified.
4. **Live media**: `iso.justfile` creates a UEFI ISO. It places the OCI image in VFS storage inside squashfs for offline use by `tuna-installer`.

---

## 7. Distributed Multi-Runner CI Orchestration

A source build has over 200 elements across KDE Plasma and its dependencies.
The workflow, `.github/workflows/build-tromso-multirunner.yml`, divides this work across runners:

1. **Plan**: Uses `bst show` to inspect the graph. It separates core dependencies and divides other elements into deterministic chunks.
2. **Core**: Builds the SDK and core dependencies. It uploads the CAS archive to GHCR as an ORAS artifact.
3. **Chunks**: Each matrix job fetches the core CAS and builds its assigned elements. It publishes CAS tarballs with composite cache keys.
4. **Final assembly**: Downloads and merges the archives into a local CAS. It builds `oci/tromso.bst`, exports the container, and signs it with Cosign.

---

## 8. Cryptographic Supply Chain Integrity

The supply chain uses these controls:
- **Source references**: Elements use pinned revisions from Git or SHA256 checksums for tarballs. Pins alone do not prove reproducibility.
- **Keyless signatures**: Publication uses Cosign with an OIDC identity from GitHub Actions (`https://token.actions.githubusercontent.com`). Rekor records evidence of signatures in its public log.

See the [README](../README.md#verifying-signatures) for verification instructions.
Check each artifact and its expected identity; this architecture does not certify any release.

---

## References

- [BuildStream Documentation](https://docs.buildstream.build/)
- [freedesktop-sdk](https://freedesktop-sdk.io/)
- [Project Bluefin Dakota](https://github.com/projectbluefin/dakota)
- [gnome-build-meta](https://gitlab.gnome.org/GNOME/gnome-build-meta)
- [CI & ISO Pipeline](ci-and-iso-pipeline.md)
- [ADR 0004: freedesktop-sdk practices adopted](adr/0004-freedesktop-sdk-upstream-practices.md)
