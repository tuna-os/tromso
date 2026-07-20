kind: cmake
description: plasma-systemmonitor - KDE system monitor

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst

- kde/frameworks/kirigami.bst
- kde/libs/kirigami-addons.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kcrash.bst
- kde/frameworks/kservice.bst
- kde/frameworks/kglobalaccel.bst
- kde/frameworks/kio.bst
- kde/frameworks/kdbusaddons.bst
- kde/frameworks/knewstuff.bst
- kde/frameworks/kitemmodels.bst
- kde/frameworks/kwindowsystem.bst
- kde/frameworks/kpackage.bst
- kde/frameworks/kiconthemes.bst
- kde/frameworks/kquickcharts.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kdeclarative.bst
- kde/plasma/libksysguard.bst

variables:
  cmake-local: >-
    -DBUILD_TESTING=OFF
    -DKF_SKIP_PO_PROCESSING=ON

sources:
- kind: git_repo
  url: kde:plasma/plasma-systemmonitor.git
  track: master
  ref: v6.5.90-66-g308eba64d627c14001c9087dcbe0ef65e82d6e43
