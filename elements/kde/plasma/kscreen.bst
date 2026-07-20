kind: cmake
description: kscreen - KDE screen management

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- freedesktop-sdk.bst:components/wayland-protocols.bst
- freedesktop-sdk.bst:components/wayland.bst
- kde/plasma/layer-shell-qt.bst
- kde/plasma/libkscreen.bst
- kde/plasma/libplasma.bst

- kde/frameworks/kimageformats.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kdbusaddons.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kcmutils.bst
- kde/frameworks/kconfigwidgets.bst
- kde/frameworks/ksvg.bst
- kde/frameworks/kxmlgui.bst
- kde/frameworks/kguiaddons.bst
- kde/frameworks/kpackage.bst
- kde/frameworks/kcodecs.bst
- kde/frameworks/kcrash.bst
- kde/frameworks/kirigami.bst
- kde/frameworks/kitemmodels.bst
- kde/frameworks/kwindowsystem.bst
- kde/frameworks/kglobalaccel.bst
- kde/frameworks/karchive.bst
- kde/frameworks/knotifications.bst
- kde/frameworks/breeze-icons.bst
- kde/plasma/plasma-activities.bst
- kde/plasma/plasma5support.bst
- kde/qt6/qt6-qtsvg.bst
- freedesktop-sdk.bst:components/xorg-lib-x11.bst
- freedesktop-sdk.bst:components/xorg-lib-xcb.bst
- freedesktop-sdk.bst:components/xorg-lib-xi.bst
variables:
  cmake-local: >-
    -DBUILD_TESTING=OFF
    -DKF_SKIP_PO_PROCESSING=ON

sources:
- kind: git_repo
  url: kde:plasma/kscreen.git
  track: master
  ref: v6.5.90-65-gf1ea5ff40d1156962b7ef0a021894905d0c1d92b
