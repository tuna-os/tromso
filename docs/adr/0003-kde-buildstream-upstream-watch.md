# ADR 0003: Keep the upstream KDE BuildStream project as a watch item

- Status: accepted
- Date: 2026-08-10
- Issue: [tuna-os/tromso#85](https://github.com/tuna-os/tromso/issues/85)

## Context

`invent.kde.org/packaging/kde-buildstream` is an official-looking KDE
packaging effort with active KDE maintainer participation. It is also a
separate, early-stage project. The repository does not yet provide evidence of
the complete Plasma dependency graph or a bootable KDE Linux image comparable
to Tromso's current BuildStream graph.

Tromso no longer has a `kde-build-meta` junction: the KDE/Plasma elements were
consolidated into this repository. A migration would therefore be a wholesale
replacement of the local element graph, not a junction URL update.

## Decision

Do not migrate Tromso to `kde-buildstream` now. Keep the current single-repo
element graph and treat the upstream project as a watch item. The source
tracking workflow must track only real repo-local element paths; it must not
attempt to update the removed `elements/kde-build-meta.bst` junction.

This is intentionally not a rejection of the upstream project. It avoids
making the production build depend on an incomplete graph while preserving a
clear path to a future trial branch.

## Re-evaluation gates

Revisit when the upstream project can demonstrate all of the following:

1. a complete, reproducible Plasma dependency graph covering the packages
   Tromso currently builds;
2. a native BuildStream image/ISO path that no longer depends on mkosi for
   final assembly; and
3. a bootable image, source pinning/release policy, and CI evidence that can be
   compared against Tromso's existing OCI and ISO gates.

The eventual trial should be an isolated branch or parallel junction, with a
full graph build and QEMU boot validation before changing the production
project. Any Tromso-specific additions, such as Plymouth and core boot
dependencies, should first be proposed upstream or explicitly accounted for
in the trial delta.
