# BuildStream Community Visibility & Reference Implementation Kit

Tracking: [#374](https://github.com/tuna-os/tromso/issues/374).  
Status: Drafts for maintainer review; external outreach, submissions, and coordination remain outstanding.

---

## Overview & Context

This kit provides reviewable outreach copy, technical case studies, and coordination proposals to increase visibility for Tromso within the **BuildStream** and **freedesktop-sdk** upstream communities.

### Project Maturity & Evidence Grounding
In accordance with the [Tromso Roadmap](../../ROADMAP.md), Tromso is currently in **Alpha**. The outreach materials in this kit focus on Tromso's implemented technical architecture:
- A large-scale, single-repo BuildStream 2 project (~200+ elements).
- A pure source-based composition of KDE Plasma 6 on top of `freedesktop-sdk`.
- Delivery as a bootable OCI container image using `bootc` and `build-oci`.
- A distributed multi-runner CAS chunking workflow running on GitHub Actions.

These drafts describe the verified build architecture and packaging patterns without making premature claims of end-user general availability or enterprise production stability before the Roadmap Alpha-to-Beta release gates are satisfied.

---

## 1. BuildStream Upstream Coordination Pitch

**Target**: BuildStream upstream project (`buildstream.build`, GitLab `buildstream/buildstream`).  
**Channel**: GitLab issue or documentation merge request proposing inclusion in "Notable Projects", "In the Wild", or the documentation Case Studies section.

### Proposal Text

**Title**: Propose Tromso (KDE Plasma desktop) as a BuildStream production reference implementation

Hello BuildStream team,

We would like to propose adding [Tromso](https://github.com/tuna-os/tromso) to the BuildStream documentation under "Notable Projects" or as a desktop OS reference implementation.

Tromso is an independent community project that uses BuildStream 2 to build a complete KDE Plasma 6 desktop operating system from source on top of `freedesktop-sdk`. Rather than relying on traditional distribution package managers or ad-hoc Containerfiles, Tromso leverages BuildStream's sandboxed, content-addressed build engine to assemble a reproducible OS tree, which is then packaged directly into a bootable OCI container managed by `bootc`.

#### Architectural Highlights & Relevance to BuildStream
- **Scale**: Tromso's element tree comprises over 200 elements, spanning the complete KDE stack (Qt 6, ~70 KDE Frameworks, Plasma 6, and applications) alongside core OS plumbing and graphics drivers.
- **Single-Repository Model**: Packaging is consolidated directly under `elements/` with `freedesktop-sdk.bst` as the sole external junction, illustrating how to manage complex desktop dependency graphs cleanly without nested-junction friction.
- **Upstream Standards Compliance**: Tromso strictly enforces BuildStream best practices (such as `fatal-warnings: [unaliased-url, unstaged-files]` and comprehensive fallback mirror coverage via `include/mirrors.yml`).
- **Distributed Multi-Runner CI**: Demonstrates how to partition large BuildStream dependency DAGs across concurrent runners on standard GitHub Actions using CAS archive streaming and cache key orchestration.
- **Container-Native OS Delivery**: Utilizes BuildStream's `build-oci` tooling to output bootable OCI container images (`containers.bootc: '1'`) and live UEFI installation media.

#### Proposed Listing
```markdown
- **[Tromso](https://github.com/tuna-os/tromso)**: A KDE Plasma 6 desktop operating system built entirely from source with BuildStream 2 on top of freedesktop-sdk, publishing bootable OCI container images managed with bootc.
```

We would be glad to contribute a short case study or documentation summary to `buildstream.build` highlighting our experiences and architectural patterns with BuildStream 2.

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
   - Enforcing `fatal-warnings: unaliased-url` across all 650+ source URLs in the project.
   - Comprehensive mirror coverage via `include/mirrors.yml` to ensure build resilience against upstream source outages.
   - Using freedesktop-sdk standard components directly (e.g. `linux-pam-base`, `polkit`, `networkmanager`) without re-implementing them.
2. **Snapshot Tracking**:
   - Tracking stable freedesktop-sdk releases (currently on `25.08.x` stable branch).
   - Synchronizing upstream junction updates through automated source tracking (`bst source track`).
3. **Collaboration & Upstream Value**:
   - Tromso's element recipes for KDE Frameworks 6 and Qt 6 provide a battle-tested reference for any freedesktop-sdk consumers targeting Qt/KDE software.
   - We actively document and monitor build quirks, capability requirements (`fakecap`), and dynamic linker caching in sandbox environments.

---

## 3. Blog Post / Technical Case Study Draft

**Title**: Building KDE with BuildStream: Lessons from Tromso  
**Target Publication**: `buildstream.build` news / `tunaos.org` blog  
**Author**: Tromso Maintainers

### Draft Article

In modern Linux infrastructure, containerization and immutable operating systems are standard practice for server deployments. However, the desktop ecosystem has largely relied on traditional package managers or non-deterministic container layering.

**Tromso** explores an alternative path: composing a complete, modern KDE Plasma 6 desktop operating system directly from upstream source trees using **BuildStream 2**, built upon **freedesktop-sdk**, and publishing the result as a bootable OCI container image managed with **bootc**.

Here are the key technical lessons learned from building a desktop OS from source with BuildStream.

#### 1. Managing Scale: The Single-Repository Model
A desktop operating system is a massive dependency graph. Tromso includes Qt 6 (~30 elements), KDE Frameworks 6 (~70 elements), KDE Plasma 6 (~41 elements), system libraries, audio servers, graphics drivers, and system plumbing.

Initially, we split packaging into a separate metadata repository connected via a BuildStream junction. However, we discovered that nested junctions introduced cache invalidation penalties and increased cross-repository maintenance friction. 

By consolidating all KDE elements directly into a single `elements/` hierarchy and retaining only `freedesktop-sdk.bst` as an external junction, we achieved:
- Atomic commits across package definitions and system configuration.
- Simplified dependency tracking and cleaner caching behavior.
- Clear separation between the upstream SDK foundation and the desktop application layer.

#### 2. Strict Sandboxing & Source Discipline
Reproducibility cannot be an afterthought. By configuring `fatal-warnings: [unaliased-url, unstaged-files]` in `project.conf`, Tromso guarantees that every single source tarball or Git repository resolves through a structured alias in `include/aliases.yml` and is backed by fallback mirrors in `include/mirrors.yml`.

In our offline pytest suite, we validate that no hardcoded URLs or un-mirrored tarballs can be committed, preventing unexpected upstream network breaks from halting builds.

#### 3. Overcoming Sandbox Nuances for Desktop Environments
Building a desktop environment in hermetic sandboxes presents unique integration challenges:
- **File Capabilities**: Security-sensitive binaries like `kwin_wayland` (`cap_sys_nice`) and `newuidmap`/`newgidmap` (`cap_setuid`/`cap_setgid`) require specific POSIX capabilities. In unprivileged build environments, we utilize `fakecap` inside the sandbox to capture and commit these attributes cleanly.
- **Dynamic Linker Caching (`ldconfig`)**: In layered OCI images, Qt 6 libraries reside across both the base OS parent layer and the desktop layer. Assembling an ephemeral overlay filesystem during the image composition element allows `ldconfig` to generate a unified linker cache that enables SDDM and Plasma to boot smoothly without runtime path discovery delays.

#### 4. Distributed Multi-Runner CI with Content-Addressable Storage
Building 200+ source packages on free GitHub Actions runners exceeds single-runner time limits. To solve this without requiring a dedicated build farm, Tromso implements a multi-runner pipeline:
1. A planning job calculates the topological execution order and partitions uncached elements into balanced chunks.
2. An initial runner builds the core bootstrap elements and publishes the CAS snapshot to GitHub Container Registry (GHCR) using ORAS.
3. Concurrent matrix runners pull the core CAS, execute their designated chunks in parallel, and export chunk CAS archives.
4. A final runner merges the CAS archives, performs the final OCI export, and signs the resulting container image with Cosign via GitHub Actions OIDC keyless signing.

#### Conclusion
BuildStream 2 provides the exact primitives needed for reproducible, source-driven OS composition: deterministic sandboxing, fine-grained artifact caching, and content-addressed storage. Tromso demonstrates that these capabilities scale beyond isolated developer SDKs to complete, bootable desktop operating systems.

---

## 4. Conference Proposal (FOSDEM 2027)

**Target Devroom**: Distributions / Desktops / Build Systems  
**Format**: 25-minute presentation + 5-minute Q&A  
**Submission Title**: Build Systems for Immutable Desktops: Composing KDE Linux with BuildStream and bootc

### Abstract
Container-native operating systems managed with `bootc` bring container agility and atomic upgrades to bare-metal systems. Yet, most bootc images are built by layering package managers inside standard Containerfiles, sacrificing source reproducibility and dependency provenance.

This talk presents **Tromso**, a community operating system project that uses **BuildStream 2** and **freedesktop-sdk** to build a KDE Plasma 6 desktop completely from source into bootable OCI container images. 

We will walk through the architectural journey of building a desktop distribution:
- Designing a 200+ element BuildStream DAG for Qt 6, KDE Frameworks, and Wayland desktop components.
- Transitioning from multi-repo nested junctions to a unified single-tree model.
- Solving sandbox challenges: managing file capabilities, linker cache generation, and user configuration.
- Scaling CI: partitioning large BuildStream dependency graphs across ephemeral multi-runner workers using CAS chunking.
- Transforming BuildStream trees into bootable OCI containers and UEFI live installation media.

Attendees will gain practical insights into applying BuildStream 2 and modern image-based deployment patterns to desktop operating systems.

---

## 5. Community Engagement Protocol & Channels

When engaging with the BuildStream and freedesktop-sdk communities, maintainers should observe the following guidelines:

### Primary Communication Venues
- **Matrix**:
  - BuildStream: `#buildstream:matrix.org`
  - freedesktop-sdk: `#freedesktop-sdk:matrix.org`
- **GitLab**:
  - BuildStream: `https://gitlab.com/BuildStream/buildstream`
  - freedesktop-sdk: `https://gitlab.com/freedesktop-sdk/freedesktop-sdk`
- **Discourse**: `https://discourse.gnome.org/c/buildstream/` (where applicable)

### Engagement Principles
1. **Be Honest About Maturity**: Acknowledge that Tromso is an active Alpha project under open development. Present Tromso as an architectural showcase and learning experience rather than a finished commercial product.
2. **Offer Upstream Value**: When discussing packaging solutions, share the `.bst` manifests and build patterns with other projects (such as `gnome-build-meta` or the early `kde-buildstream` project under ADR 0003).
3. **Respect Upstream Feedback**: Actively listen to suggestions from BuildStream and freedesktop-sdk maintainers regarding junction management, cache retention, and sandboxing best practices.

---

## 6. Maintainer Publication & Action Checklist

Before public transmission, a maintainer must review and execute the following steps:

- [ ] **Verify Against Roadmap**: Confirm that the technical details align with the current state in [ROADMAP.md](../../ROADMAP.md). Ensure no unverified claims of production stability are made.
- [ ] **Designate Contact**: Confirm the maintainer acting as the official contact for BuildStream/freedesktop-sdk outreach.
- [ ] **Submit Upstream Documentation PR / Issue**:
  - Open an issue or MR on `buildstream/buildstream` or `buildstream.build` proposing Tromso's inclusion in documentation.
  - Link to `docs/ARCHITECTURE.md` and repository README.
- [ ] **Matrix Introduction**:
  - Introduce Tromso in `#buildstream:matrix.org` using the short coordination pitch.
  - Invite feedback on the multi-runner CAS chunking architecture and packaging patterns.
- [ ] **FOSDEM 2027 Submission**:
  - Submit the presentation abstract during the FOSDEM 2027 call for participation (CFP) window.
- [ ] **Record Execution**:
  - Update issue [#374](https://github.com/tuna-os/tromso/issues/374) with links to submitted proposals, pull requests, and conference submissions. Keep #374 open until external visibility milestones are completed.
