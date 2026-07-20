kind: cmake
description: kdeconnect - KDE Connect device integration

build-depends:
- freedesktop-sdk.bst:components/wayland-protocols.bst
- freedesktop-sdk.bst:components/libxkbcommon.bst
- freedesktop-sdk.bst:components/libxslt.bst
- freedesktop-sdk.bst:components/xorg-lib-x11.bst
- freedesktop-sdk.bst:components/xorg-lib-xcb.bst
- freedesktop-sdk.bst:components/xorg-lib-xtst.bst
- freedesktop-sdk.bst:components/libei.bst
- freedesktop-sdk.bst:components/libevdev.bst
- core-deps/libfakekey.bst
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/frameworks/kpackage.bst
- kde/frameworks/karchive.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtconnectivity.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/libs/kirigami-addons.bst
- kde/frameworks/kirigami.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kconfigwidgets.bst
- kde/frameworks/kcmutils.bst
- kde/frameworks/kitemmodels.bst
- kde/frameworks/kstatusnotifieritem.bst
- kde/frameworks/kglobalaccel.bst
- kde/frameworks/breeze-icons.bst
- kde/frameworks/kio.bst
- kde/frameworks/kxmlgui.bst
- kde/frameworks/kdbusaddons.bst
- kde/frameworks/knotifications.bst
- kde/frameworks/qqc2-desktop-style.bst
- freedesktop-sdk.bst:components/dbus.bst
- kde/qt6/qt6-qtmultimedia.bst

variables:
  cmake-local: >-
    -DBUILD_TESTING=OFF
    -DCMAKE_DISABLE_FIND_PACKAGE_KF6DocTools=ON
    -DKF_SKIP_PO_PROCESSING=ON
    -DWITH_PULSEAUDIO=OFF


sources:
- kind: git_repo
  url: kde:network/kdeconnect-kde.git
  track: master
  ref: v24.01.90-1188-gb1562d54001aeb6a0aed4da92dc761aed6320232
- kind: patch
  path: patches/kdeconnect/0001-make-kpeople-optional.patch
- kind: patch
  path: patches/kdeconnect/0002-gate-smsapp-on-kpeople.patch
- kind: patch
  path: patches/kdeconnect/0003-fix-pkgconfig-xkbcommon.patch

