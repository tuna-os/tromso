kind: junction
description: Junction to hanthor/kde-build-meta (fork of gnome-build-meta with KDE Plasma)

sources:
- kind: git_repo
  url: github:hanthor/kde-build-meta.git
  track: master
  ref: 344dd14d2bb3d953d7fcf075ce8023d4625fbb61

config:
  options:
    arch: "%{arch}"

  # Override junctions from kde-build-meta so they use our local overrides
  junction-overrides:
  - target: freedesktop-sdk.bst
    junction: freedesktop-sdk.bst
  - target: plugins/buildstream-plugins.bst
    junction: plugins/buildstream-plugins.bst
  - target: plugins/buildstream-plugins-community.bst
    junction: plugins/buildstream-plugins-community.bst
  - target: oci/integration/os-release.bst
    junction: oci/os-release.bst
