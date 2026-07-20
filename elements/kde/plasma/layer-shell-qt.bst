kind: cmake
description: layer-shell-qt

build-depends:
- freedesktop-sdk.bst:components/wayland-protocols.bst
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- freedesktop-sdk.bst:components/wayland.bst
- freedesktop-sdk.bst:components/libxkbcommon.bst

variables:
  cmake-local: >-
    -DBUILD_TESTING=OFF
    -DBUILD_HTML_DOCS=OFF
    -DBUILD_MAN_DOCS=OFF
    -DBUILD_QTHELP_DOCS=OFF
    -DBUILD_DOC=OFF
    -DBUILD_PYTHON_BINDINGS=OFF
    -DKF_SKIP_PO_PROCESSING=ON
    -DBUILD_QT5=OFF
    -DBUILD_WITH_QT6=ON
    -DQT_MAJOR_VERSION=6

sources:
- kind: git_repo
  url: kde:plasma/layer-shell-qt.git
  track: master
  ref: v6.5.90-6-gaac600107ab3959a34178beb7f4425c13006e578
