kind: cmake
description: drkonqi - KDE crash handler

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kservice.bst
- kde/frameworks/kjobwidgets.bst
- kde/frameworks/kio.bst
- kde/frameworks/kcrash.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/kwallet.bst
- kde/frameworks/knotifications.bst
- kde/frameworks/kidletime.bst
- kde/frameworks/kwindowsystem.bst
- kde/frameworks/syntax-highlighting.bst
- kde/frameworks/kstatusnotifieritem.bst
- kde/libs/polkit-qt-1.bst
- kde/frameworks/kirigami.bst
- kde/frameworks/kitemmodels.bst

variables:
  cmake-local: >-
    -DBUILD_TESTING=OFF
    -DKF_SKIP_PO_PROCESSING=ON
    -DWITH_PYTHON_MODULES=OFF

sources:
- kind: git_repo
  url: kde:plasma/drkonqi.git
  track: master
  ref: v6.5.90-32-g4e74051a9a4f91c2bcbc6822d803f96be55086f0
