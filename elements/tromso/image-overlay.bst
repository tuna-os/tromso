kind: manual
description: Image overlay payload vendored from ublue-os/aurora system_files/shared (functional files only)

sources:
- kind: git_repo
  url: github:ublue-os/aurora.git
  track: main
  ref: stable-20260902.1-10-g9d64a72b4d6e1141531ecb5982fce13320d165d7

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  # Artwork guard. This element tracks ublue-os/aurora's main branch and
  # track-bst-sources.yml automerges ref bumps, so an upstream commit could
  # otherwise re-introduce Aurora artwork into the image without review
  # (tuna-os/tromso#300). Drop any image assets before staging; only functional
  # files are wanted from this payload.
  - |
    find system_files -type f \( \
        -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.jxl' \
        -o -iname '*.svg' -o -iname '*.svgz' -o -iname '*.webp' -o -iname '*.gif' \
      \) -print -delete
  - |
    if [ -d system_files/shared/usr ]; then
      cp -r system_files/shared/usr/./ "%{install-root}%{prefix}/"
    fi
    if [ -d system_files/shared/etc ]; then
      mkdir -p "%{install-root}%{sysconfdir}"
      cp -r system_files/shared/etc/./ "%{install-root}%{sysconfdir}/"
    fi
  - "%{install-extra}"
