kind: cmake
description: bluedevil - KDE Bluetooth stack

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/frameworks/kdoctools.bst
- kde/plasma/libplasma.bst

- kde/frameworks/kirigami.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/frameworks/bluez-qt.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kdbusaddons.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kjobwidgets.bst
- kde/frameworks/kcmutils.bst
- kde/frameworks/kconfigwidgets.bst
- kde/frameworks/karchive.bst
- kde/frameworks/kio.bst
- kde/frameworks/knotifications.bst
- kde/frameworks/kservice.bst
- kde/frameworks/breeze-icons.bst
- kde/frameworks/ksvg.bst
- kde/frameworks/kpackage.bst
- freedesktop-sdk.bst:components/shared-mime-info.bst
- kde/frameworks/kcodecs.bst
variables:
  cmake-local: >-
    -DCMAKE_DISABLE_FIND_PACKAGE_KF6DocTools=ON
    -DBUILD_TESTING=OFF
    -DKF_SKIP_PO_PROCESSING=ON

sources:
- kind: git_repo
  url: kde:plasma/bluedevil.git
  track: master
  ref: v6.5.90-50-g555123b0b320f013e35c82207d16cf6567ea1f5c

