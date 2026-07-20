kind: cmake
description: elisa - KDE music player

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtmultimedia.bst
- kde/qt6/qt6-qtsvg.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- freedesktop-sdk.bst:components/python3.bst
- kde/frameworks/kcodecs.bst
- kde/frameworks/kcolorscheme.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kcrash.bst
- kde/frameworks/kdbusaddons.bst
- kde/frameworks/kfilemetadata.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kiconthemes.bst
- kde/frameworks/kio.bst
- kde/frameworks/kirigami.bst
- kde/libs/kirigami-addons.bst
- kde/frameworks/kitemviews.bst
- kde/frameworks/kxmlgui.bst
- kde/frameworks/qqc2-desktop-style.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/kservice.bst
- kde/frameworks/kcompletion.bst
- kde/frameworks/kconfigwidgets.bst
- kde/frameworks/kglobalaccel.bst
- kde/frameworks/kguiaddons.bst
- kde/frameworks/solid.bst
- kde/frameworks/breeze-icons.bst
- kde/frameworks/kauth.bst
- kde/frameworks/kjobwidgets.bst
- kde/frameworks/kbookmarks.bst
- kde/frameworks/knotifications.bst
- kde/frameworks/kwindowsystem.bst
- kde/frameworks/karchive.bst
- kde/frameworks/kitemmodels.bst

variables:
  cmake-local: >-
    -DBUILD_TESTING=OFF
    -DKF_SKIP_PO_PROCESSING=ON

sources:
- kind: git_repo
  url: kde:multimedia/elisa.git
  track: master
  ref: v24.01.90-876-ga3bf013cfee86b493ce4ac282e60b73808276db1
