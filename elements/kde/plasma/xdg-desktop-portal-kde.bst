kind: cmake
description: xdg-desktop-portal-kde - KDE XDG portal backend

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- freedesktop-sdk.bst:components/wayland-protocols.bst
- kde/frameworks/plasma-wayland-protocols.bst
- freedesktop-sdk.bst:components/wayland.bst
- kde/plasma/kwayland.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kguiaddons.bst
- kde/frameworks/kglobalaccel.bst
- kde/frameworks/kio.bst
- kde/frameworks/karchive.bst
- kde/frameworks/kirigami.bst
- kde/frameworks/knotifications.bst
- kde/frameworks/kservice.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/kstatusnotifieritem.bst
- kde/frameworks/breeze-icons.bst
- kde/libs/polkit-qt-1.bst
- kde/qt6/qt6-qtdeclarative.bst
- freedesktop-sdk.bst:components/libxkbcommon.bst

variables:
  cmake-local: >-
    -DBUILD_TESTING=OFF
    -DKF_SKIP_PO_PROCESSING=ON

sources:
- kind: git_repo
  url: kde:plasma/xdg-desktop-portal-kde.git
  track: master
  ref: v6.5.90-120-g2cf3559f9ee92287d28891a4f40fecac637e60eb
- kind: patch
  path: patches/xdg-desktop-portal-kde/0001-fallback-when-qt-cups-private-header-is-missing.patch
