kind: cmake
description: okular - KDE document viewer

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtsvg.bst
- kde/qt6/qt6-qtspeech.bst
- kde/qt6/qt6-qtmultimedia.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- freedesktop-sdk.bst:components/python3.bst
- freedesktop-sdk.bst:components/libtiff.bst
- kde/libs/poppler-qt6.bst
- kde/libs/phonon.bst
- kde/frameworks/karchive.bst
- kde/frameworks/kbookmarks.bst
- kde/frameworks/kcolorscheme.bst
- kde/frameworks/kcompletion.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kconfigwidgets.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kcrash.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kiconthemes.bst
- kde/frameworks/kio.bst
- kde/frameworks/kparts.bst
- kde/frameworks/ktextwidgets.bst
- kde/frameworks/kwallet.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/kwindowsystem.bst
- kde/frameworks/kxmlgui.bst
- kde/frameworks/purpose.bst
- kde/frameworks/kservice.bst
- kde/frameworks/kguiaddons.bst
- kde/frameworks/solid.bst
- kde/frameworks/kauth.bst
- kde/frameworks/kjobwidgets.bst
- kde/frameworks/kdbusaddons.bst
- kde/frameworks/kcodecs.bst
- kde/frameworks/kglobalaccel.bst
- kde/frameworks/kpty.bst
- kde/frameworks/breeze-icons.bst
- kde/frameworks/threadweaver.bst
- kde/frameworks/sonnet.bst
- kde/plasma/plasma-activities.bst

variables:
  cmake-local: >-
    -DBUILD_TESTING=OFF
    -DKF_SKIP_PO_PROCESSING=ON
    -DOKULAR_UI=desktop
    -DBUILD_HTML_DOCS=OFF
    -DBUILD_MAN_DOCS=OFF
    -DBUILD_DOC=OFF
    -DCMAKE_DISABLE_FIND_PACKAGE_KF6DocTools=ON
    -DFORCE_NOT_REQUIRED_DEPENDENCIES=Freetype\;LibSpectre\;KExiv2Qt6\;DjVuLibre\;EPub\;QMobipocket6\;Discount

sources:
- kind: git_repo
  url: kde:graphics/okular.git
  track: master
  ref: v24.20.85-969-g4d742ae2c648bc07a0587f622d6e68716384888c
- kind: patch
  path: patches/okular/0002-dvi-qstringliteral.patch
