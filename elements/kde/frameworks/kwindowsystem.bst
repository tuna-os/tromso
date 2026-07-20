kind: cmake
description: kwindowsystem

depends:
- freedesktop-sdk.bst:components/xorg-lib-x11.bst
- freedesktop-sdk.bst:components/xorg-lib-xcb.bst
- freedesktop-sdk.bst:components/xorg-lib-xfixes.bst
- freedesktop-sdk.bst:components/xcb-util.bst
- freedesktop-sdk.bst:components/xcb-util-cursor.bst
- freedesktop-sdk.bst:components/xcb-util-keysyms.bst
- freedesktop-sdk.bst:components/xcb-util-wm.bst

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qttools.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- freedesktop-sdk.bst:components/wayland-protocols.bst
- kde/frameworks/plasma-wayland-protocols.bst
- kde/qt6/qt6-qtwayland.bst
- freedesktop-sdk.bst:components/libxkbcommon.bst

variables:
  cmake-local: -DBUILD_TESTING=OFF -DBUILD_PYTHON_BINDINGS=OFF -DKWINDOWSYSTEM_X11=ON
  strip-binaries: ''

sources:
- kind: git_repo
  url: kde:frameworks/kwindowsystem.git
  track: master
  ref: v6.25.0-rc1-2-g7eb2bb0bb9135c1857115701f19d86e2e6c368c6
