kind: cmake
description: kate - Advanced text editor

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/frameworks/kdoctools.bst
- kde/frameworks/kuserfeedback.bst
- kde/libs/qtkeychain-qt6.bst
- kde/qt6/qt6-qtbase.bst
- freedesktop-sdk.bst:components/gpgmepp.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kguiaddons.bst
- kde/frameworks/kcrash.bst
- kde/frameworks/kiconthemes.bst
- kde/frameworks/ktexteditor.bst
- kde/frameworks/kparts.bst
- kde/frameworks/kio.bst
- kde/frameworks/kxmlgui.bst
- kde/frameworks/kconfigwidgets.bst
- kde/frameworks/kcodecs.bst
- kde/frameworks/karchive.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/sonnet.bst
- kde/frameworks/syntax-highlighting.bst
- kde/frameworks/kcolorscheme.bst
- kde/frameworks/kauth.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kglobalaccel.bst
- kde/frameworks/breeze-icons.bst
- kde/frameworks/knotifications.bst
- kde/frameworks/kjobwidgets.bst
- kde/frameworks/kservice.bst
- kde/frameworks/kbookmarks.bst
- kde/frameworks/kcompletion.bst
- kde/frameworks/kwindowsystem.bst
- kde/frameworks/kdbusaddons.bst
- kde/frameworks/solid.bst
- kde/frameworks/kitemviews.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtmultimedia.bst
- kde/qt6/qt6-qtspeech.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

variables:
  cmake-local: >-
    -DBUILD_TESTING=OFF
    -DBUILD_HTML_DOCS=OFF
    -DBUILD_MAN_DOCS=OFF
    -DBUILD_QTHELP_DOCS=OFF
    -DBUILD_DOC=OFF
    -DCMAKE_DISABLE_FIND_PACKAGE_KF6DocTools=ON
    -DKF_SKIP_PO_PROCESSING=ON

sources:
- kind: git_repo
  url: kde:utilities/kate.git
  track: master
  ref: v24.01.90-2477-g159fa1588f6d9045af2acb3ba8a7f47091736902
