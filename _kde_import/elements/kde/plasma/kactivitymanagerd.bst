kind: cmake
description: kactivitymanagerd

build-depends:
- kde/libs/boost.bst
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/frameworks/kdbusaddons.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kcrash.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kio.bst
- kde/frameworks/kglobalaccel.bst
- kde/frameworks/kconfigwidgets.bst
- kde/frameworks/kxmlgui.bst
- kde/frameworks/kcodecs.bst

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
  url: kde:plasma/kactivitymanagerd.git
  track: master
  ref: v6.5.90-17-gfc393cd3816e032bf8cf4806eac7ea4cf41463bd
