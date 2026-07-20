kind: cmake
description: aurorae

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst

- kde/plasma/kdecoration.bst
- kde/frameworks/ksvg.bst
- kde/frameworks/kcolorscheme.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kcmutils.bst
- kde/frameworks/kconfigwidgets.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/kcodecs.bst
- kde/frameworks/kguiaddons.bst
- kde/frameworks/knewstuff.bst
- kde/frameworks/kpackage.bst
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
  url: kde:plasma/aurorae.git
  track: master
  ref: v6.5.90-28-g2bc65fbbca1c299ca2cec5f98d3f662076b80af8
