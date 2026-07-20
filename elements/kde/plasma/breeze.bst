kind: cmake
description: breeze

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/frameworks/kirigami.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kcolorscheme.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kguiaddons.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kiconthemes.bst
- kde/frameworks/kwindowsystem.bst
- kde/frameworks/kcmutils.bst
- kde/frameworks/kconfigwidgets.bst
- kde/frameworks/kcodecs.bst
- kde/frameworks/karchive.bst
- kde/frameworks/breeze-icons.bst
- kde/frameworks/kglobalaccel.bst
- kde/frameworks/kitemviews.bst
- kde/frameworks/kpackage.bst
- kde/frameworks/kxmlgui.bst
- kde/plasma/kwayland.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/plasma/kdecoration.bst
- kde/qt6/qt6-qt5compat.bst
- kde/qt6/qt6-qtsvg.bst
- kde/frameworks/frameworkintegration.bst
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
    -DCMAKE_EXE_LINKER_FLAGS="-Wl,--copy-dt-needed-entries"

sources:
- kind: git_repo
  url: kde:plasma/breeze.git
  track: master
  ref: v6.5.90-76-g57866958833d18a3f252a3321db1444dd44bfa06
