kind: cmake
description: kscreenlocker

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/frameworks/kcmutils.bst
- kde/frameworks/kconfigwidgets.bst
- kde/frameworks/kpackage.bst
- kde/frameworks/kdoctools.bst
- freedesktop-sdk.bst:components/wayland.bst
- freedesktop-sdk.bst:components/xorg-lib-x11.bst
- freedesktop-sdk.bst:components/xorg-lib-xcb.bst
- freedesktop-sdk.bst:components/linux-pam-base.bst
- kde/plasma/layer-shell-qt.bst
- kde/plasma/libkscreen.bst
- kde/frameworks/plasma-wayland-protocols.bst
- kde/plasma/libplasma.bst
- kde/frameworks/kirigami.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- freedesktop-sdk.bst:components/xcb-util-keysyms.bst
- kde/frameworks/kcrash.bst
- kde/frameworks/kio.bst
- kde/frameworks/kglobalaccel.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kidletime.bst
- kde/frameworks/knotifications.bst
- kde/frameworks/solid.bst
- kde/frameworks/kwindowsystem.bst
- kde/frameworks/kxmlgui.bst
- kde/frameworks/ksvg.bst
- kde/qt6/qt6-qtsvg.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtwayland.bst
- kde/frameworks/karchive.bst
- kde/plasma/plasma-activities.bst
- kde/frameworks/breeze-icons.bst
- freedesktop-sdk.bst:components/docbook-xml.bst
- freedesktop-sdk.bst:components/docbook-xsl.bst
- freedesktop-sdk.bst:components/libxslt.bst

variables:
  cmake-local: >-
    -DBUILD_TESTING=OFF
    -DBUILD_PYTHON_BINDINGS=OFF
    -DKF_SKIP_PO_PROCESSING=ON
    -DBUILD_QT5=OFF
    -DBUILD_WITH_QT6=ON
    -DQT_MAJOR_VERSION=6
    -DBUILD_X11=OFF
    -DKSCREENLOCKER_BUILD_X11=OFF

sources:
- kind: git_repo
  url: kde:plasma/kscreenlocker.git
  track: master
  ref: v6.5.90-41-ga3a8185a00aadf22f5707de5a41ae17ce5fa9b87
