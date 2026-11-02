kind: manual
description: >-
  Original Tromso identity artwork by TunaOS: icon, wordmark, and wallpaper
  asset. It is separate from KDE and Aurora artwork.

sources:
- kind: local
  path: branding/tromso

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

config:
  install-commands:
  - install -Dm644 tromso-logo.svg '%{install-root}%{datadir}/icons/hicolor/scalable/apps/tromso-logo.svg'
  - install -Dm644 tromso-wordmark.svg '%{install-root}%{datadir}/tunaos/branding/tromso-wordmark.svg'
  - install -Dm644 tromso-wallpaper.svg '%{install-root}%{datadir}/tunaos/branding/tromso-wallpaper.svg'
  - install -Dm644 tromso-wallpaper.png '%{install-root}%{datadir}/backgrounds/TunaOS/Tromso/tromso-wallpaper.png'
  - install -Dm644 tromso-wallpaper.png '%{install-root}%{datadir}/wallpapers/Tromso/contents/images/1920x1080.png'
  - |
    install -Dm644 /dev/stdin '%{install-root}%{datadir}/wallpapers/Tromso/metadata.json' <<'EOF'
    {"KPlugin":{"Id":"Tromso","Name":"TunaOS Tromsø","License":"Apache-2.0"}}
    EOF
  - |
    install -Dm644 /dev/stdin '%{install-root}%{datadir}/plasma/look-and-feel/org.tunaos.tromso.desktop/metadata.json' <<'EOF'
    {"KPackageStructure":"Plasma/LookAndFeel","KPlugin":{"Id":"org.tunaos.tromso.desktop","Name":"TunaOS Tromsø","License":"Apache-2.0"}}
    EOF
  - |
    install -Dm644 /dev/stdin '%{install-root}%{datadir}/plasma/look-and-feel/org.tunaos.tromso.desktop/contents/defaults' <<'EOF'
    [kdeglobals][KDE]
    widgetStyle=Breeze
    [kdeglobals][General]
    ColorScheme=BreezeLight
    [kdeglobals][Icons]
    Theme=breeze
    [plasmarc][Theme]
    name=default
    [Wallpaper]
    Image=Tromso
    [kcminputrc][Mouse]
    cursorTheme=breeze_cursors
    [kwinrc][org.kde.kdecoration2]
    library=org.kde.breeze
    theme=Breeze
    [ksplashrc][KSplash]
    Theme=org.kde.breeze.desktop
    EOF
  - '%{install-extra}'

variables:
  strip-binaries: ''
