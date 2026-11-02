# KDE Community Co-Marketing Partnership & Plasma 6 Visibility Kit

Tracking: [#372](https://github.com/tuna-os/tromso/issues/372).  
Status: Drafts for maintainer review; external outreach, submissions, and community coordination remain outstanding.

---

## Overview & Context

This kit establishes a comprehensive framework for co-marketing, community outreach, and technical collaboration between **Tromso** and the upstream **KDE Community** (including the Plasma development team, the KDE Promo / Communications team, and the Visual Design Group).

### Strategic Value
Tromso occupies a unique technical position in the desktop Linux ecosystem:
- It is a source-composed KDE Plasma 6 desktop built directly on top of `freedesktop-sdk` using **BuildStream 2**.
- It delivers the desktop operating system as an immutable, bootable OCI container image managed with **bootc**.
- For the KDE community, Tromso serves as a production-grade reference architecture proving that KDE Plasma 6 excels in modern container-native, image-based, and transactional deployment environments.

### Project Maturity & Alpha Grounding
In accordance with [ROADMAP.md](../../ROADMAP.md), Tromso is currently in **Alpha** (0 of 5 release gates satisfied). While issue [#372](https://github.com/tuna-os/tromso/issues/372) outlines an ambitious vision of production readiness:
- All outreach copy and partner proposals in this kit truthfully present Tromso as an active, source-reproducible **Alpha reference implementation** and collaborative technical showcase.
- We deliberately avoid premature claims of general-availability enterprise stability until the formal release gates in `ROADMAP.md` (Build reliability, Install validation, Release operations, User readiness, and Desktop experience) are satisfied with recorded run evidence.
- Claims focus strictly on verified architecture: our 200+ element BuildStream dependency graph, single-repo element hierarchy, containerized CI chunking, and bootc composefs image composition.

### Trademark & Independent Community Positioning
Tromso is an independent community project within the [TunaOS](https://tunaos.org) ecosystem.
- **Independence**: Tromso is not an official KDE project and makes no claim of exclusive endorsement.
- **Distinction from KDE Linux**: The official KDE Linux project ([`invent.kde.org/kde-linux/kde-linux`](https://invent.kde.org/kde-linux/kde-linux)) uses `mkosi` and Arch Linux packages. Tromso uses BuildStream and freedesktop-sdk. Tromso references KDE Linux package selections but maintains its own independent build tooling and delivery architecture.
- **KDE e.V. Trademark Compliance**: All co-marketing drafts, badging guidelines, and public communications strictly follow the [KDE e.V. Trademark Policy](https://www.kde.org/community/whatiskde/trademarks.php). KDE® and the K Desktop Environment® logo are registered trademarks of KDE e.V.

---

## 1. Initial Partnership Outreach Pitch

**Target Channels**:
- KDE Promo Team: GitLab issue on `teams/promo` or email to `kde-promo@kde.org`.
- Matrix: `#kde-promo:kde.org` and `#kde-devel:kde.org`.
- Forum: [KDE Discuss](https://discuss.kde.org/) (Community category).

### Outreach Proposal Draft

**Subject**: Partnership Proposal: Tromso as a KDE Plasma 6 bootc reference implementation

Hello KDE Promo and Plasma teams,

We would like to introduce [Tromso](https://github.com/tuna-os/tromso), an open community project building a full KDE Plasma 6 desktop operating system using BuildStream 2 and freedesktop-sdk, delivered as bootable OCI container images managed with `bootc`.

As container-native and immutable desktops gain momentum across Linux distributions (such as Fedora Kinoite and SteamOS), we believe Tromso provides a compelling technical demonstration of KDE Plasma 6 running in a pure source-composed, transactional container environment.

#### Why This Partnership Matters for KDE
1. **Container-Native Reference Architecture**: Tromso demonstrates how KDE Plasma 6, Qt 6, and KDE Frameworks can be built directly from upstream source tarballs in hermetic sandboxes and packaged cleanly into bootable OCI images with zero host package-manager contamination.
2. **Expanding Desktop Immutability**: Proves that Plasma 6 is a first-class choice for image-based systems, offering atomic updates, instant rollbacks, and composefs-backed storage.
3. **Mutual Visibility**: Showcases KDE Plasma's versatility to developers adopting containerized workflows, while giving KDE a concrete reference implementation for modern image composition.

#### Proposed Collaborative Next Steps
- **Co-Marketing**: A technical guest post on the KDE blog / Planet KDE highlighting how Plasma 6 runs on bootc and BuildStream.
- **Documentation Cross-Linking**: Mutual documentation references between Tromso deployment guides and KDE's official Plasma 6 resources.
- **Brand & Visual Review**: Engaging the KDE Visual Design Group (VDG) for feedback on Tromso's desktop layout, default theming, and Breeze compliance.
- **Akademy & FOSDEM 2027**: Exploring joint presentations on immutable desktop packaging and containerized Plasma deployments.

We emphasize that Tromso is an independent community project currently in Alpha under active development. We would value your feedback and the opportunity to coordinate on upcoming Plasma releases.

- **Repository**: https://github.com/tuna-os/tromso
- **Roadmap & Release Gates**: https://github.com/tuna-os/tromso/blob/main/ROADMAP.md
- **Architecture Documentation**: https://github.com/tuna-os/tromso/blob/main/docs/ARCHITECTURE.md
- **Pipeline Guide**: https://github.com/tuna-os/tromso/blob/main/docs/ci-and-iso-pipeline.md

---

## 2. Co-Marketing Content: Blog Post & Editorial Draft

**Target Publication**: KDE Promo Blog / Planet KDE / `tunaos.org`  
**Title**: Deploying KDE Plasma on Immutable Linux with Tromso  
**Subtitle**: Composing Plasma 6 from Source with BuildStream and Delivering via bootc

### Article Draft

In recent years, the Linux landscape has experienced a profound shift toward image-based, immutable operating systems. Developers and system administrators increasingly demand atomic upgrades, predictable deployments, and guaranteed rollbacks. While immutable systems have often relied on server-oriented container builds or traditional distro package trees layered inside containers, desktop operating systems present distinct architectural challenges.

**Tromso** is an open-source project exploring a clean, source-driven approach: assembling a complete, modern **KDE Plasma 6** desktop operating system from upstream source repositories using **BuildStream 2**, built atop **freedesktop-sdk**, and packaged directly as a bootable OCI container image managed with **bootc**.

#### 1. Why KDE Plasma 6 on bootc?
KDE Plasma 6 offers a responsive, Wayland-native desktop environment with exceptional modularity. When paired with `bootc` (a project bringing standard OCI container semantics to bootable operating system roots), the benefits become immediately tangible:
- **Transactional System Updates**: Operating system upgrades occur via standard OCI image pulls (`bootc upgrade`). If an update fails to boot, systemd-boot and ostree provide immediate rollback to the previous boot deployment.
- **Source Reproducibility**: Unlike Containerfiles that run imperative `dnf` or `apt` commands during image builds, Tromso composes its entire filesystem using BuildStream's content-addressed dependency graph. Every tarball is mirror-backed, sandboxed, and checksummed.
- **Separation of System and Apps**: The core OS provides a rock-solid, immutable base featuring Plasma 6, SDDM, NetworkManager, and PipeWire, while desktop applications are cleanly isolated via Flatpak and Flathub.

#### 2. Architecture: From Upstream Tarballs to Bootable Containers
Tromso's build pipeline integrates over 200 BuildStream elements organized in a single repository:
- **Foundational SDK**: Built upon `freedesktop-sdk.bst` as an external junction, providing the glibc base, systemd, and fundamental graphics runtimes.
- **KDE Stack**: Qt 6 libraries (~30 elements), KDE Frameworks 6 (~70 elements), and KDE Plasma 6 (~41 elements) are compiled hermetically with CMake and Extra CMake Modules (`ECM`).
- **OCI Assembly**: The final BuildStream stage runs `build-oci`, exporting the merged tree as an OCI layout with `containers.bootc: '1'` image annotations and composefs enabled.
- **Multi-Runner CI**: To build this extensive dependency graph without dedicated server clusters, Tromso partitions the BuildStream DAG across ephemeral GitHub Actions runners, sharing CAS (Content-Addressable Storage) archives through GitHub Container Registry.

#### 3. Solving Desktop Integration Quirks in Container Environments
Running a rich desktop environment in a container-composed root requires addressing subtle integration challenges:
- **Display Manager & GPU Bring-up**: In virtualized QEMU environments, SDDM initialization requires careful driver and backend configuration; Tromso provides software rasterizer fallbacks (`Environment=QT_QUICK_BACKEND=software`) when hardware acceleration is unavailable.
- **Dynamic Linker Caching (`ldconfig`)**: Because bootc layers combine freedesktop-sdk system libraries with KDE Plasma desktop libraries, an explicit chroot `ldconfig` execution during image composition ensures SDDM and Plasma binaries resolve shared libraries immediately at boot.
- **File Capabilities**: Security-critical binaries such as `kwin_wayland` (`cap_sys_nice`) require POSIX capabilities that cannot normally be set in unprivileged rootless build sandboxes. Tromso integrates `fakecap` during build time to preserve these attributes into the final container layers.

#### 4. Collaboration with the KDE Community
Tromso is currently in Alpha, actively working toward its first verified Beta candidate under an evidence-based roadmap. We invite KDE contributors, packagers, and immutable desktop enthusiasts to:
- Test Tromso in QEMU or via live ISO media.
- Share packaging patterns and CMake integration improvements.
- Help us refine desktop defaults and ensure full compliance with KDE's Human Interface Guidelines.

Tromso demonstrates that KDE Plasma 6 is not only the premier desktop for traditional distributions, but also a first-class citizen in the container-native future of Linux.

- **Check out the project**: https://github.com/tuna-os/tromso
- **Build instructions & Justfile**: https://github.com/tuna-os/tromso#readme

---

## 3. Badging, Shared Graphics & Trademark Policy

To ensure high-visibility co-branding while strictly adhering to KDE's intellectual property and trademark standards:

### Badge Guidelines
- **Badge Copy**: `"Built with KDE Plasma 6"` or `"Powered by KDE Plasma"`.
- **Allowed Contexts**: Tromso project README, landing page (`tunaos.org/tromso`), and documentation.
- **Asset Usage**: Use official KDE Promo community badges. Do not modify the KDE logo's aspect ratio, proportions, or colors.
- **Mandatory Trademark Disclaimer**: Any page displaying the KDE mark or badge must include the standard trademark attribution:
  > *KDE®, K Desktop Environment®, and the KDE Plasma logo are registered trademarks of KDE e.V.*
- **Independence Statement**: The badge must be accompanied by explicit text clarifying that Tromso is an independent community project and not an official product of KDE e.V.

---

## 4. Documentation Cross-Linking & User Guides

### Tromso Documentation Changes
1. **Upstream User Guides**: Link to official KDE documentation within Tromso guides:
   - [KDE UserBase](https://userbase.kde.org/)
   - [Plasma 6 User Guide](https://docs.kde.org/stable6/en/plasma-desktop/plasma-desktop/)
   - [KDE Human Interface Guidelines (HIG)](https://develop.kde.org/hig/)
2. **Support Boundary Clarification**:
   - Instruct users to report Tromso image build, bootc update, and packaging defects to `tuna-os/tromso/issues`.
   - Direct upstream Plasma desktop bugs and feature requests to `bugs.kde.org`.

### Proposed Cross-Link for KDE Community Resources
Submit a documentation entry to the KDE Wiki / Community Deployment resources under "Distributions & Projects Shipping Plasma 6":
```markdown
- **[Tromso](https://github.com/tuna-os/tromso)**: An independent community project composing KDE Plasma 6 from source using BuildStream 2 and freedesktop-sdk, delivered as bootable OCI container images managed with bootc.
```

---

## 5. Conference Visibility & Presentation Proposals

### Akademy 2027 Proposal

**Event**: Akademy 2027  
**Session Format**: 30-minute Presentation + 10-minute Q&A  
**Track**: System Integration / Distributions / Packaging  
**Submission Title**: *Plasma on bootc: Composing Immutable KDE Desktops from Source*  
**Co-Presenters**: Tromso Maintainer & Upstream KDE Packaging Collaborator (invited)

#### Abstract
Container-native operating systems managed with `bootc` offer atomic upgrades, declarative system states, and instant rollbacks. However, most bootc container images are assembled by running traditional package managers inside standard Containerfiles, which obscures dependency provenance and loses fine-grained build caching.

This presentation details **Tromso**, a community operating system project that builds a complete KDE Plasma 6 desktop directly from upstream source code using **BuildStream 2** and **freedesktop-sdk**, packaging the result into bootable OCI container images.

#### Presentation Outline
1. **The Immutable Desktop Landscape**: Why transactional container-native systems matter to KDE desktop users and enterprises.
2. **Composing Plasma from Source**: Managing a 200+ element BuildStream dependency DAG spanning Qt 6, KDE Frameworks 6, and Plasma 6 without nested junction complexity.
3. **Bootc Integration**: Converting BuildStream filesystem trees into OCI bootc images (`containers.bootc: '1'`) with composefs enablement.
4. **Desktop Integration Challenges**: Managing POSIX capabilities (`fakecap`), SDDM software fallbacks, dynamic linker caching, and systemd target dependencies in container roots.
5. **CI at Scale**: Partitioning large desktop builds across ephemeral multi-runner workers using CAS chunking and keyless Cosign image signing.
6. **Future Directions & Collaboration**: How the KDE packaging ecosystem can leverage reproducible source pipelines.

---

### FOSDEM 2027 Joint Proposal

**Event**: FOSDEM 2027  
**Devroom**: Immutable and Image-Based Linux Desktops / Desktops Devroom  
**Session Format**: 20-minute Presentation + 5-minute Q&A  
**Title**: *Building and Deploying KDE Plasma 6 with BuildStream and bootc*  
**Abstract**:  
Learn how Tromso bridges the gap between source-based reproducible build systems (BuildStream 2) and modern container-native OS updates (`bootc`). We explore how KDE Plasma 6 can be compiled hermetically against `freedesktop-sdk` and deployed as bootable OCI containers and live installation media, delivering an atomic, rollback-capable Plasma experience.

---

## 6. Technical Collaboration Framework

### KDE Visual Design Group (VDG) Collaboration
Following the audit of legacy branding assets ([#373](https://github.com/tuna-os/tromso/issues/373)) and the removal of third-party artwork ([#301](https://github.com/tuna-os/tromso/pull/301)), Tromso defaults to stock **Breeze Dark**.

**Action Items with VDG**:
1. **Design Review Request**: Open a topic on KDE Discuss (Visual Design category) or the VDG Matrix room (`#kde-vdg:kde.org`) requesting an audit of Tromso's desktop configuration:
   - Verifying Breeze Dark consistency across SDDM, lock screen, and panel defaults.
   - Auditing Fastfetch and system branding display for proper KDE logo usage.
   - Reviewing Plymouth boot splash integration.
2. **Community Identity Collaboration**: Invite VDG community designers to collaborate on upstream-compliant, original Tromso branding assets and wallpapers that respect KDE HIG.

### Plasma 6.x Feature & Release Tracking
- **Release Tracking Workflow**: Use automated source tracking (`bst source track`) to monitor upstream KDE Plasma release tags (Plasma 6.2, 6.3, etc.).
- **Sandbox Feedback**: Feed back build fixes, CMake configuration nuances, and missing dependency declarations discovered in BuildStream's strict sandboxes directly to upstream KDE bug trackers.

### Technical Synchronization on bootc Challenges
Establish regular communication with KDE Linux developers (`kde-linux` / mkosi team) and the `kde-buildstream` packaging initiative ([ADR 0003](../adr/0003-kde-buildstream-upstream-watch.md)) to share findings regarding:
- Wayland compositor session startup under systemd user instances.
- Desktop portal (`xdg-desktop-portal-kde`) sandboxing and Flatpak interaction in bootc roots.
- Storage efficiency and deduplication with composefs.

---

## 7. Success Metrics & Milestone Tracker

The partnership progress will be evaluated against the five key metrics defined in issue [#372](https://github.com/tuna-os/tromso/issues/372):

| Metric | Target | Current Status | Verification Source |
|---|---|---|---|
| KDE Blog / Promo Coverage | 1+ mention or technical case study | Planned (draft prepared in Section 2) | URL of published post on kde.org / Planet KDE |
| GitHub Community Interest | 50+ GitHub stars from KDE community | 11 stars (baseline) | GitHub repository star count |
| Conference Presentations | 2+ co-presentations (Akademy + FOSDEM) | Proposals drafted (Section 5) | Accepted session links in conference schedules |
| Developer Testing & Feedback | 10+ KDE developers testing Tromso | Pending Beta image availability | Discussion threads and GitHub issues |
| Upstream Reference Listing | Inclusion in BuildStream/KDE docs | Proposals drafted | BuildStream / KDE wiki reference link |

*Note*: Active testing metrics depend directly on progressing Tromso through the Alpha-to-Beta release gates defined in [ROADMAP.md](../../ROADMAP.md).

---

## 8. Maintainer Publication & Action Checklist

Before initiating external outreach, a maintainer must review and perform the following actions:

- [ ] **Verify Against Roadmap**: Confirm that the technical descriptions match current CI and build capabilities without exaggerating maturity beyond Alpha.
- [ ] **Designate Community Liaison**: Assign a Tromso maintainer as the public point of contact for KDE communications.
- [ ] **Initial Outreach**:
  - Send the partnership pitch (Section 1) to `kde-promo@kde.org` or post on KDE Discuss under Community.
  - Introduce Tromso in Matrix `#kde-promo:kde.org` and `#kde-devel:kde.org`.
- [ ] **Submit VDG Review Request**:
  - Post desktop screenshots and configuration details on KDE Discuss / VDG channel for feedback on Breeze theming consistency.
- [ ] **Conference Submissions**:
  - Submit the Akademy 2027 presentation proposal during the Akademy CFP window.
  - Submit the FOSDEM 2027 presentation proposal to the Desktops or Immutable Distributions devroom.
- [ ] **Co-Marketing Publication**:
  - Coordinate with KDE Promo on scheduling the technical blog post (Section 2).
  - Add the "Built with KDE Plasma 6" badge to the Tromso landing page in compliance with Section 3.
- [ ] **Issue Tracking**:
  - Update issue [#372](https://github.com/tuna-os/tromso/issues/372) with submission links, feedback threads, and partnership milestones. Keep #372 open until the ongoing collaboration is established.
