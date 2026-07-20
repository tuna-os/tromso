kind: cmake
description: libplasma

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qtwayland.bst
- kde/qt6/qt6-qtsvg.bst
- kde/qt6/qt6-qt5compat.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- freedesktop-sdk.bst:components/wayland.bst
- freedesktop-sdk.bst:components/wayland-protocols.bst
- freedesktop-sdk.bst:components/xorg-lib-x11.bst
- freedesktop-sdk.bst:components/xorg-lib-xcb.bst
- freedesktop-sdk.bst:components/xcb-util.bst
- kde/frameworks/kdoctools.bst
- kde/frameworks/plasma-wayland-protocols.bst
- kde/plasma/plasma-activities.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kglobalaccel.bst
- kde/frameworks/kguiaddons.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kiconthemes.bst
- kde/frameworks/kio.bst
- kde/frameworks/kwindowsystem.bst
- kde/frameworks/knotifications.bst
- kde/frameworks/kpackage.bst
- kde/frameworks/ksvg.bst
- kde/frameworks/kcolorscheme.bst
- kde/frameworks/kdbusaddons.bst
- kde/frameworks/kbookmarks.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/kcodecs.bst
- kde/frameworks/kservice.bst
- kde/frameworks/solid.bst
- kde/frameworks/kcrash.bst
- kde/frameworks/kcompletion.bst
- kde/frameworks/kitemviews.bst
- kde/frameworks/kjobwidgets.bst
- kde/frameworks/kauth.bst

depends:
- kde/frameworks/kirigami.bst
- kde/frameworks/kcolorscheme.bst
- kde/frameworks/kdbusaddons.bst
- kde/frameworks/kbookmarks.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/kcodecs.bst
- kde/frameworks/kservice.bst
- kde/frameworks/solid.bst
- kde/frameworks/kcrash.bst
- kde/frameworks/kcompletion.bst
- kde/frameworks/kitemviews.bst
- kde/frameworks/kjobwidgets.bst
- kde/frameworks/kauth.bst

variables:
  cmake-local: >-
    -DCMAKE_DISABLE_FIND_PACKAGE_KF6DocTools=ON
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
    -DBUILD_X11=OFF

sources:
- kind: git_repo
  url: kde:plasma/libplasma.git
  track: master
  ref: v6.5.90-89-g4ca334ae667b8268ae39527e026805060dae4399

