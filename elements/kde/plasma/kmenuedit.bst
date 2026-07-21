kind: cmake
description: kmenuedit - KDE menu editor

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- freedesktop-sdk.bst:components/libxslt.bst
- freedesktop-sdk.bst:components/docbook-xml.bst
- freedesktop-sdk.bst:components/docbook-xsl.bst
- kde/frameworks/karchive.bst
- kde/frameworks/kdoctools.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kxmlgui.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kconfigwidgets.bst
- kde/frameworks/kcodecs.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kdbusaddons.bst
- kde/frameworks/kcompletion.bst
- kde/frameworks/kiconthemes.bst
- kde/frameworks/breeze-icons.bst
- kde/frameworks/kio.bst
- kde/frameworks/kservice.bst
- kde/frameworks/kitemviews.bst
- kde/frameworks/kjobwidgets.bst
- kde/frameworks/sonnet.bst
- kde/frameworks/kglobalaccel.bst
- kde/frameworks/knotifications.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/kwindowsystem.bst
- kde/frameworks/kcrash.bst

variables:
  cmake-local: >-
    -DBUILD_TESTING=OFF
    -DKF_SKIP_PO_PROCESSING=ON

sources:
- kind: git_repo
  url: kde:plasma/kmenuedit.git
  track: master
  ref: v6.5.90-31-g52c3eb0c0f8cd613856b9fcf4485e8d718d539ab
