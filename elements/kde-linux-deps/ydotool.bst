kind: cmake
description: Command-line automation tool for Wayland (xdotool replacement)

sources:
- kind: tar
  url: github:ReimuNotMoe/ydotool/archive/refs/tags/v1.0.4.tar.gz
  ref: ba075a43aa6ead51940e892ecffa4d0b8b40c241e4e2bc4bd9bd26b61fde23bd

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- freedesktop-sdk.bst:components/scdoc.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/systemd.bst

variables:
  cmake-local: >-
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5
