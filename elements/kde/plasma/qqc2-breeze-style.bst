kind: cmake
description: qqc2-breeze-style

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst

- kde/frameworks/kguiaddons.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kirigami.bst
- kde/frameworks/kcolorscheme.bst
- kde/frameworks/kiconthemes.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
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
  url: kde:plasma/qqc2-breeze-style.git
  track: master
  ref: v6.5.90-7-ge84b2d2c800c26e27f8e784949b95ea8ea01f6ff
