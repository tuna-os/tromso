kind: cmake
description: plasma5support

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/frameworks/networkmanager-qt.bst
- kde/plasma/plasma-activities.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kguiaddons.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/knotifications.bst
- kde/frameworks/solid.bst
- kde/frameworks/kservice.bst
- kde/frameworks/kidletime.bst
- kde/frameworks/kio.bst
- kde/frameworks/kunitconversion.bst
- kde/frameworks/kholidays.bst
- kde/plasma/libksysguard.bst

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
    -DCMAKE_DISABLE_FIND_PACKAGE_GPS=ON

sources:
- kind: git_repo
  url: kde:plasma/plasma5support.git
  track: master
  ref: v6.5.90-45-g59daf4e3b85b902e98fe52ae974dcffbc7aced3f
