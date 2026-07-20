kind: cmake
description: powerdevil

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/frameworks/kdoctools.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtsvg.bst
- kde/libs/qcoro.bst
- kde/plasma/plasma-workspace.bst
- kde/frameworks/kxmlgui.bst
- kde/frameworks/kpackage.bst
- kde/frameworks/karchive.bst
- kde/frameworks/ksvg.bst
- kde/frameworks/plasma-wayland-protocols.bst
- freedesktop-sdk.bst:components/wayland.bst
- freedesktop-sdk.bst:components/systemd-libs.bst
- kde/frameworks/kcmutils.bst
- kde/frameworks/kconfigwidgets.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kio.bst
- kde/frameworks/krunner.bst
- kde/frameworks/kwindowsystem.bst
- kde/frameworks/kidletime.bst
- kde/frameworks/kitemmodels.bst
- kde/frameworks/kglobalaccel.bst
- kde/frameworks/kirigami.bst
- kde/frameworks/knotifications.bst
- kde/frameworks/breeze-icons.bst
- kde/plasma/libkscreen.bst
- kde/plasma/libplasma.bst
- kde/plasma/plasma-activities.bst
- kde/frameworks/solid.bst

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
  url: kde:plasma/powerdevil.git
  track: master
  ref: v6.5.90-109-ge5393819c2020d4308974a4781539033eb208623
