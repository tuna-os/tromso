kind: manual
description: Aurora logos, pixmaps, splash assets, and SDDM logo links

sources:
- kind: git_repo
  url: github:get-aurora-dev/common.git
  track: main
  ref: a40eb75e00df196d264e09cc9022f642be4304f0
- kind: remote
  url: https://invent.kde.org/plasma/plasma-workspace/-/raw/d3b5a422e586ee578efadfe462d0d0b5546aaa3b/lookandfeel/org.kde.breeze/contents/splash/images/busywidget.svgz
  ref: 606739a68533cd009d7401c25f449b2637cb66264a5358d42969fa1635ff3221
- kind: remote
  url: https://invent.kde.org/plasma/plasma-workspace/-/raw/d3b5a422e586ee578efadfe462d0d0b5546aaa3b/lookandfeel/org.kde.breeze/contents/splash/images/kde.svgz
  ref: 86e865eec31c48ca7002e4588b81f3916ce75af6a0d8a0d7056d9516a5b68f1e

build-depends:
- kde-build-meta.bst:freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/gzip.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/librsvg.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  - |
    scalable_dir="%{install-root}%{datadir}/icons/hicolor/scalable"
    places_dir="$scalable_dir/places"
    apps_dir="$scalable_dir/apps"
    pixmaps_dir="%{install-root}%{datadir}/pixmaps"
    splash_dir="%{install-root}%{datadir}/plasma/look-and-feel/dev.getaurora.aurora.desktop/contents/splash/images"
    splash_light_dir="%{install-root}%{datadir}/plasma/look-and-feel/dev.getaurora.auroralight.desktop/contents/splash/images"
    plymouth_dir="%{install-root}%{datadir}/plymouth/themes/spinner"
    sddm_dir="%{install-root}%{datadir}/sddm/themes/01-breeze-aurora"

    mkdir -p "$scalable_dir" "$places_dir" "$apps_dir" "$pixmaps_dir" "$splash_dir" "$splash_light_dir" "$plymouth_dir" "$sddm_dir"

    install -Dm0644 logos/distributor-logo.svg "$scalable_dir/distributor-logo.svg"
    install -Dm0644 logos/auroralogo-white.svg "$places_dir/auroralogo-white.svg"
    install -Dm0644 logos/distributor-logo-symbolic.svg "$places_dir/distributor-logo-symbolic.svg"
    install -Dm0644 logos/auroralogo-circle-symbolic.svg "$places_dir/auroralogo-circle-symbolic.svg"
    install -Dm0644 logos/auroralogo-pride.svg "$places_dir/auroralogo-pride.svg"
    install -Dm0644 logos/auroralogo-pride-trans.svg "$places_dir/auroralogo-pride-trans.svg"
    install -Dm0644 logos/aurora-banner.svg "$pixmaps_dir/aurora-banner.svg"

    ln -sr "$pixmaps_dir/aurora-banner.svg" "$pixmaps_dir/fedora-logo.svg"
    ln -sr "$pixmaps_dir/aurora-banner.svg" "$pixmaps_dir/fedora_whitelogo.svg"
    ln -sr "$scalable_dir/distributor-logo.svg" "$pixmaps_dir/fedora-logo-sprite.svg"
    ln -sr "$scalable_dir/distributor-logo.svg" "$places_dir/distributor-logo.svg"
    ln -sr "$scalable_dir/distributor-logo.svg" "$places_dir/auroralogo-gradient.svg"
    ln -sr "$places_dir/distributor-logo-symbolic.svg" "$places_dir/auroralogo-symbolic.svg"
    ln -sr "$places_dir/distributor-logo-symbolic.svg" "$places_dir/distributor-logo-white.svg"
    ln -sr "$places_dir/distributor-logo-symbolic.svg" "$places_dir/start-here.svg"
    ln -sr "$places_dir/distributor-logo-symbolic.svg" "$apps_dir/start-here.svg"
    ln -sr "$places_dir/distributor-logo.svg" "$sddm_dir/default-logo.svg"

    rsvg-convert -w 400 -h 100 -o "$pixmaps_dir/fedora-logo.png" logos/aurora-banner.svg
    rsvg-convert -w 128 -h 32 -o "$pixmaps_dir/fedora-logo-small.png" logos/aurora-banner.svg
    rsvg-convert -w 200 -h 100 -o "$pixmaps_dir/fedora_logo_med.png" logos/aurora-banner.svg
    rsvg-convert -w 256 -h 256 -o "$pixmaps_dir/system-logo.png" logos/distributor-logo.svg
    rsvg-convert -w 128 -h 128 -o "$pixmaps_dir/fedora-logo-sprite.png" logos/distributor-logo.svg
    rsvg-convert -w 256 -h 256 -o "$pixmaps_dir/system-logo-white.png" logos/distributor-logo.svg
    rsvg-convert -w 128 -h 32 -o "$plymouth_dir/watermark.png" logos/aurora-banner.svg
    cp "$plymouth_dir/watermark.png" "$plymouth_dir/kinoite-watermark.png"

    gzip -c logos/distributor-logo.svg >"$splash_dir/aurora_logo.svgz"
    install -Dm0644 busywidget.svgz "$splash_dir/busywidget.svgz"
    install -Dm0644 kde.svgz "$splash_dir/kde.svgz"
    cp -r "$splash_dir/." "$splash_light_dir/"
  - "%{install-extra}"
