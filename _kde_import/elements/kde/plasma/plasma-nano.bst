kind: cmake
description: plasma-nano

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst

- kde/frameworks/kwindowsystem.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kservice.bst
- kde/frameworks/kitemmodels.bst
- kde/qt6/qt6-qtsvg.bst
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
  url: kde:plasma/plasma-nano.git
  track: master
  ref: v6.5.90-18-gce48a4a8da0ba3ea5f455418bcda44c7e57e217e
