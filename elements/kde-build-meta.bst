kind: junction
description: Junction to tuna-os/kde-build-meta (KDE Plasma 6 build metadata)

# git_repo (not a sha-pinned tarball) so `bst source track` — and therefore
# the track-bst-sources.yml junction job — can actually bump it. Matches
# how kde-build-meta's own freedesktop-sdk.bst/gnome-build-meta.bst use
# git_repo as junction sources upstream.
#
# ref-format is explicit: this project inherits a project-wide git_repo
# default of ref-format: git-describe from freedesktop-sdk's runtime.yml
# (same reason xfce-linux's project.conf sets it explicitly too). Our ref
# below is a plain commit sha, so it must be pinned to ref-format: sha1
# per-source or BuildStream can't validate it as a ref at all — this is
# what caused "Subproject has no ref for junction: kde-build-meta.bst".
sources:
- kind: git_repo
  url: github:tuna-os/kde-build-meta.git
  track: master
  ref: 363c8ba0d7ceb106931c1c569fd5873a3a37008e
  ref-format: sha1

config:
  options:
    arch: "%{arch}"
