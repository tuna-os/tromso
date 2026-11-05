# BuildStream Community Visibility & Reference Implementation Kit

Issue: [#374](https://github.com/tuna-os/tromso/issues/374).

Status: Drafts for maintainer review; external outreach, submissions, and coordination remain outstanding.

---

## Overview & Context

This kit provides outreach drafts, technical case studies, and proposals for coordination with **BuildStream** and **freedesktop-sdk** communities.

### Project Maturity & Evidence Grounding
The [roadmap](../../ROADMAP.md) identifies Tromso as **Alpha**. These drafts describe its technical architecture:
- One repository with over 200 BuildStream elements.
- A pure source-based composition of KDE Plasma 6 on top of `freedesktop-sdk`.
- Bootable OCI images with `bootc` and `build-oci`.
- A distributed CI workflow with CAS chunks on GitHub Actions.

These drafts describe the build architecture and package patterns. They make no claims of general availability or enterprise stability before the Alpha-to-Beta gates pass.

---

## 1. BuildStream Upstream Coordination Pitch

**Target**: BuildStream upstream project (`buildstream.build`, GitLab `buildstream/buildstream`).  
**Channel**: A GitLab issue or documentation merge request. Propose inclusion in "Notable Projects", "In the Wild", or the Case Studies section.

### Proposal Text

**Title**: Propose Tromso (KDE Plasma desktop) as a reference for BuildStream

Hello BuildStream team,

We propose [Tromso](https://github.com/tuna-os/tromso) for the BuildStream documentation under "Notable Projects" or as a reference for desktop systems.

Tromso is an independent community project. It uses BuildStream 2 to build KDE Plasma 6 from source on `freedesktop-sdk`. BuildStream assembles the OS tree in isolated sandboxes with content-addressed artifacts. The `build-oci` tool packages that tree as a bootable OCI image for `bootc`.

#### Architectural Highlights & Relevance to BuildStream
- **Scale**: The tree has over 200 elements. These cover Qt 6, about 70 KDE Frameworks, Plasma 6, applications, system utilities, and graphics drivers.
- **One Repository**: Package definitions live under `elements/`. The only external junction is `freedesktop-sdk.bst`. This avoids nested junctions in a complex graph of desktop dependencies.
- **Upstream Standards**: Tromso enforces `fatal-warnings: [unaliased-url, unstaged-files]`. The `include/mirrors.yml` file provides fallback mirrors.
- **Distributed CI**: The workflow divides graphs of dependencies across GitHub Actions runners. The jobs connect through CAS archives and composite cache keys.
- **OS Delivery**: The `build-oci` tool creates OCI images for bootc (`containers.bootc: '1'`). Tromso also builds live UEFI media for installation.

#### Proposed Listing
```markdown
- **[Tromso](https://github.com/tuna-os/tromso)**: A KDE Plasma 6 desktop operating system built entirely from source with BuildStream 2 on top of freedesktop-sdk, publishing bootable OCI container images managed with bootc.
```

We can contribute a short case study to `buildstream.build`. It would describe our experience with BuildStream 2 and these architectural patterns.

- **Repository**: https://github.com/tuna-os/tromso
- **Architecture Documentation**: https://github.com/tuna-os/tromso/blob/main/docs/ARCHITECTURE.md
- **CI Pipeline Guide**: https://github.com/tuna-os/tromso/blob/main/docs/ci-and-iso-pipeline.md

---

## 2. freedesktop-sdk Alignment Memo

**Target**: `freedesktop-sdk` maintainers (`freedesktop-sdk.io`, GitLab `freedesktop-sdk/freedesktop-sdk`).  
**Channel**: freedesktop-sdk Matrix room (`#freedesktop-sdk:matrix.org`) or GitLab discussion.

### Alignment Summary

Tromso relies directly on `freedesktop-sdk` as its foundational build junction (`elements/freedesktop-sdk.bst`). We view freedesktop-sdk as our primary upstream.

#### Current Alignment Practices
1. **Upstream Conventions (ADR 0004)**:
   - Enforce `fatal-warnings: unaliased-url` across over 650 source URLs.
   - Provide mirrors through `include/mirrors.yml` to protect builds against source outages.
   - Use SDK components directly, such as `linux-pam-base`, `polkit`, and `networkmanager`.
2. **Snapshot Updates**:
   - Track stable releases of freedesktop-sdk (`25.08.x` at the time of this draft).
   - Update junction references through automated `bst source track` runs.
3. **Collaboration & Upstream Value**:
   - Share recipes for KDE Frameworks 6 and Qt 6 with other SDK consumers.
   - Document build quirks, capabilities (`fakecap`), and the dynamic linker cache inside sandboxes.

---

## 3. Blog Post / Technical Case Study Draft

**Title**: Build KDE with BuildStream: Lessons from Tromso

**Target Publication**: `buildstream.build` news / `tunaos.org` blog  
**Author**: Tromso Maintainers

### Draft Article

Linux servers commonly use containers and immutable systems. Desktops often depend on traditional package managers or nondeterministic layers in containers.

**Tromso** builds KDE Plasma 6 from upstream sources with **BuildStream 2** and **freedesktop-sdk**. It publishes the result as a bootable OCI image for **bootc**.

These are our technical lessons from a desktop build with BuildStream.

#### 1. Managing Scale: The Single-Repository Model
A desktop has a large dependency graph. Tromso includes Qt 6 (about 30 elements), KDE Frameworks 6 (about 70), and Plasma 6 (about 41). System libraries, audio servers, graphics drivers, and utilities complete the graph.

We initially kept definitions of packages in a separate repository, connected through a junction. With nested junctions, caches became invalid more often. Maintenance across repositories also became more complex.

We moved KDE elements into one `elements/` tree. Only `freedesktop-sdk.bst` remains as an external junction. This gives us:
- Atomic commits across package definitions and system configuration.
- Simpler dependency updates and cache behavior.
- Clear separation between the upstream SDK foundation and the desktop application layer.

#### 2. Strict Sandboxing & Source Discipline
Reproducibility needs source discipline. Tromso sets `fatal-warnings: [unaliased-url, unstaged-files]` in `project.conf`. Each source uses an alias from `include/aliases.yml` and fallback mirrors from `include/mirrors.yml`.

The offline suite checks for hardcoded URLs and sources without mirrors. These checks help protect builds against unexpected failures in upstream networks.

#### 3. Overcoming Sandbox Nuances for Desktop Environments
Desktop builds face integration challenges inside isolated sandboxes:
- **File Capabilities**: The `kwin_wayland` binary needs `cap_sys_nice`. The `newuidmap` and `newgidmap` binaries need `cap_setuid` and `cap_setgid`. We use `fakecap` inside unprivileged sandboxes to preserve these attributes.
- **Linker Cache (`ldconfig`)**: Qt 6 libraries span the base OS and desktop layers. An overlay combines these trees during image composition. This lets `ldconfig` create one linker cache so SDDM and Plasma can resolve libraries at boot.

#### 4. Distributed Multi-Runner CI with Content-Addressable Storage
A build of over 200 packages exceeds the time limits on a single free runner. Tromso uses a multi-runner pipeline:
1. The plan job calculates the order of dependencies. It divides uncached elements into balanced chunks.
2. The core runner builds bootstrap elements. It publishes a CAS snapshot to GitHub Container Registry (GHCR) with ORAS.
3. Matrix runners fetch the core CAS and build assigned chunks in parallel. They export CAS archives for each chunk.
4. The final runner merges those archives and exports the OCI image. Cosign signs it through GitHub Actions OIDC.

#### Conclusion
BuildStream 2 provides isolated sandboxes, artifact caches, and content-addressed storage for reproducible OS composition. Tromso applies these features to a complete desktop system.

---

## 4. Conference Proposal (FOSDEM 2027)

**Target Devroom**: Distributions / Desktops / Build Systems  
**Format**: 25-minute presentation + 5-minute Q&A  
**Submission Title**: Build Systems for Immutable Desktops: KDE Linux with BuildStream and bootc

### Abstract
Systems that use `bootc` offer OCI delivery and atomic upgrades on bare metal. Images built with package managers inside Containerfiles can lose reproducibility and clear dependency provenance.

This talk presents **Tromso**, a community project that builds KDE Plasma 6 from source with **BuildStream 2** and **freedesktop-sdk**. Its output is a bootable OCI image.

We will describe the architecture of a desktop distribution:
- A BuildStream graph with over 200 elements for Qt 6, KDE Frameworks, and Wayland components.
- The move from nested junctions across repositories to one tree.
- Sandbox challenges: file capabilities, linker caches, and user configuration.
- CI across multiple runners with shared CAS archives.
- Conversion of BuildStream trees to bootable OCI containers and live UEFI media.

Attendees will learn how to apply BuildStream 2 and deployments through images to desktop systems.

---

## 5. Community Engagement Protocol & Channels

Maintainers should follow these guidelines with the BuildStream and freedesktop-sdk communities:

### Primary Communication Venues
- **Matrix**:
  - BuildStream: `#buildstream:matrix.org`
  - freedesktop-sdk: `#freedesktop-sdk:matrix.org`
- **GitLab**:
  - BuildStream: `https://gitlab.com/BuildStream/buildstream`
  - freedesktop-sdk: `https://gitlab.com/freedesktop-sdk/freedesktop-sdk`
- **Discourse**: `https://discourse.gnome.org/c/buildstream/` (where applicable)

### Engagement Principles
1. **Maturity**: Explain that Tromso is an Alpha project under open development. Present its architecture and lessons without claims of a finished commercial product.
2. **Upstream Value**: Share `.bst` files and build patterns with other projects. These include `gnome-build-meta` and the early `kde-buildstream` effort from ADR 0003.
3. **Feedback**: Listen to upstream maintainers about junctions, cache retention, and sandbox practices.

---

## 6. Maintainer Publication & Action Checklist

Before publication, a maintainer must review and execute these steps:

- [ ] **Roadmap**: Check technical details against [ROADMAP.md](../../ROADMAP.md). Do not make unverified claims of production stability.
- [ ] **Contact**: Choose the maintainer who will act as the official contact for BuildStream/freedesktop-sdk outreach.
- [ ] **Propose Documentation Upstream**:
  - Open an issue or MR on `buildstream/buildstream` or `buildstream.build` to propose Tromso for the documentation.
  - Link to `docs/ARCHITECTURE.md` and repository README.
- [ ] **Matrix Introduction**:
  - Introduce Tromso in `#buildstream:matrix.org` with the short pitch.
  - Invite feedback on the multi-runner architecture, CAS chunks, and package patterns.
- [ ] **FOSDEM 2027 Submission**:
  - Submit the abstract during the FOSDEM 2027 call for participation (CFP) window.
- [ ] **Record Execution**:
  - Update [#374](https://github.com/tuna-os/tromso/issues/374) with links to proposals, pull requests, and conference submissions. Keep it open until external visibility milestones are complete.
