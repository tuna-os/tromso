kind: cmake
description: konsole

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtmultimedia.bst
- kde/qt6/qt6-qtspeech.bst
- kde/frameworks/kdoctools.bst
- kde/frameworks/kbookmarks.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kconfigwidgets.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kcrash.bst
- kde/frameworks/kguiaddons.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kiconthemes.bst
- kde/frameworks/karchive.bst
- kde/frameworks/breeze-icons.bst
- kde/frameworks/kio.bst
- kde/frameworks/knewstuff.bst
- kde/frameworks/kpackage.bst
- kde/frameworks/knotifications.bst
- kde/frameworks/knotifyconfig.bst
- kde/frameworks/kparts.bst
- kde/frameworks/kservice.bst
- kde/frameworks/ktextwidgets.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/sonnet.bst
- kde/frameworks/kpty.bst
- kde/frameworks/kwindowsystem.bst
- kde/frameworks/kxmlgui.bst
- kde/frameworks/kglobalaccel.bst
- kde/frameworks/kdbusaddons.bst

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
    -DUSE_DBUS=OFF

sources:
- kind: git_repo
  url: kde:kde/konsole.git
  track: master
  ref: v25.04.3-0-gbc359b16a01fc093835e36f21c22f691fea31b32
- kind: patch
  path: patches/konsole/0001-fix-dbus-qlist-double-introspection.patch
- kind: patch
  path: patches/konsole/0002-check-tempfile-open-for-shellcheck.patch
