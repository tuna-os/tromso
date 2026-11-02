# KDE community partnership drafts

Issue: [#372](https://github.com/tuna-os/tromso/issues/372).

Status: drafts for maintainer review. Maintainers have not completed external outreach or submissions.

## Context and maturity

TunaOS Tromsø is an independent Alpha project. It uses BuildStream 2 and `freedesktop-sdk` to compose KDE Plasma 6 from source.
The goal is OCI images for `bootc`, with tools for live ISO media.
These drafts describe the design, not proof of reliable installation, updates, rollback, or reproducible output.
Consult [ROADMAP.md](../../ROADMAP.md) for release gates and run evidence.
The gates cover builds, installation, release operations, user guidance, and desktop tests.

Tromsø has no KDE endorsement. It is not a variant of [KDE Linux](https://invent.kde.org/kde-linux/kde-linux).
KDE Linux uses `mkosi` and Arch Linux packages. Tromsø uses BuildStream and the SDK.
Package choices can inform work across projects without a shared release process.

Follow the [KDE trademark policy](https://www.kde.org/community/whatiskde/trademarks.php) before use of KDE marks.
KDE e.V. owns the KDE® and K Desktop Environment® trademarks.
Do not imply an approved partnership.

## 1. Initial outreach pitch

Possible channels, subject to their current rules:

- KDE Promo: an issue on `teams/promo` or `kde-promo@kde.org`.
- Matrix: `#kde-promo:kde.org` and `#kde-devel:kde.org`.
- [KDE Discuss](https://discuss.kde.org/): the Community category.

### Draft

Subject: Feedback request: KDE Plasma 6 with BuildStream and bootc

Hello KDE Promo and Plasma teams,

We would like to introduce [TunaOS Tromsø](https://github.com/tuna-os/tromso), an independent Alpha project.
We compose Plasma 6 with BuildStream 2 on `freedesktop-sdk`. The goal is OCI images for `bootc`.
We seek feedback on desktop integration and ways to share our element recipes.
We do not claim stable releases or proven installation and rollback behavior.

The repository contains recipes for Qt 6, KDE Frameworks, and Plasma 6.
It also contains tools for OCI composition and CI across multiple runners.
These could provide material for a technical case study after review of the evidence.

Possible joint work:

- A technical article for KDE Promo, Planet KDE, or `tunaos.org`, subject to editorial approval.
- Links between relevant project guides and upstream KDE resources, subject to upstream review.
- Feedback from the Visual Design Group (VDG) on desktop defaults and Breeze use.
- Proposals for Akademy and FOSDEM 2027, subject to suitable calls.

We welcome feedback and contact with maintainers who share these interests.

- Repository: https://github.com/tuna-os/tromso
- Roadmap: https://github.com/tuna-os/tromso/blob/main/ROADMAP.md
- Architecture: https://github.com/tuna-os/tromso/blob/main/docs/ARCHITECTURE.md
- Pipeline: https://github.com/tuna-os/tromso/blob/main/docs/ci-and-iso-pipeline.md

## 2. Technical article draft

Possible venues: KDE Promo, Planet KDE, or `tunaos.org`. Editors must approve publication.

### Plasma 6 from source with BuildStream and bootc

TunaOS Tromsø explores source composition for a desktop based on images.
BuildStream describes dependencies and builds artifacts in sandboxes. The SDK supplies the base for the desktop.
The goal is OS updates through `bootc`, separate from applications through Flatpak and Flathub.
Commands such as `bootc upgrade` describe the intended update path, not a qualified release procedure.
Tromsø still needs evidence for its installation, update, and rollback paths.

### Architecture

- The junction at `freedesktop-sdk.bst` supplies libraries for the base and graphics components.
- The element tree contains recipes for Qt 6, KDE Frameworks 6, and Plasma 6.
- The OCI stage uses `build-oci` and the `containers.bootc: '1'` annotation.
- The design uses composefs for the root filesystem.
- CI divides the dependency graph across runners on GitHub Actions.
- Runners exchange archives of content-addressed storage (CAS) through GitHub Container Registry.

Source references and caches help control build inputs. They do not establish bit-for-bit reproducibility or immunity to upstream outages.

### Desktop integration topics

SDDM and graphics setup need tests for each supported environment.
The software fallback uses `Environment=QT_QUICK_BACKEND=software` where appropriate.
The composition process uses `ldconfig` to prepare the cache for libraries across layers.
The build uses `fakecap` to preserve capability metadata from unprivileged sandboxes.

For example, `kwin_wayland` uses `cap_sys_nice`. Capability metadata needs validation in the final image.
These mechanisms do not establish readiness of the desktop.

### Invitation

Tromsø remains Alpha. Consult the roadmap and exact artifact evidence before a test in QEMU or from live media.
We welcome reports on recipes, CMake dependencies, desktop defaults, and alignment with KDE design guidance.

- Project: https://github.com/tuna-os/tromso
- Build instructions: https://github.com/tuna-os/tromso#readme

## 3. Badges, graphics, and trademarks

Badge text proposals include “Built with KDE Plasma 6” and “Powered by KDE Plasma”.
A maintainer must check the policy and get any necessary approval before use.
Neither proposal gives permission to use a mark.
Possible locations include the README, `tunaos.org/tromso`, and project docs.

- Use assets from KDE Promo only under their applicable terms.
- Do not change logo proportions, aspect ratio, or colors.
- Include the attribution that the policy specifies for each mark.
- State that Tromsø is independent and is not an official product of KDE e.V.
- Ask KDE Promo to review attribution text before publication.

## 4. Documentation links and support boundaries

Useful upstream references:

- [KDE UserBase](https://userbase.kde.org/)
- [Plasma 6 user guide](https://docs.kde.org/stable6/en/plasma-desktop/plasma-desktop/)
- [KDE design guidance](https://develop.kde.org/hig/)

Report defects in Tromsø images, recipes, or updates to `tuna-os/tromso/issues`.
Report upstream defects in Plasma to `bugs.kde.org`, with evidence that identifies the upstream component.

### Proposed entry for upstream review

[TunaOS Tromsø](https://github.com/tuna-os/tromso) is an independent Alpha project.
It composes Plasma 6 with BuildStream 2 and `freedesktop-sdk`, with OCI images for `bootc` as its target.

Ask maintainers of KDE resources about the scope for this entry before submission.

## 5. Conference proposals

### Akademy 2027

Proposed format: 30 minutes plus 10 minutes for questions.

Proposed track: system integration, distributions, or package recipes.

Proposed title: Plasma on bootc: desktop composition from source.

A Tromsø maintainer would present. An upstream collaborator could join only after an explicit invitation and acceptance.
No event or speaker has approved this draft.

#### Abstract

TunaOS Tromsø explores Plasma 6 with BuildStream 2 and `freedesktop-sdk`.
This talk describes the dependency graph and export to OCI images for `bootc`.
It discusses failures of Alpha integration and the evidence needed to qualify a candidate.
It does not present the project as ready for production.

#### Outline

1. Explain the goals of desktops based on images.
2. Describe the dependency graph for Qt, KDE Frameworks, and Plasma.
3. Show OCI composition with `containers.bootc: '1'` and composefs.
4. Discuss `fakecap`, SDDM fallbacks, `ldconfig`, and systemd dependencies.
5. Describe CAS exchange across CI runners and Cosign with OIDC.
6. Discuss source reproducibility as a goal that needs evidence.

### FOSDEM 2027

Proposed venue: a suitable devroom for desktops or distributions based on images.

Proposed format: 20 minutes plus 5 minutes for questions.

Proposed title: KDE Plasma 6 with BuildStream and bootc.

#### Abstract

Tromsø connects source composition with a design for OS updates through OCI images.
This talk describes recipes for Plasma, sandbox constraints, and tools for live media.
It separates implemented mechanisms from unqualified boot, installation, and rollback paths.
The submission and any joint presentation need approval from maintainers, speakers, and organizers.

## 6. Technical collaboration

### Visual review

The project chose the Breeze Dark theme after the asset audit in [#373](https://github.com/tuna-os/tromso/issues/373).
See also the removal of third-party artwork in [#301](https://github.com/tuna-os/tromso/pull/301).
A maintainer should check the candidate's actual defaults before a request for review.

Possible venues include KDE Discuss (Visual Design) and `#kde-vdg:kde.org`, subject to their rules.

Ask reviewers to check:

- Breeze Dark across SDDM, the lock screen, and panels.
- Fastfetch output and use of KDE marks.
- The Plymouth splash.
- Original project assets and wallpapers against KDE design guidance.

### Release and integration feedback

Use `bst source track` to inspect updates to upstream sources. Review changes before adoption.
Send reproducible reports about build defects or missing dependencies to the relevant upstream project.

Ask developers of KDE Linux and contributors to `kde-buildstream` whether they want to exchange technical reports.
See [ADR 0003](../adr/0003-kde-buildstream-upstream-watch.md).
Possible topics include Wayland startup under systemd, `xdg-desktop-portal-kde` with Flatpak, and composefs storage use.

## 7. Milestones and evidence

Issue [#372](https://github.com/tuna-os/tromso/issues/372) proposes these targets. They are goals, not completed results.

| Goal | Proposed target | Required evidence |
|---|---|---|
| KDE coverage | At least one article or mention | Published URL and editorial approval |
| Community interest | 50 stars from the KDE community | Dated count and a stated attribution method |
| Conference talks | Two joint presentations | Accepted sessions and speaker consent |
| Developer feedback | Ten KDE contributors test a candidate | Candidate identity, reports, and test context |
| Upstream reference | A link from BuildStream or KDE resources | Accepted entry and live URL |

Do not reuse an old star count as a current baseline.
Candidate tests depend on the release gates and available evidence in [ROADMAP.md](../../ROADMAP.md).

## 8. Maintainer approval and publication checklist

A maintainer must approve final copy and each external action. This document publishes no outreach.

- [ ] Compare each claim with the roadmap and exact CI evidence.
- [ ] Select a maintainer as the public contact.
- [ ] Confirm channel rules before an email or post to KDE Promo, Matrix, or KDE Discuss.
- [ ] Send the pitch only after approval.
- [ ] Request VDG review with screenshots and configuration from an identified candidate.
- [ ] Submit conference proposals only through the relevant calls for participation.
- [ ] Get speaker consent before a joint proposal.
- [ ] Coordinate article review and publication with KDE Promo or the selected editor.
- [ ] Add a badge only after the trademark review in Section 3.
- [ ] Record submission URLs, feedback, and approvals in #372.
- [ ] Keep #372 open until maintainers account for the intended external actions.
