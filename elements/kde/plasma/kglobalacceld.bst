kind: cmake
description: kglobalacceld

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kcrash.bst
- kde/frameworks/kdbusaddons.bst
- kde/frameworks/kwindowsystem.bst
- kde/frameworks/kglobalaccel.bst
- kde/frameworks/kservice.bst
- kde/frameworks/kio.bst
- kde/frameworks/kjobwidgets.bst
- kde/frameworks/kbookmarks.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/kcodecs.bst
- kde/frameworks/kcompletion.bst
- kde/frameworks/kitemviews.bst
- kde/frameworks/kiconthemes.bst
- kde/frameworks/kauth.bst
- kde/frameworks/solid.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kguiaddons.bst
- kde/frameworks/kcolorscheme.bst
- kde/frameworks/breeze-icons.bst
- kde/frameworks/karchive.bst
- kde/frameworks/knotifications.bst
- kde/libs/libcanberra.bst
- freedesktop-sdk.bst:components/systemd-libs.bst
- freedesktop-sdk.bst:components/util-linux.bst

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
  url: kde:plasma/kglobalacceld.git
  track: master
  ref: v6.5.90-11-gbbea7ba8ece7dba3a58f7b4d117e6e80cef0f58f
