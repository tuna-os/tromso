kind: meson
description: udev rules for game controllers

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-meson.bst
- freedesktop-sdk.bst:components/systemd.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

config:
  install-commands:
    (>):
    - |
      install -Dm644 /dev/stdin \
        '%{install-root}%{indep-libdir}/modules-load.d/game-devices-udev.conf' <<'EOF'
      uinput
      EOF

sources:
- kind: git_repo
  url: codeberg:fabiscafe/game-devices-udev.git
  ref: 1.1-0-g811ba06ec13810f92cf080be8710ce9dbbc3fcc1
