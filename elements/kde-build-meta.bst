kind: junction
description: Junction to tuna-os/kde-build-meta (KDE Plasma 6 build metadata)

# git_repo (not a sha-pinned tarball) so `bst source track` — and therefore
# the track-bst-sources.yml junction job — can actually bump it. Matches
# how kde-build-meta's own freedesktop-sdk.bst/gnome-build-meta.bst use
# git_repo as junction sources upstream. (The real fix for "Subproject has
# no ref for junction" was in project.conf: git_repo must come from a
# standalone plugin junction, not one nested inside this element itself —
# see the comment there.)
sources:
- kind: git_repo
  url: github:tuna-os/kde-build-meta.git
  track: master
  ref: 363c8ba0d7ceb106931c1c569fd5873a3a37008e

config:
  options:
    arch: "%{arch}"
