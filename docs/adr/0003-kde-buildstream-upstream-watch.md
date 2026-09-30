# ADR 0003: Keep the upstream KDE BuildStream project as a watch item

- Status: accepted
- Date: 2026-08-10
- Issue: [tuna-os/tromso#85](https://github.com/tuna-os/tromso/issues/85)

## Context

`invent.kde.org/packaging/kde-buildstream` is a KDE package project with
participation from active KDE maintainers. It is also a separate project at an
early stage. The repository does not yet show a complete dependency graph for
Plasma. It also does not show a bootable image of KDE Linux that compares with
the current BuildStream graph in Tromso.

Tromso no longer has a `kde-build-meta` junction. The project moved the KDE and
Plasma elements into this repository. Thus, a migration would replace all local
elements instead of only the URL of a junction.

## Decision

Do not migrate Tromso to `kde-buildstream` now. Keep the current graph of
elements in this repository, and treat the upstream project as a watch item.
The workflow that tracks sources must track only element paths in this
repository. It must not try to update the removed
`elements/kde-build-meta.bst` junction.

This decision does not reject the upstream project. It prevents the production
build from use of an incomplete graph. It also keeps a clear path to a future
trial branch.

## Gates for another evaluation

Revisit the decision when the upstream project can show all these items:

1. a complete and reproducible dependency graph for Plasma, with the packages
   that Tromso builds now;
2. a native BuildStream path for the image and ISO, without mkosi for final
   assembly; and
3. a bootable image and a policy for source versions and releases. The project
   must also give CI evidence to compare with the OCI and ISO gates in Tromso.

Use an isolated branch or parallel junction for the eventual trial. Complete a
full graph build and QEMU boot test before you change the production project.
First submit additions specific to Tromso, such as Plymouth and core boot
dependencies, to the upstream project. Otherwise, record them explicitly in
the trial delta.
