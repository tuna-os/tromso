kind: cmake
description: gwenview - KDE image viewer

build-depends:
- freedesktop-sdk.bst:components/wayland-protocols.bst
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtsvg.bst
- kde/qt6/qt6-qtmultimedia.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/frameworks/baloo.bst
- kde/frameworks/karchive.bst
- kde/frameworks/kcolorscheme.bst
- kde/frameworks/kcompletion.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kconfigwidgets.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kcrash.bst
- kde/frameworks/kfilemetadata.bst
- kde/frameworks/kguiaddons.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kiconthemes.bst
- kde/frameworks/kio.bst
- kde/frameworks/kitemmodels.bst
- kde/frameworks/kitemviews.bst
- kde/frameworks/kjobwidgets.bst
- kde/frameworks/kparts.bst
- kde/frameworks/kservice.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/kxmlgui.bst
- kde/frameworks/knotifications.bst
- kde/frameworks/kcodecs.bst
- kde/frameworks/kbookmarks.bst
- kde/frameworks/kauth.bst
- kde/frameworks/solid.bst
- kde/frameworks/breeze-icons.bst
- kde/frameworks/kglobalaccel.bst
- kde/plasma/plasma-activities.bst
- kde/libs/phonon.bst
- kde/frameworks/kdoctools.bst
- freedesktop-sdk.bst:components/docbook-xml.bst
- freedesktop-sdk.bst:components/docbook-xsl.bst
- freedesktop-sdk.bst:components/libxslt.bst
- kde/frameworks/purpose.bst
- freedesktop-sdk.bst:components/jpeg.bst
- freedesktop-sdk.bst:components/libpng.bst
- freedesktop-sdk.bst:components/libtiff.bst
- core-deps/exiv2.bst
- freedesktop-sdk.bst:components/lcms.bst

variables:
  cmake-local: >-
    -DBUILD_TESTING=OFF
    -DKF_SKIP_PO_PROCESSING=ON
    -DGWENVIEW_SEMANTICINFO_BACKEND=None
    -DGWENVIEW_IMAGEANNOTATOR=OFF

sources:
- kind: git_repo
  url: kde:graphics/gwenview.git
  track: master
  ref: v24.01.90-503-g20d85fff7a19fcb4f3abb7a9daa7d06a1416fb48
- kind: patch
  path: patches/gwenview/0002-use-libjpeg62-with-turbo.patch
