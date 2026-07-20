kind: junction
description: Junction to tuna-os/kde-build-meta (KDE Plasma 6 build metadata)

# kind: git (core plugin, not the community git_repo plugin) — this junction
# is what loads the community plugins in the first place, so it can't use a
# source kind that itself comes from those plugins (bootstrap circularity).
# Still trackable via `bst source track`, so track-bst-sources.yml works.
sources:
- kind: git
  url: github:tuna-os/kde-build-meta.git
  track: master
  ref: 363c8ba0d7ceb106931c1c569fd5873a3a37008e

config:
  options:
    arch: "%{arch}"
