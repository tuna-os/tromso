# BuildStream Community Visibility & Reference Implementation Kit

Issue: [#374](https://github.com/tuna-os/tromso/issues/374).  
Status: Drafts for maintainer review; external outreach, submissions, and coordination remain outstanding.

---

## Overview & Context

This kit provides outreach copy for review, technical case studies, and coordination proposals.
It aims to increase Tromso's visibility within the **BuildStream** and **freedesktop-sdk** upstream communities.

### Project Maturity & Evidence Grounding
The [Tromso Roadmap](../../ROADMAP.md) shows that Tromso is in **Alpha** now.
The outreach materials focus on the technical architecture that Tromso has:
- A large-scale BuildStream 2 project in a single repo (~200+ elements).
- A pure source-based composition of KDE Plasma 6 on top of `freedesktop-sdk`.
- Delivery as a bootable image in OCI container format with `bootc` and `build-oci`.
- A distributed workflow for CAS chunks across multiple runners on GitHub Actions.

These drafts describe the verified build architecture and package patterns.
They do not claim general availability for end users or production stability for enterprises.
Tromso must first meet the Roadmap's release gates from Alpha to Beta.

---

## 1. BuildStream Upstream Coordination Pitch

**Target**: BuildStream upstream project (`buildstream.build`, GitLab `buildstream/buildstream`).  
**Channel**: GitLab issue or merge request for documentation.
Propose inclusion in "Notable Projects", "In the Wild", or the Case Studies section of the documentation.

### Proposal Text

**Title**: Propose Tromso (KDE Plasma desktop) as a production reference for BuildStream

Hello BuildStream team,

We would like to propose [Tromso](https://github.com/tuna-os/tromso) for the BuildStream documentation.
It could appear under "Notable Projects" or as a reference desktop OS.

Tromso is an independent community project that uses BuildStream 2 to build a complete operating system for desktops with KDE Plasma 6 from source.
It builds on top of `freedesktop-sdk`.
It does not rely on traditional package managers from distributions or ad-hoc Containerfiles.
Tromso uses BuildStream's sandboxed, content-addressed build engine to assemble a reproducible OS tree.
It then packages the tree directly into a bootable container in OCI format that `bootc` manages.

#### Architectural Highlights & Relevance to BuildStream
- **Scale**: Tromso's tree has over 200 elements.
  These span the complete KDE stack (Qt 6, ~70 KDE Frameworks, Plasma 6, and applications).
  They also include core OS infrastructure and graphics drivers.
- **Single-Repository Model**: All package definitions are directly under `elements/`.
  The sole external junction is `freedesktop-sdk.bst`.
  This shows how to manage the complex dependency graphs for desktops cleanly without friction from nested junctions.
- **Upstream Standards Compliance**: Tromso strictly follows the best practices for BuildStream.
  Examples include `fatal-warnings: [unaliased-url, unstaged-files]` and comprehensive coverage from fallback mirrors via `include/mirrors.yml`.
- **Distributed Multi-Runner CI**: This shows how to partition the large dependency DAGs from BuildStream across concurrent runners on GitHub Actions.
  It streams CAS archives and coordinates cache keys.
- **Container-Native OS Delivery**: It uses BuildStream's `build-oci` tooling to create bootable container images in OCI format (`containers.bootc: '1'`).
  It also outputs live installation media for UEFI.

#### Proposed Listing
```markdown
- **[Tromso](https://github.com/tuna-os/tromso)**: A KDE Plasma 6 desktop operating system built entirely from source with BuildStream 2 on top of freedesktop-sdk, publishing bootable OCI container images managed with bootc.
```

We would be glad to contribute a short case study or summary for the documentation to `buildstream.build`.
It could describe our experiences and architecture patterns with BuildStream 2.

- **Repository**: https://github.com/tuna-os/tromso
- **Architecture Documentation**: https://github.com/tuna-os/tromso/blob/main/docs/ARCHITECTURE.md
- **CI Pipeline Guide**: https://github.com/tuna-os/tromso/blob/main/docs/ci-and-iso-pipeline.md

---

## 2. freedesktop-sdk Alignment Memo

**Target**: `freedesktop-sdk` maintainers (`freedesktop-sdk.io`, GitLab `freedesktop-sdk/freedesktop-sdk`).  
**Channel**: freedesktop-sdk Matrix room (`#freedesktop-sdk:matrix.org`) or GitLab discussion.

### Alignment Summary

Tromso relies directly on `freedesktop-sdk` as its foundational build junction (`elements/freedesktop-sdk.bst`).
We view freedesktop-sdk as our primary upstream.

#### Current Alignment Practices
1. **Upstream Conventions (ADR 0004)**:
   - Enforce `fatal-warnings: unaliased-url` across all 650+ source URLs in the project.
   - Provide comprehensive mirror coverage via `include/mirrors.yml` for resilience against upstream source outages.
   - Use standard components from freedesktop-sdk directly (e.g. `linux-pam-base`, `polkit`, `networkmanager`).
     Do not make separate versions of them.
2. **Snapshot Updates**:
   - Track stable releases of freedesktop-sdk (now on the `25.08.x` stable branch).
   - Synchronize updates for the upstream junction through automated source updates (`bst source track`).
3. **Collaboration & Upstream Value**:
   - Tromso's recipes for KDE Frameworks 6 and Qt 6 provide a battle-tested reference for consumers of freedesktop-sdk.
     These consumers target Qt/KDE software.
   - We actively document and monitor build quirks, capability requirements (`fakecap`), and dynamic linker caches in sandbox environments.

---

## 3. Blog Post / Technical Case Study Draft

**Title**: Build KDE with BuildStream: Lessons from Tromso  
**Target Publication**: `buildstream.build` news / `tunaos.org` blog  
**Author**: Tromso Maintainers

### Draft Article

In modern Linux infrastructure, containerization and immutable operating systems are standard practice for server deployments.
However, the desktop ecosystem has largely relied on traditional package managers or non-deterministic container layers.

**Tromso** explores an alternative path.
It composes a complete, modern operating system for desktops with KDE Plasma 6 directly from upstream source trees.
It uses **BuildStream 2** on **freedesktop-sdk**.
It publishes the result as a bootable container image in OCI format that **bootc** manages.

Here are the key technical lessons from our work to build a desktop OS from source with BuildStream.

#### 1. Managing Scale: The Single-Repository Model
A desktop operating system is a massive dependency graph.
Tromso includes Qt 6 (~30 elements), KDE Frameworks 6 (~70 elements), and KDE Plasma 6 (~41 elements).
It also includes system libraries, audio servers, graphics drivers, and system infrastructure.

Initially, we split package definitions into a separate repository for metadata with a BuildStream junction.
However, we discovered penalties for cache invalidation from nested junctions.
The junctions also increased friction in cross-repository maintenance.

We put all KDE elements directly into a single `elements/` hierarchy.
We retained only `freedesktop-sdk.bst` as an external junction.
This gave us:
- Atomic commits across package definitions and system configuration.
- Simpler dependency records and cleaner cache behavior.
- Clear separation between the upstream SDK foundation and the application layer for the desktop.

#### 2. Strict Sandboxing & Source Discipline
Reproducibility cannot be an afterthought.
Tromso configures `fatal-warnings: [unaliased-url, unstaged-files]` in `project.conf`.
This guarantees that every source tarball or Git repository resolves through a structured alias in `include/aliases.yml`.
Fallback mirrors in `include/mirrors.yml` back each source.

In our offline suite of pytest tests, we validate that contributors cannot commit any hardcoded URLs or un-mirrored tarballs.
This prevents unexpected breaks in upstream networks that halt builds.

#### 3. Overcoming Sandbox Nuances for Desktop Environments
A build of a desktop environment in hermetic sandboxes has unique challenges for integration:
- **File Capabilities**: Security-sensitive binaries like `kwin_wayland` (`cap_sys_nice`) and `newuidmap`/`newgidmap` (`cap_setuid`/`cap_setgid`) need specific POSIX capabilities.
  In unprivileged build environments, we use `fakecap` inside the sandbox to capture and commit these attributes cleanly.
- **Dynamic Linker Cache (`ldconfig`)**: In layered OCI images, Qt 6 libraries reside across two layers.
  These are the parent layer for the base OS and the desktop layer.
  The element for image composition assembles an ephemeral overlay filesystem.
  This lets `ldconfig` generate a unified linker cache.
  The cache lets SDDM and Plasma boot smoothly without delays from path discovery at runtime.

#### 4. Distributed Multi-Runner CI with Content-Addressable Storage
Builds of 200+ source packages on free runners from GitHub Actions exceed the time limits for a single runner.
To solve this without a dedicated build farm, Tromso has a multi-runner pipeline:
1. A plan job calculates the execution order from the topology.
   It partitions uncached elements into balanced chunks.
2. An initial runner builds the core bootstrap elements.
   It publishes the CAS snapshot to GitHub Container Registry (GHCR) with ORAS.
3. Concurrent runners in the matrix pull the core CAS and execute their designated chunks in parallel.
   They export CAS archives for each chunk.
4. A final runner merges the CAS archives and does the final OCI export.
   It signs the container image with Cosign and keyless signatures via OIDC from GitHub Actions.

#### Conclusion
BuildStream 2 provides the exact primitives needed for reproducible, source-driven OS composition.
These include deterministic sandboxes, fine-grained artifact caches, and content-addressed storage.
Tromso demonstrates that these capabilities scale beyond isolated developer SDKs to complete, bootable desktop operating systems.

---

## 4. Conference Proposal (FOSDEM 2027)

**Target Devroom**: Distributions / Desktops / Build Systems.
**Format**: 25-minute presentation + 5-minute Q&A.
**Submission Title**: Build Systems for Immutable Desktops: Compose KDE Linux with BuildStream and bootc

### Abstract
Container-native operating systems that `bootc` manages bring container agility and atomic upgrades to bare-metal systems.
Yet, most bootc images use layers of package managers inside standard Containerfiles.
This sacrifices source reproducibility and dependency provenance.

This talk presents **Tromso**, a community project for an operating system.
It uses **BuildStream 2** and **freedesktop-sdk** to build a desktop with KDE Plasma 6 completely from source.
The output consists of bootable container images in OCI format.

We will walk through the architectural journey to build a desktop distribution:
- Design a BuildStream DAG with 200+ elements for Qt 6, KDE Frameworks, and components for Wayland desktops.
- Move from nested junctions across multiple repos to a unified single-tree model.
- Solve sandbox challenges: manage file capabilities, linker cache generation, and user configuration.
- Scale CI: partition the large dependency graphs from BuildStream across ephemeral multi-runner workers with CAS chunks.
- Transform BuildStream trees into bootable containers in OCI format and live installation media for UEFI.

Attendees will gain practical insights into how to apply BuildStream 2 and modern patterns for image-based deployment to operating systems for desktops.

---

## 5. Community Engagement Protocol & Channels

When maintainers engage with the BuildStream and freedesktop-sdk communities, they should observe the following guidelines:

### Primary Communication Venues
- **Matrix**:
  - BuildStream: `#buildstream:matrix.org`
  - freedesktop-sdk: `#freedesktop-sdk:matrix.org`
- **GitLab**:
  - BuildStream: `https://gitlab.com/BuildStream/buildstream`
  - freedesktop-sdk: `https://gitlab.com/freedesktop-sdk/freedesktop-sdk`
- **Discourse**: `https://discourse.gnome.org/c/buildstream/` (where applicable)

### Engagement Principles
1. **Be Honest About Maturity**: Acknowledge that Tromso is an active Alpha project under open development.
   Present Tromso as an architectural showcase and educational experience, not a finished commercial product.
2. **Offer Upstream Value**: When you discuss package solutions, share the `.bst` manifests and build patterns with other projects.
   Examples include `gnome-build-meta` or the early `kde-buildstream` project under ADR 0003.
3. **Respect Upstream Feedback**: Actively listen to suggestions from maintainers of BuildStream and freedesktop-sdk.
   These can concern junction management, cache retention, and best practices for sandboxes.

---

## 6. Maintainer Publication & Action Checklist

Before public transmission, a maintainer must review and execute the following steps:

- [ ] **Verify Against Roadmap**: Confirm that the technical details align with the current state in [ROADMAP.md](../../ROADMAP.md).
  Do not make unverified claims of production stability.
- [ ] **Designate Contact**: Confirm the maintainer who will act as the official contact for outreach to BuildStream/freedesktop-sdk.
- [ ] **Submit Upstream PR / Issue for Documentation**:
  - Open an issue or MR on `buildstream/buildstream` or `buildstream.build`.
    Propose Tromso's inclusion in documentation.
  - Link to `docs/ARCHITECTURE.md` and the repository README.
- [ ] **Matrix Introduction**:
  - Introduce Tromso in `#buildstream:matrix.org` with the short coordination pitch.
  - Invite feedback on the architecture for multi-runner CAS chunks and package patterns.
- [ ] **FOSDEM 2027 Submission**:
  - Submit the presentation abstract during the FOSDEM 2027 call for participation (CFP) window.
- [ ] **Record Execution**:
  - Update issue [#374](https://github.com/tuna-os/tromso/issues/374) with links to submitted proposals, pull requests, and conference submissions.
    Keep #374 open until maintainers complete the external visibility milestones.
