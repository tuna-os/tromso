# BuildStream community reference drafts

Issue: [#374](https://github.com/tuna-os/tromso/issues/374).

Status: drafts for maintainer review. External outreach and submissions remain incomplete.

## Context and maturity

TunaOS Tromsø is an independent Alpha project. It composes KDE Plasma 6 with BuildStream 2 on `freedesktop-sdk`.
The repository includes an element tree, OCI composition, live ISO tools, and CI for multiple runners.
The design targets images for `bootc`.
These drafts do not establish reliable installation, production readiness, or bit-for-bit reproducibility.
Consult the [roadmap](../../ROADMAP.md) and exact run evidence before public claims or candidate tests.

## 1. BuildStream outreach pitch

Target: the BuildStream project at `buildstream.build` and `buildstream/buildstream` on GitLab.

Possible route: an issue or documentation merge request for a project list or case study.
Confirm the venue and its rules before submission.

### Draft proposal

Title: Propose TunaOS Tromsø as an Alpha project that uses BuildStream

Hello BuildStream team,

We would like to propose [TunaOS Tromsø](https://github.com/tuna-os/tromso) for a project list or technical case study.
Tromsø is an independent Alpha project that composes Plasma 6 from source with BuildStream 2 and `freedesktop-sdk`.
It targets OCI images for `bootc`. We do not claim qualified installation or production readiness.

Topics that could help other BuildStream users include:

- Recipes for Qt 6, KDE Frameworks, Plasma, and desktop components.
- A common `elements/` tree with `freedesktop-sdk.bst` as an external junction.
- Source aliases and mirrors in `include/aliases.yml` and `include/mirrors.yml`.
- Project checks such as `fatal-warnings: [unaliased-url, unstaged-files]`.
- CI that divides the dependency graph across runners and exchanges CAS archives.
- Export through `build-oci` with `containers.bootc: '1'` and tools for live media.

We can offer a short case study about these mechanisms and their limits.
Source control and sandbox isolation support repeatable builds. They do not prove reproducibility of output.

### Proposed entry

[TunaOS Tromsø](https://github.com/tuna-os/tromso) is an Alpha project that composes Plasma 6 with BuildStream 2 and `freedesktop-sdk`.
It targets OCI images for `bootc` and explores CI across multiple runners.

References:

- Repository: https://github.com/tuna-os/tromso
- Architecture: https://github.com/tuna-os/tromso/blob/main/docs/ARCHITECTURE.md
- Pipeline: https://github.com/tuna-os/tromso/blob/main/docs/ci-and-iso-pipeline.md

## 2. freedesktop-sdk alignment memo

Target: maintainers at `freedesktop-sdk.io` and `freedesktop-sdk/freedesktop-sdk` on GitLab.

Possible channels: `#freedesktop-sdk:matrix.org` or a relevant GitLab discussion, subject to local rules.

Tromsø uses `elements/freedesktop-sdk.bst` as its base junction.
Before outreach, compare these topics with the candidate's source and [roadmap](../../ROADMAP.md):

- Source aliases and mirrors under the conventions in ADR 0004.
- Use of SDK components such as `linux-pam-base`, `polkit`, and `networkmanager`.
- The exact SDK branch and pinned reference; do not copy an old version claim.
- Review of source updates from `bst source track`.
- Recipes for Qt and KDE that other consumers could inspect or adapt.
- Reports about capabilities, `fakecap`, and the cache that `ldconfig` generates.

Mirrors can provide alternative sources. They do not guarantee availability during upstream outages.
The recipes are Alpha work, not a proven reference for production.

## 3. Technical article draft

Proposed title: KDE with BuildStream: lessons from TunaOS Tromsø.

Possible venues: `buildstream.build` news or the `tunaos.org` blog, subject to editorial approval.

Proposed authors: Tromsø maintainers, after their consent.

### Draft article

TunaOS Tromsø explores desktop composition from source with BuildStream 2 and `freedesktop-sdk`.
The target is Plasma 6 in OCI images for `bootc`.
The project remains Alpha. The architecture offers topics for review, not proof of a qualified desktop release.

### One tree for desktop recipes

The `elements/` tree contains recipes for Qt, KDE Frameworks, Plasma, libraries, audio, and graphics components.
The SDK remains an external junction.
A common repository allows changes to desktop recipes and system configuration in the same commit.
Do not claim measured improvements to cache behavior without comparative run evidence.

### Source discipline and sandbox constraints

`project.conf` defines fatal warnings such as `unaliased-url` and `unstaged-files`.
The files for aliases and mirrors describe routes to sources. Repository tests check the source conventions.
These checks help find defects in configuration. They cannot guarantee availability of sources or identical output across builds.

Capabilities need care in unprivileged sandboxes.
The build uses `fakecap` to preserve metadata for binaries such as `kwin_wayland`, `newuidmap`, and `newgidmap`.
Relevant capabilities include `cap_sys_nice`, `cap_setuid`, and `cap_setgid`.
Maintainers must validate the final image's metadata and behavior.

The OCI composition also needs a library cache across layers.
The build uses `ldconfig` for this cache. Its presence does not by itself prove that SDDM or Plasma starts correctly.

### CI across runners

The pipeline divides work across runners on GitHub Actions:

1. The job for the plan orders dependencies and groups elements into chunks.
2. A runner builds bootstrap artifacts and exports CAS through ORAS to GitHub Container Registry.
3. Jobs in the matrix import CAS, build their assigned elements, and export archives.
4. A job combines the archives and tries OCI export.
5. Publication uses Cosign with OIDC from GitHub Actions.

This describes the workflow design. A workflow definition does not prove a successful publication or a valid signature for every run.
Use the [pipeline guide](https://github.com/tuna-os/tromso/blob/main/docs/ci-and-iso-pipeline.md) for current details and evidence.

### Conclusion

BuildStream offers dependency control, sandbox isolation, and content-addressed artifacts for source composition.
Tromsø explores these mechanisms for a desktop OS. Reproducibility and release readiness still need evidence for specific candidates.

## 4. Conference proposal: FOSDEM 2027

Possible devrooms: distributions, desktops, or build systems.

Proposed format: 25 minutes plus 5 minutes for questions.

Proposed title: Desktop composition with BuildStream and bootc.

### Abstract

TunaOS Tromsø explores Plasma 6 from source with BuildStream 2 and `freedesktop-sdk`.
The goal is OCI images for `bootc`, with tools for UEFI live media.
This talk describes the architecture, Alpha failures, and evidence needed to qualify a candidate.
It does not claim a production release or guaranteed reproducibility.

Proposed topics:

- The dependency graph for Qt, KDE Frameworks, and Wayland components.
- Desktop recipes in one tree with an SDK junction.
- Capabilities, the library cache, and system configuration in sandboxes.
- CAS exchange across CI runners.
- OCI export and tools for live media.

Maintainers and speakers must approve the proposal before submission.
A suitable call for participation and acceptance from organizers are separate requirements.

## 5. Community channels and conduct

Confirm each venue's current scope before contact.

- BuildStream Matrix: `#buildstream:matrix.org`.
- SDK Matrix: `#freedesktop-sdk:matrix.org`.
- BuildStream GitLab: https://gitlab.com/BuildStream/buildstream
- SDK GitLab: https://gitlab.com/freedesktop-sdk/freedesktop-sdk
- BuildStream Discourse, where applicable: https://discourse.gnome.org/c/buildstream/

State Alpha status and the limits of the evidence.
Share `.bst` recipes and concrete reports that upstream maintainers can inspect.
Projects such as `gnome-build-meta` or `kde-buildstream` might have related concerns; do not assume their interest or approval.
See ADR 0003 for the upstream context.
Respect feedback about junctions, cache retention, and sandbox isolation.
Do not use unrelated code issues for publicity.

## 6. Maintainer approval and publication checklist

A maintainer must approve the final copy and each external action. This document publishes no outreach.

- [ ] Compare claims with [ROADMAP.md](../../ROADMAP.md), source definitions, and exact run evidence.
- [ ] Select a maintainer as the public contact.
- [ ] Confirm the preferred route for a BuildStream project entry or case study.
- [ ] Submit an issue or merge request only after review.
- [ ] Include `docs/ARCHITECTURE.md` and the repository README as references.
- [ ] Introduce the project in Matrix only with permission under channel rules.
- [ ] Request feedback on CAS exchange and desktop recipes.
- [ ] Submit the FOSDEM proposal through a suitable call after speaker approval.
- [ ] Record submissions, feedback, and live URLs in [#374](https://github.com/tuna-os/tromso/issues/374).
- [ ] Keep #374 open until maintainers account for the intended external actions.
