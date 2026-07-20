kind: cmake
description: milou

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/frameworks/kdoctools.bst
- kde/plasma/libplasma.bst

- kde/frameworks/ki18n.bst
- kde/frameworks/krunner.bst
- kde/frameworks/ksvg.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kservice.bst
- kde/frameworks/kio.bst
- kde/frameworks/kitemmodels.bst
- kde/frameworks/kbookmarks.bst
- kde/frameworks/kcolorscheme.bst
- kde/frameworks/kcompletion.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/kdbusaddons.bst
- kde/frameworks/kjobwidgets.bst
- kde/frameworks/kauth.bst
- kde/frameworks/kcodecs.bst
- kde/frameworks/kpackage.bst
- kde/frameworks/solid.bst
- kde/frameworks/kcrash.bst
- kde/frameworks/kwindowsystem.bst
- kde/frameworks/kiconthemes.bst
- kde/frameworks/kguiaddons.bst
- kde/frameworks/kitemviews.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
variables:
  cmake-local: >-
    -DCMAKE_DISABLE_FIND_PACKAGE_KF6DocTools=ON
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
  url: kde:plasma/milou.git
  track: master
  ref: v6.5.90-19-gabdfef7f0e42d738e6839f5a8df07436fd15bbf7
