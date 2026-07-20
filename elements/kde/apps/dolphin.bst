kind: cmake
description: dolphin - KDE file manager

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/frameworks/kdoctools.bst
- freedesktop-sdk.bst:components/docbook-xml.bst
- freedesktop-sdk.bst:components/docbook-xsl.bst
- freedesktop-sdk.bst:components/libxslt.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/libs/phonon.bst
- kde/frameworks/baloo.bst
- kde/frameworks/kbookmarks.bst
- kde/frameworks/kcmutils.bst
- kde/frameworks/kcodecs.bst
- kde/frameworks/kcolorscheme.bst
- kde/frameworks/kcompletion.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kconfigwidgets.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kcrash.bst
- kde/frameworks/kdbusaddons.bst
- kde/frameworks/kfilemetadata.bst
- kde/frameworks/kguiaddons.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kiconthemes.bst
- kde/frameworks/kio.bst
- kde/frameworks/kjobwidgets.bst
- kde/frameworks/knewstuff.bst
- kde/frameworks/knotifications.bst
- kde/frameworks/kparts.bst
- kde/frameworks/kservice.bst
- kde/frameworks/ktextwidgets.bst
- kde/frameworks/kuserfeedback.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/kwindowsystem.bst
- kde/frameworks/kxmlgui.bst
- kde/frameworks/solid.bst
- kde/frameworks/kauth.bst
- kde/frameworks/kglobalaccel.bst
- kde/frameworks/breeze-icons.bst
- kde/frameworks/karchive.bst
- kde/frameworks/kitemviews.bst
- kde/frameworks/kitemmodels.bst
- kde/frameworks/sonnet.bst
- kde/qt6/qt6-qtspeech.bst
- kde/qt6/qt6-qtmultimedia.bst
- kde/frameworks/kpackage.bst

variables:
  cmake-local: >-
    -DBUILD_TESTING=OFF
    -DKF_SKIP_PO_PROCESSING=ON

sources:
- kind: git_repo
  url: kde:system/dolphin.git
  track: master
  ref: v24.01.90-1320-g6cbee2ac13d4b414c94c33325e18487683a44b57

