kind: cmake
description: plasma-nm

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- core-deps/NetworkManager.bst
- kde/plasma/libplasma.bst

- kde/frameworks/kirigami.bst
- kde/libs/qtkeychain-qt6.bst
- kde/libs/qcoro.bst
- kde/frameworks/prison.bst
- kde/frameworks/kquickcharts.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/frameworks/kcolorscheme.bst
- kde/frameworks/kcompletion.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kdbusaddons.bst
- kde/frameworks/kio.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kjobwidgets.bst
- kde/frameworks/networkmanager-qt.bst
- kde/frameworks/knotifications.bst
- kde/frameworks/kservice.bst
- kde/frameworks/solid.bst
- kde/frameworks/kwallet.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/kwindowsystem.bst
- kde/frameworks/kcmutils.bst
- kde/frameworks/kconfigwidgets.bst
- kde/frameworks/ksvg.bst
- kde/frameworks/modemmanager-qt.bst
- kde/frameworks/kpackage.bst
- kde/frameworks/kcodecs.bst
- kde/frameworks/kdeclarative.bst
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
  url: kde:plasma/plasma-nm.git
  track: master
  ref: v6.5.90-157-g0389ce3601bf34c2d72e32c462128c7a4c857029
