kind: cmake
description: libksysguard

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qttools.bst
- freedesktop-sdk.bst:components/libdrm.bst
- freedesktop-sdk.bst:components/libnl.bst
- kde/libs/lm-sensors.bst

- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kauth.bst
- kde/frameworks/kservice.bst
- kde/frameworks/kpackage.bst
- kde/frameworks/knewstuff.bst
- kde/frameworks/attica.bst
- kde/frameworks/solid.bst
variables:
  cmake-local: >-
    -DCMAKE_INSTALL_SBINDIR=bin
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
  url: kde:plasma/libksysguard.git
  track: master
  ref: v6.5.90-51-gd1fa7c1bb214fbc40f623a4af61bb97e6c7268bf
