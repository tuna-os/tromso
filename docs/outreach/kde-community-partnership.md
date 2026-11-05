# KDE Community Co-Marketing Partnership & Plasma 6 Visibility Kit

Issue: [#372](https://github.com/tuna-os/tromso/issues/372).
Status: Drafts for maintainer review; external outreach, submissions, and community coordination remain outstanding.

---

## Overview & Context

This kit defines a full framework for joint promotion, community outreach, and technical collaboration between **Tromso** and the upstream **KDE Community**. It includes the Plasma development team, the KDE Promo / Communications team, and the Visual Design Group.

### Strategic Value
Tromso occupies a unique technical position in the ecosystem for desktop Linux:
- It is a source-composed desktop with KDE Plasma 6. It builds directly on `freedesktop-sdk` with **BuildStream 2**.
- It delivers the desktop operating system as an immutable, bootable OCI image for containers. **bootc** manages the image.
- For KDE, Tromso serves as a production-grade architecture for reference. It proves that KDE Plasma 6 excels in modern container-native, image-based environments with transactional deployments.

### Project Maturity & Alpha Grounding
In accordance with [ROADMAP.md](../../ROADMAP.md), Tromso is now in **Alpha** (0 of 5 release gates satisfied). Issue [#372](https://github.com/tuna-os/tromso/issues/372) outlines an ambitious vision of production readiness. However:
- All outreach copy and proposals for partners present Tromso as an active, source-reproducible **Alpha reference implementation**, with truthful descriptions. They also present it as a collaborative technical showcase.
- We deliberately avoid claims of enterprise stability at general availability before maturity. The formal release gates in `ROADMAP.md` must have recorded evidence from runs first. These gates cover Build reliability, Install validation, Release operations, User readiness, and Desktop experience.
- Claims focus strictly on verified architecture. This includes our graph of 200+ BuildStream elements and the hierarchy of elements in one repo. It also includes containerized CI in chunks and image composition with bootc and composefs.

### Trademark & Independent Community Positioning
Tromso is an independent community project within the [TunaOS](https://tunaos.org) ecosystem.
- **Independence**: Tromso is not an official KDE project and makes no claim of exclusive endorsement.
- **Distinction from KDE Linux**: The official project for KDE Linux ([`invent.kde.org/kde-linux/kde-linux`](https://invent.kde.org/kde-linux/kde-linux)) uses `mkosi` and packages from Arch Linux. Tromso uses BuildStream and freedesktop-sdk. Tromso uses package selections from KDE Linux as references. It maintains its own independent tooling for builds and architecture for delivery.
- **Compliance with KDE e.V. Trademarks**: All drafts for joint promotion, guidelines for badges, and public communications follow the trademark policy strictly. The applicable policy is the [KDE e.V. Trademark Policy](https://www.kde.org/community/whatiskde/trademarks.php). KDE e.V. owns the registered trademarks KDE® and the K Desktop Environment® logo.

---

## 1. Initial Partnership Outreach Pitch

**Target Channels**:
- KDE Promo Team: GitLab issue on `teams/promo` or email to `kde-promo@kde.org`.
- Matrix: `#kde-promo:kde.org` and `#kde-devel:kde.org`.
- Forum: [KDE Discuss](https://discuss.kde.org/) (Community category).

### Outreach Proposal Draft

**Subject**: Proposal for Partnership: Tromso as a bootc reference implementation with KDE Plasma 6

Hello KDE Promo and Plasma teams,

We would like to introduce [Tromso](https://github.com/tuna-os/tromso), an open community project. It builds a full operating system for desktops with KDE Plasma 6, BuildStream 2, and freedesktop-sdk. It provides bootable OCI images for containers that `bootc` manages.

Container-native and immutable desktops gain more momentum in Linux distributions, such as Fedora Kinoite and SteamOS. We believe Tromso provides a persuasive technical demonstration of KDE Plasma 6. It runs in a pure source-composed, transactional container environment.

#### Why This Partnership Matters for KDE
1. **Container-Native Reference Architecture**: Tromso builds KDE Plasma 6, Qt 6, and KDE Frameworks directly from upstream source tarballs. It uses hermetic sandboxes. It packages them cleanly into bootable OCI images without contamination from the host package manager.
2. **Desktop Immutability**: It proves that Plasma 6 is a first-class choice for image-based systems. These offer atomic updates, instant rollbacks, and composefs-backed storage.
3. **Mutual Visibility**: It showcases the versatility of KDE Plasma to developers who adopt containerized workflows. It gives KDE a concrete reference implementation for modern image composition.

#### Proposed Collaborative Next Steps
- **Joint Promotion**: A technical guest post on the KDE blog / Planet KDE. It would highlight how Plasma 6 runs on bootc and BuildStream.
- **Cross-References in Documentation**: Mutual references between deployment guides for Tromso and official resources for KDE Plasma 6.
- **Brand & Visual Review**: Feedback from KDE: Visual Design Group (VDG). This covers the desktop layout, default theme, and Breeze compliance in Tromso.
- **Akademy & FOSDEM 2027**: Explore joint presentations on packages for immutable desktops and containerized deployments of Plasma.

We emphasize that Tromso is an independent community project now in Alpha under active development. We would value your feedback and the opportunity to coordinate on upcoming Plasma releases.

- **Repository**: https://github.com/tuna-os/tromso
- **Roadmap & Release Gates**: https://github.com/tuna-os/tromso/blob/main/ROADMAP.md
- **Architecture Documentation**: https://github.com/tuna-os/tromso/blob/main/docs/ARCHITECTURE.md
- **Pipeline Guide**: https://github.com/tuna-os/tromso/blob/main/docs/ci-and-iso-pipeline.md

---

## 2. Co-Marketing Content: Blog Post & Editorial Draft

**Target Publication**: KDE Promo Blog / Planet KDE / `tunaos.org`.  
**Title**: Deploy KDE Plasma on Immutable Linux with Tromso.  
**Subtitle**: Compose Plasma 6 from Source with BuildStream and Deliver via bootc.

### Article Draft

In recent years, Linux has experienced a profound shift toward image-based, immutable operating systems. Developers and system administrators need atomic upgrades, predictable deployments, and guaranteed rollbacks more and more. Immutable systems have often relied on server-oriented container builds or traditional package trees from distros inside containers. Desktop operating systems have distinct architectural challenges.

**Tromso** explores a clean, source-driven approach as an open-source project. It assembles a complete, modern operating system for desktops with **KDE Plasma 6** from upstream source repositories. It uses **BuildStream 2** atop **freedesktop-sdk**. It packages the result directly as a bootable OCI image for containers that **bootc** manages.

#### 1. Why KDE Plasma 6 on bootc?
KDE Plasma 6 offers a responsive, Wayland-native desktop environment with exceptional modularity. The `bootc` project provides standard OCI semantics for containers to bootable roots for operating systems. Together, they offer immediately tangible benefits:
- **Transactional System Updates**: Upgrades to the operating system occur via standard pulls of OCI images (`bootc upgrade`). If an update fails to boot, systemd-boot and ostree provide immediate rollback to the previous boot deployment.
- **Source Reproducibility**: Containerfiles run imperative `dnf` or `apt` commands during image builds. Instead, Tromso composes its entire filesystem with the content-addressed dependency graph of BuildStream. Each tarball has mirror support, sandbox isolation, and a checksum.
- **Separation of System and Apps**: The core OS provides a rock-solid, immutable base with Plasma 6, SDDM, NetworkManager, and PipeWire. Flatpak and Flathub provide clean isolation for desktop applications.

#### 2. Architecture: From Upstream Tarballs to Bootable Containers
The build pipeline in Tromso integrates over 200 BuildStream elements in a single repository:
- **Foundational SDK**: It uses `freedesktop-sdk.bst` as an external junction. This provides the glibc base, systemd, and fundamental graphics runtimes.
- **KDE Stack**: CMake compiles the stack hermetically with Extra CMake Modules (`ECM`). It includes Qt 6 libraries (~30 elements), KDE Frameworks 6 (~70 elements), and KDE Plasma 6 (~41 elements).
- **OCI Assembly**: The final BuildStream stage runs `build-oci`. It exports the merged tree as an OCI layout. This has `containers.bootc: '1'` image annotations and composefs enabled.
- **Multi-Runner CI**: Tromso builds this extensive dependency graph without dedicated clusters of servers. It partitions the BuildStream DAG across ephemeral runners in GitHub Actions. They share CAS (Content-Addressable Storage) archives through GitHub Container Registry.

#### 3. Solving Desktop Integration Quirks in Container Environments
A rich desktop environment in a container-composed root needs solutions to subtle integration challenges:
- **Display Manager & GPU Bring-up**: In virtualized QEMU environments, SDDM initialization needs careful configuration of drivers and backends. Tromso provides fallbacks for software rasterizers (`Environment=QT_QUICK_BACKEND=software`) when hardware acceleration is unavailable.
- **Dynamic Linker Cache (`ldconfig`)**: Layers in bootc combine the system libraries from freedesktop-sdk with libraries for the KDE Plasma desktop. Image composition includes an explicit chroot `ldconfig` execution. This ensures that SDDM and Plasma binaries can resolve shared libraries at boot without delay.
- **File Capabilities**: Binaries important for security, such as `kwin_wayland` (`cap_sys_nice`), need POSIX capabilities. Sandboxes for unprivileged rootless builds cannot normally set them. Tromso integrates `fakecap` during builds to preserve these attributes into the final container layers.

#### 4. Collaboration with the KDE Community
Tromso is now in Alpha. It actively works toward its first verified Beta candidate under an evidence-based roadmap. We invite contributors from KDE, packagers, and enthusiasts for immutable desktops to:
- Test Tromso in QEMU or via live ISO media.
- Share patterns for packages and improvements to CMake integration.
- Help us refine the desktop defaults. Ensure full compliance with the Human Interface Guidelines from KDE.

Tromso demonstrates that KDE Plasma 6 is the premier desktop for traditional distributions. It is also a first-class citizen in the container-native future of Linux.

- **Check out the project**: https://github.com/tuna-os/tromso
- **Build instructions & Justfile**: https://github.com/tuna-os/tromso#readme

---

## 3. Badging, Shared Graphics & Trademark Policy

These guidelines provide high visibility for shared brands. They also ensure strict adherence to intellectual property and trademark standards from KDE:

### Badge Guidelines
- **Badge Copy**: `"Built with KDE Plasma 6"` or `"Powered by KDE Plasma"`.
- **Allowed Contexts**: README for the Tromso project, home page (`tunaos.org/tromso`), and documentation.
- **Asset Usage**: Use official badges from the KDE Promo community. Do not change the aspect ratio, proportions, or colors of the KDE logo.
- **Mandatory Trademark Disclaimer**: Any page with the KDE mark or badge must include the standard trademark attribution:
  > *KDE e.V. owns the registered trademarks KDE®, K Desktop Environment®, and the KDE Plasma logo.*
- **Independence Statement**: Explicit text must accompany the badge. It must clarify that Tromso is an independent community project. It is not an official product of KDE e.V.

---

## 4. Documentation Cross-Linking & User Guides

### Tromso Documentation Changes
1. **Upstream User Guides**: Link to official KDE documentation within Tromso guides:
   - [KDE UserBase](https://userbase.kde.org/)
   - [Plasma 6 User Guide](https://docs.kde.org/stable6/en/plasma-desktop/plasma-desktop/)
   - [KDE: Human Interface Guidelines (HIG)](https://develop.kde.org/hig/)
2. **Support Boundary Clarification**:
   - Instruct users to report defects in Tromso image builds, bootc updates, and packages to `tuna-os/tromso/issues`.
   - Direct bugs and feature requests for the upstream Plasma desktop to `bugs.kde.org`.

### Proposed Cross-Link for KDE Community Resources
Submit a documentation entry to the KDE Wiki / Community Deployment resources. Use the category "Distributions & Projects That Ship Plasma 6":
```markdown
- **[Tromso](https://github.com/tuna-os/tromso)**: An independent community project composing KDE Plasma 6 from source using BuildStream 2 and freedesktop-sdk, delivered as bootable OCI container images managed with bootc.
```

---

## 5. Conference Visibility & Presentation Proposals

### Akademy 2027 Proposal

**Event**: Akademy 2027.  
**Session Format**: 30-minute Presentation + 10-minute Q&A.  
**Track**: System Integration / Distributions / Packages.  
**Submission Title**: *Plasma on bootc: Compose Immutable Desktops with KDE from Source*.
**Co-Presenters**: Tromso Maintainer & Collaborator for Upstream KDE Packages (invited).

#### Abstract
Container-native operating systems that `bootc` manages offer atomic upgrades, declarative system states, and instant rollbacks. However, most bootc images for containers use traditional package managers inside standard Containerfiles for assembly. This obscures dependency provenance and loses fine-grained cache support for builds.

This presentation details **Tromso**, a community project for an operating system. It builds a complete desktop with KDE Plasma 6 directly from upstream source code. It uses **BuildStream 2** and **freedesktop-sdk**. It packages the result into bootable OCI images for containers.

#### Presentation Outline
1. **The Immutable Desktop Landscape**: Why transactional and container-native systems matter to users of KDE desktops and enterprises.
2. **Compose Plasma from Source**: Manage a DAG of 200+ BuildStream elements. It spans Qt 6, KDE Frameworks 6, and Plasma 6. Avoid complexity from nested junctions.
3. **Bootc Integration**: Convert filesystem trees from BuildStream into OCI bootc images (`containers.bootc: '1'`) with composefs enabled.
4. **Desktop Integration Challenges**: Manage POSIX capabilities (`fakecap`), SDDM software fallbacks, and caches for the dynamic linker. Also manage dependencies on systemd targets in container roots.
5. **CI at Scale**: Partition builds of large desktops across ephemeral multi-runner workers. Use chunks of CAS data and keyless signatures for images with Cosign.
6. **Future Directions & Collaboration**: How the ecosystem for KDE packages can use reproducible source pipelines.

---

### FOSDEM 2027 Joint Proposal

**Event**: FOSDEM 2027.  
**Devroom**: Immutable and Image-Based Linux Desktops / Desktops Devroom.  
**Session Format**: 20-minute Presentation + 5-minute Q&A.  
**Title**: *Build and Deploy KDE Plasma 6 with BuildStream and bootc*.  

**Abstract**:  
Learn how Tromso bridges systems for reproducible source-based builds (BuildStream 2) and modern container-native updates to the OS (`bootc`). We explore hermetic compilation of KDE Plasma 6 against `freedesktop-sdk`. We also explore deployment as bootable OCI containers and live installation media for an atomic, rollback-capable Plasma experience.

---

## 6. Technical Collaboration Framework

### KDE Visual Design Group (VDG) Collaboration
Tromso defaults to stock **Breeze Dark** after the audit of legacy brand assets ([#373](https://github.com/tuna-os/tromso/issues/373)). This also follows the removal of third-party artwork ([#301](https://github.com/tuna-os/tromso/pull/301)).

**Action Items with VDG**:
1. **Design Review Request**: Open a topic on KDE Discuss (Visual Design category) or the VDG Matrix room (`#kde-vdg:kde.org`). Request an audit of the desktop configuration in Tromso:
   - Verify consistency of Breeze Dark across SDDM, lock screen, and panel defaults.
   - Audit Fastfetch and the display of system brands for proper usage of the KDE logo.
   - Review integration of the Plymouth boot splash.
2. **Community Identity Collaboration**: Invite designers from the VDG community to collaborate on original, upstream-compliant brand assets and wallpapers for Tromso. These must respect KDE HIG.

### Plasma 6.x Feature & Release Tracking
- **Workflow to Monitor Releases**: Use automated source updates (`bst source track`) to monitor release tags from upstream KDE Plasma. Examples include Plasma 6.2, 6.3, etc.
- **Sandbox Feedback**: Feed build fixes, CMake configuration nuances, and missing dependency declarations directly to bug trackers for upstream KDE. These come from discoveries in the strict sandboxes of BuildStream.

### Technical Synchronization on bootc Challenges
Establish regular communication with KDE Linux developers (`kde-linux` / mkosi team) and the `kde-buildstream` initiative for packages ([ADR 0003](../adr/0003-kde-buildstream-upstream-watch.md)). Share findings about:
- Startup of Wayland compositor sessions under systemd user instances.
- Sandbox isolation of desktop portals (`xdg-desktop-portal-kde`) and Flatpak interaction in bootc roots.
- Storage efficiency and deduplication with composefs.

---

## 7. Success Metrics & Milestone Tracker

Evaluate progress on the partnership against the five key metrics in issue [#372](https://github.com/tuna-os/tromso/issues/372):

| Metric | Target | Current Status | Verification Source |
|---|---|---|---|
| KDE Blog / Promo Coverage | 1+ mention or technical case study | Planned (draft prepared in Section 2) | URL of published post on kde.org / Planet KDE |
| GitHub Community Interest | 50+ GitHub stars from KDE community | 11 stars (baseline) | GitHub repository star count |
| Conference Presentations | 2+ co-presentations (Akademy + FOSDEM) | Proposals drafted (Section 5) | Accepted session links in conference schedules |
| Developer Testing & Feedback | 10+ KDE developers testing Tromso | Pending Beta image availability | Discussion threads and GitHub issues |
| Upstream Reference Listing | Inclusion in BuildStream/KDE docs | Proposals drafted | BuildStream / KDE wiki reference link |

*Note*: Metrics for active tests depend on progress through the Alpha-to-Beta release gates in [ROADMAP.md](../../ROADMAP.md). This dependence is direct.

---

## 8. Maintainer Publication & Action Checklist

Before external outreach, a maintainer must review and do the following actions:

- [ ] **Verify Against Roadmap**: Confirm that the technical descriptions match the current CI and capabilities of builds. Do not exaggerate maturity beyond Alpha.
- [ ] **Designate Community Liaison**: Assign a Tromso maintainer as the public point of contact for KDE communications.
- [ ] **Initial Outreach**:
  - Send the partnership pitch (Section 1) to `kde-promo@kde.org` or post on KDE Discuss under Community.
  - Introduce Tromso in Matrix `#kde-promo:kde.org` and `#kde-devel:kde.org`.
- [ ] **Submit Review Request to VDG**:
  - Post desktop screenshots and configuration details on KDE Discuss / VDG channel. Request feedback on consistency of the Breeze theme.
- [ ] **Conference Submissions**:
  - Submit the Akademy 2027 presentation proposal during the Akademy CFP window.
  - Submit the FOSDEM 2027 presentation proposal to the Desktops or Immutable Distributions devroom.
- [ ] **Joint Promotion Publication**:
  - Coordinate with KDE Promo on the schedule for the technical blog post (Section 2).
  - Add the "Built with KDE Plasma 6" badge to the Tromso home page in compliance with Section 3.
- [ ] **Issue Updates**:
  - Update issue [#372](https://github.com/tuna-os/tromso/issues/372) with submission links, feedback threads, and milestones for the partnership. Keep #372 open until the ongoing collaboration exists.
