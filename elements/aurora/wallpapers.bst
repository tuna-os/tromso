kind: manual
description: Aurora wallpapers and default wallpaper links

sources:
- kind: tar
  url: github_files:ublue-os/artwork/releases/download/aurora-v2026-04-23/aurora-wallpapers.tar.zstd
  ref: fd029232de0bc45f327c394ecd00023fe52d30b376fe19046660c82f6f8bdcd7
  base-dir: ""

depends:
- kde-build-meta.bst:freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  - |
    mkdir -p "%{install-root}%{datadir}/backgrounds/aurora" "%{install-root}%{datadir}/wallpapers"
    cp -r kde/. "%{install-root}%{datadir}/backgrounds/aurora/"

    for dir in "%{install-root}%{datadir}/backgrounds/aurora"/*; do
      if [ -d "$dir" ]; then
        ln -sr "$dir" "%{install-root}%{datadir}/wallpapers/"
      fi
    done

    ln -sr "%{install-root}%{datadir}/backgrounds/aurora/aurora-wallpaper-6" \
      "%{install-root}%{datadir}/backgrounds/aurora/aurora-wallpaper-1"
    ln -sr "%{install-root}%{datadir}/backgrounds/aurora/aurora-wallpaper-1" \
      "%{install-root}%{datadir}/wallpapers/aurora-wallpaper-1"

    ln -sr "%{install-root}%{datadir}/backgrounds/aurora/aurora-wallpaper-12/contents/images/3840x2160.jxl" \
      "%{install-root}%{datadir}/backgrounds/default.jxl"
    ln -sr "%{install-root}%{datadir}/backgrounds/aurora/aurora-wallpaper-12/contents/images/3840x2160.jxl" \
      "%{install-root}%{datadir}/backgrounds/default-dark.jxl"
    ln -sr "%{install-root}%{datadir}/backgrounds/aurora/aurora-wallpaper-12" \
      "%{install-root}%{datadir}/wallpapers/Aurora"
    ln -sr "%{install-root}%{datadir}/backgrounds/aurora/aurora.xml" \
      "%{install-root}%{datadir}/backgrounds/default.xml"
  - "%{install-extra}"
