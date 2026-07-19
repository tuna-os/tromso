kind: junction
description: Junction to tuna-os/kde-build-meta (KDE Plasma 6 build metadata)

# git_repo (not a sha-pinned tarball) so `bst source track` — and therefore
# the track-bst-sources.yml junction job — can actually bump it.
sources:
- kind: git_repo
  url: github:tuna-os/kde-build-meta.git
  track: master
  ref: 363c8ba0d7ceb106931c1c569fd5873a3a37008e

config:
  options:
    arch: "%{arch}"
