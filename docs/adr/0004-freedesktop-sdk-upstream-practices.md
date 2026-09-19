# ADR 0004: freedesktop-sdk practices that Tromso adopts

- Status: accepted
- Date: 2026-09-19
- Issue: [tuna-os/tromso#264](https://github.com/tuna-os/tromso/issues/264)

## Context

freedesktop-sdk is the only real junction in Tromso. It is the closest thing
this project has to an upstream. Its
[guide for OS images](https://freedesktop-sdk.gitlab.io/documentation/guides/building-outputs/building-os.html#building-a-desktop-os-image),
and the `project.conf` behind it, state four rules:

1. every source uses an alias from `include/_private/aliases.yml`, and
   `unaliased-url` is a fatal warning;
2. `overlaps` is also a fatal warning;
3. a fixed `source-date-epoch` sets `SOURCE_DATE_EPOCH` for the whole project;
4. the disk image is an element. `bst build vm/desktop/efi.bst` runs
   `genimage` in the sandbox and writes `disk.img`. The user then gets that
   file with `bst artifact checkout` and grows it with `truncate`.

Tromso obeys some of these rules and diverges from the rest. No document
records the divergences. Each one therefore costs the same research again.

This ADR records which divergences are deliberate, which ones are debt, and
what gates the debt.

## Decision

### Adopt now: an alias for every source

This change makes `unaliased-url` fatal in `project.conf`.

The graph is clean today. All 653 source URLs under `elements/` use an alias
from `include/aliases.yml`. The rule costs nothing now, and it stops a
regression later.

The rule matters for two reasons. First, `include/mirrors.yml` can only
re-point a source that uses an alias. Second, `url` is part of the cache key
of a downloadable source. A hardcoded URL therefore needs a rebuild before it
can move.

`tests/pytest/test_source_aliases.py` checks the same rule offline. It needs
no BuildStream and no network, so a contributor sees a violation early. The
real gate is the `bst-validate` job. That job loads the whole graph and now
fails on the warning.

### Adopt now as a ratchet: `github_files:` for GitHub tarballs

Fifteen elements under `elements/kde-linux-deps/` fetch GitHub tarballs
through the generic `tar_https:` alias. That obeys `unaliased-url`, because
upstream keeps `tar_https` for single hosts. But `include/mirrors.yml` has no
entry for `tar_https`. It has one for `github_files`. Those fifteen elements
therefore have no mirror as a fallback.

A migration is a one-word edit for each element. It also changes the source
cache key. `imath` and `openexr` sit low in the graph, so the rebuild is
large. An explicit list in the test lets the fifteen elements stay as they
are. A sixteenth element fails the test. Make the list shorter when a rebuild
of those subtrees happens for another reason.

### Defer: `overlaps` as a fatal warning

Tromso does not adopt this rule yet. The OCI layer stack in `elements/oci/`
merges trees that overlap on purpose. It merges `/parent`, `/layer` and the
integration layers.

A fatal `overlaps` warning would red the build for reasons that are not bugs.
An audit must come first, and that audit needs a full `bst build`.

### Defer: `SOURCE_DATE_EPOCH` for the whole project

Tromso does not adopt this rule yet. `environment:` is part of the cache key
of every element. A new variable there invalidates the whole graph. Every CI
runner then rebuilds from zero.

The benefit is real, because upstream needs it for reproducible artifacts.
But a maintainer must schedule that cost. It does not belong in an unrelated
change. Tromso already pins the timestamps of the EROFS images through
`filesystem-time`.

### Do not adopt: `genimage` for disk assembly

The upstream element `vm/desktop/efi.bst` makes a partition table and
filesystems from a plain root tree. `genimage` does that work in the sandbox,
and BuildStream caches the result.

Tromso cannot use that shape. Its output is a bootc/ostree OCI image.
`bootc install to-disk` creates the on-disk layout at install time. The build
does not create it.

`just generate-bootable-image` is a local test harness for that install path.
It is not a step that makes a release image. `just build` makes the release
image. It already obeys the upstream shape: build an element, then check the
artifact out.

Two upstream practices carry over, and Tromso already uses both. The element
`elements/oci/tromso.bst` consumes `vm/prepare-image.bst` from upstream. The
`kde-linux-system/repart-config*.bst` elements from kde-build-meta are the
correct start point for disk assembly in the sandbox, if anyone wants it.

## Gates for a new evaluation

- `overlaps`: a clean `bst build oci/tromso.bst` with the warning on. It must
  prove that every overlap in the layer stack is deliberate. Add an explicit
  `overlap-whitelist` for those overlaps.
- `SOURCE_DATE_EPOCH`: a scheduled window for a full rebuild. Every chunk in
  `build-tromso-multirunner.yml` rebuilds from zero.
- `github_files:`: any PR that already rebuilds `elements/kde-linux-deps/`
  must migrate the elements that it touches.
