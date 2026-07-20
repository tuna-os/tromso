kind: cmake
description: knighttime

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/frameworks/ki18n.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qttools.bst
- kde/qt6/qt6-qtpositioning.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kdbusaddons.bst
- kde/frameworks/kholidays.bst

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
  url: kde:plasma/knighttime.git
  track: master
  ref: v6.5.90-10-gf28f89a00fd7c4961930a8c35b6e41a1ace5e5ea
