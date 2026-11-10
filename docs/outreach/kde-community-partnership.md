# KDE Community Co-Marketing Partnership & Plasma 6 Visibility Kit

Issue: [#372](https://github.com/tuna-os/tromso/issues/372).

Status: Drafts for maintainer review; external outreach, submissions, and community coordination remain outstanding.

---

## Overview & Context

This kit proposes publicity, community outreach, and technical collaboration between **Tromso** and the **KDE Community**. Participants could include Plasma developers, KDE Promo, and the Visual Design Group.

### Strategic Value
Tromso occupies a unique technical position in the desktop Linux ecosystem:
- It is a source-composed KDE Plasma 6 desktop built directly on top of `freedesktop-sdk` using **BuildStream 2**.
- It delivers an immutable, bootable OCI image for **bootc**.
- It provides a reference architecture for Plasma 6 on systems with containers, atomic updates, and deployments through images.

### Project Maturity & Alpha Grounding
The [roadmap](../../ROADMAP.md) identifies Tromso as **Alpha** (0 of 5 release gates complete at draft time). Issue [#372](https://github.com/tuna-os/tromso/issues/372) proposes a path toward production readiness:
- These drafts present an active **Alpha reference** and technical collaboration opportunity.
- We make no claims of enterprise stability before the gates in `ROADMAP.md` pass with recorded run evidence. The gates cover build reliability, installation validation, release operations, user readiness, and desktop experience.
- Claims focus on the architecture: over 200 BuildStream elements, one repository, CI chunks, and OCI composition with bootc and composefs.

### Trademark & Independent Community Positioning
Tromso is an independent community project within the [TunaOS](https://tunaos.org) ecosystem.
- **Independence**: Tromso is not an official KDE project and makes no claim of exclusive endorsement.
- **KDE Linux**: The official project for [KDE Linux](https://invent.kde.org/kde-linux/kde-linux) uses `mkosi` and Arch Linux packages. Tromso uses BuildStream and freedesktop-sdk. Tromso follows its package selections but maintains independent build tools and delivery.
- **Trademarks**: Public drafts and badge guidelines must follow the [KDE e.V. Trademark Policy](https://www.kde.org/community/whatiskde/trademarks.php). KDE e.V. owns the registered KDE® and K Desktop Environment® logo trademarks.

---

## 1. Initial Partnership Outreach Pitch

**Target Channels**:
- KDE Promo Team: GitLab issue on `teams/promo` or email to `kde-promo@kde.org`.
- Matrix: `#kde-promo:kde.org` and `#kde-devel:kde.org`.
- Forum: [KDE Discuss](https://discuss.kde.org/) (Community category).

### Outreach Proposal Draft

**Subject**: Partnership Proposal: Tromso as a KDE Plasma 6 bootc reference implementation

Hello KDE Promo and Plasma teams,

We introduce [Tromso](https://github.com/tuna-os/tromso), an open community project that builds KDE Plasma 6 with BuildStream 2 and freedesktop-sdk. It delivers OCI images for `bootc`.

Immutable desktops, such as Fedora Kinoite and SteamOS, show interest in deployments through images. Tromso explores this approach with KDE Plasma 6 and builds from source.

#### Why This Partnership Matters for KDE
1. **Source Builds**: Tromso builds Plasma 6, Qt 6, and KDE Frameworks from upstream tarballs in isolated sandboxes. It packages the result as bootable OCI images without packages from the host.
2. **Immutable Desktops**: Plasma 6 can support atomic updates, rollback, and composefs-backed storage.
3. **Visibility**: Tromso gives developers a reference for KDE Plasma in workflows with containers and image composition.

#### Proposed Collaborative Next Steps
- **Joint Publicity**: A guest post for the KDE blog or Planet KDE about Plasma 6 with bootc and BuildStream.
- **Documentation Links**: Cross-references between Tromso deployment guides and official resources for Plasma 6.
- **Visual Review**: Feedback from KDE's Visual Design Group (VDG) on layout, default themes, and Breeze consistency.
- **Akademy & FOSDEM 2027**: Joint presentations about immutable desktops and Plasma deployments with containers.

Tromso is an independent Alpha project under active development. We welcome feedback and coordination on upcoming Plasma releases.

- **Repository**: https://github.com/tuna-os/tromso
- **Roadmap & Release Gates**: https://github.com/tuna-os/tromso/blob/main/ROADMAP.md
- **Architecture Documentation**: https://github.com/tuna-os/tromso/blob/main/docs/ARCHITECTURE.md
- **Pipeline Guide**: https://github.com/tuna-os/tromso/blob/main/docs/ci-and-iso-pipeline.md

---

## 2. Co-Marketing Content: Blog Post & Editorial Draft

**Target Publication**: KDE Promo Blog / Planet KDE / `tunaos.org`  
**Title**: KDE Plasma on Immutable Linux with Tromso

**Subtitle**: Plasma 6 from Source with BuildStream and bootc

### Article Draft

Linux developers increasingly use immutable operating systems with atomic upgrades and rollback. Desktop systems have distinct challenges compared with server containers or distributions that assemble packages into images.

**Tromso** builds **KDE Plasma 6** from upstream sources with **BuildStream 2** and **freedesktop-sdk**. It packages the result as a bootable OCI image for **bootc**.

#### 1. Why KDE Plasma 6 on bootc?
KDE Plasma 6 offers a modular desktop with Wayland support. The `bootc` project applies OCI semantics to bootable systems. Together, they offer:
- **Atomic Updates**: Use `bootc upgrade` to pull OCI images for OS upgrades. If an update fails to boot, systemd-boot and ostree provide rollback to the previous deployment.
- **Reproducibility**: Tromso composes the filesystem through a content-addressed BuildStream graph. It does not run `dnf` or `apt` during image builds. Sources have mirrors and checksums; builds use isolated sandboxes.
- **System and Apps**: The immutable base contains Plasma 6, SDDM, NetworkManager, and PipeWire. Flatpak and Flathub provide separate desktop applications.

#### 2. Architecture: From Upstream Tarballs to Bootable Containers
The pipeline has over 200 BuildStream elements in one repository:
- **SDK**: The external junction `freedesktop-sdk.bst` provides glibc, systemd, and graphics runtimes.
- **KDE**: Isolated builds use CMake and Extra CMake Modules (`ECM`). They cover Qt 6 (about 30 elements), KDE Frameworks 6 (about 70), and Plasma 6 (about 41).
- **OCI Assembly**: The final stage runs `build-oci`. It exports an OCI layout with `containers.bootc: '1'` annotations and composefs support.
- **Distributed CI**: Tromso divides the graph across GitHub Actions runners. They share archives of content-addressable storage (CAS) through GitHub Container Registry.

#### 3. Solving Desktop Integration Quirks in Container Environments
A desktop inside a root composed from containers has integration challenges:
- **Display Manager & GPU**: SDDM needs correct drivers and backend configuration in QEMU. Tromso provides a software rasterizer fallback (`Environment=QT_QUICK_BACKEND=software`) when hardware acceleration is unavailable.
- **Linker Cache (`ldconfig`)**: The image combines libraries from the SDK and KDE. An explicit chroot call to `ldconfig` creates the cache so SDDM and Plasma can resolve libraries at boot.
- **File Capabilities**: The `kwin_wayland` binary needs `cap_sys_nice`. Unprivileged sandboxes cannot set these POSIX attributes. Tromso uses `fakecap` to preserve them in the final layers.

#### 4. Collaboration with the KDE Community
Tromso is Alpha. Its roadmap calls for evidence before the first verified Beta candidate. We invite KDE contributors, packagers, and desktop enthusiasts to:
- Test Tromso in QEMU or via live ISO media.
- Share package patterns and CMake integration improvements.
- Help refine the desktop defaults and follow KDE's interface guidelines.

Tromso explores Plasma 6 on source-built systems with OCI delivery.

- **Check out the project**: https://github.com/tuna-os/tromso
- **Build instructions & Justfile**: https://github.com/tuna-os/tromso#readme

---

## 3. Badging, Shared Graphics & Trademark Policy

Use these badge guidelines and follow the KDE trademark policy:

### Badge Guidelines
- **Badge Copy**: `"Built with KDE Plasma 6"` or `"Powered by KDE Plasma"`.
- **Contexts**: The Tromso README, website (`tunaos.org/tromso`), and documentation.
- **Assets**: Use official community badges from KDE Promo. Do not change logo proportions, aspect ratio, or colors.
- **Attribution**: Pages with the KDE mark or badge must include this trademark attribution:

  > *KDE®, K Desktop Environment®, and the logo for KDE Plasma are trademarks registered by KDE e.V.*
- **Independence**: Add this text beside the badge: Tromso is independent. It is not an official KDE e.V. product.

---

## 4. Documentation Cross-Linking & User Guides

### Tromso Documentation Changes
1. **User Guides**: Link to official KDE documentation from Tromso guides:
   - [KDE UserBase](https://userbase.kde.org/)
   - [Plasma 6 User Guide](https://docs.kde.org/stable6/en/plasma-desktop/plasma-desktop/)
   - [KDE interface guidelines (HIG)](https://develop.kde.org/hig/)
2. **Support Boundary Clarification**:
   - Direct Tromso build, bootc update, and package defects to `tuna-os/tromso/issues`.
   - Direct bugs in upstream Plasma and feature requests to `bugs.kde.org`.

### Proposed Cross-Link for KDE Community Resources
Propose an entry for KDE Wiki or community deployment resources under the category for distributions and projects with Plasma 6:
```markdown
- **[Tromso](https://github.com/tuna-os/tromso)**: An independent community project composing KDE Plasma 6 from source using BuildStream 2 and freedesktop-sdk, delivered as bootable OCI container images managed with bootc.
```

---

## 5. Conference Visibility & Presentation Proposals

### Akademy 2027 Proposal

**Event**: Akademy 2027.

**Session Format**: 30-minute presentation + 10-minute Q&A.

**Track**: System Integration / Distributions / Packages.

**Submission Title**: *Plasma on bootc: Immutable KDE Desktops from Source*.

**Co-Presenters**: A Tromso maintainer and an upstream KDE collaborator (proposed invitation)

#### Abstract
Systems that use `bootc` offer atomic upgrades, declarative states, and rollback. Builds with traditional package managers inside Containerfiles can obscure dependency provenance and lose detailed caches of artifacts.

This talk presents **Tromso**, a community project that builds KDE Plasma 6 from source with **BuildStream 2** and **freedesktop-sdk**. It packages the result as bootable OCI images.

#### Presentation Outline
1. **Immutable Desktops**: Why atomic updates matter to KDE users and enterprises.
2. **Plasma from Source**: A graph with over 200 BuildStream elements for Qt 6, KDE Frameworks, and Plasma 6. This graph has no nested junctions.
3. **Bootc Integration**: Conversion of BuildStream trees into OCI images (`containers.bootc: '1'`) with composefs support.
4. **Desktop Integration**: POSIX capabilities (`fakecap`), SDDM software fallbacks, linker caches, and dependencies between systemd targets.
5. **CI at Scale**: Builds across multiple runners with shared CAS archives and keyless Cosign signatures.
6. **Collaboration**: How KDE package maintainers can use reproducible builds from source.

---

### FOSDEM 2027 Joint Proposal

**Event**: FOSDEM 2027.

**Devroom**: Immutable and Image-Based Linux Desktops / Desktops Devroom.

**Session Format**: 20-minute presentation + 5-minute Q&A.

**Title**: *Build and Deploy KDE Plasma 6 with BuildStream and bootc*.

**Abstract**:  
Learn how Tromso connects source-based builds with BuildStream 2 to OS updates through `bootc`. We describe isolated builds of KDE Plasma 6 against `freedesktop-sdk`. The output includes bootable OCI containers and live media, with atomic updates and rollback.

---

## 6. Technical Collaboration Framework

### KDE Visual Design Group (VDG) Collaboration
Tromso defaults to stock **Breeze Dark** after the [legacy artwork audit](https://github.com/tuna-os/tromso/issues/373) and [third-party artwork removal](https://github.com/tuna-os/tromso/pull/301).

**Action Items with VDG**:
1. **Design Review**: Ask for an audit on KDE Discuss (Visual Design) or the VDG Matrix room (`#kde-vdg:kde.org`). Cover:
   - Breeze Dark consistency across SDDM, the lock screen, and panels.
   - Correct KDE logo use in Fastfetch and system identity displays.
   - Plymouth splash integration at boot.
2. **Community Identity**: Invite VDG designers to create original Tromso assets and wallpapers that respect KDE HIG and upstream guidelines.

### Plasma 6.x Feature & Release Tracking
- **Release Updates**: Use automated `bst source track` runs to monitor upstream tags for Plasma releases (6.2, 6.3, etc.).
- **Sandbox Feedback**: Report build fixes, CMake issues, and missing dependencies to upstream bug trackers for KDE.

### Technical Synchronization on bootc Challenges
Coordinate with KDE Linux developers (`kde-linux` / mkosi) and the `kde-buildstream` effort ([ADR 0003](../adr/0003-kde-buildstream-upstream-watch.md)). Share findings about:
- Startup of Wayland compositor sessions under systemd user instances.
- Desktop portal (`xdg-desktop-portal-kde`) isolation and Flatpak interaction in bootc roots.
- Storage efficiency and deduplication with composefs.

---

## 7. Success Metrics & Milestone Tracker

Issue [#372](https://github.com/tuna-os/tromso/issues/372) defines five metrics for partnership progress:

| Metric | Target | Current Status | Verification Source |
|---|---|---|---|
| KDE Blog / Promo Coverage | 1+ mention or technical case study | Planned (draft prepared in Section 2) | URL of published post on kde.org / Planet KDE |
| GitHub Community Interest | 50+ GitHub stars from KDE community | 11 stars (baseline) | GitHub repository star count |
| Conference Presentations | 2+ co-presentations (Akademy + FOSDEM) | Proposals drafted (Section 5) | Accepted session links in conference schedules |
| Developer Testing & Feedback | 10+ KDE developers testing Tromso | Pending Beta image availability | Discussion threads and GitHub issues |
| Upstream Reference Listing | Inclusion in BuildStream/KDE docs | Proposals drafted | BuildStream / KDE wiki reference link |

*Note*: Tests by developers depend on the Alpha-to-Beta release gates in [ROADMAP.md](../../ROADMAP.md).

---

## 8. Maintainer Publication & Action Checklist

Before external outreach, a maintainer must review and execute these actions:

- [ ] **Roadmap**: Check technical claims against current CI and build capabilities. Do not exaggerate maturity beyond Alpha.
- [ ] **Contact**: Choose a Tromso maintainer as the public contact for KDE communications.
- [ ] **Initial Outreach**:
  - Send the partnership pitch (Section 1) to `kde-promo@kde.org` or post on KDE Discuss under Community.
  - Introduce Tromso in Matrix `#kde-promo:kde.org` and `#kde-devel:kde.org`.
- [ ] **Request VDG Review**:
  - Post screenshots and configuration details on KDE Discuss or the VDG channel. Ask for feedback on Breeze consistency.
- [ ] **Conference Submissions**:
  - Submit the Akademy 2027 presentation proposal during the Akademy CFP window.
  - Submit the FOSDEM 2027 presentation proposal to the Desktops or Immutable Distributions devroom.
- [ ] **Joint Publication**:
  - Coordinate a publication date with KDE Promo for the technical blog post (Section 2).
  - Add the "Built with KDE Plasma 6" badge to the Tromso website under the guidelines in Section 3.
- [ ] **Issue Updates**:
  - Update [#372](https://github.com/tuna-os/tromso/issues/372) with submission links, feedback threads, and partnership milestones. Keep it open until the projects establish collaboration.
