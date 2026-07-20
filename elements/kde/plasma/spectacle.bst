kind: cmake
description: spectacle

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/frameworks/kdoctools.bst
- kde/frameworks/plasma-wayland-protocols.bst
- freedesktop-sdk.bst:components/wayland.bst

- kde/frameworks/kconfig.bst
- kde/frameworks/kconfigwidgets.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kcrash.bst
- kde/frameworks/kdbusaddons.bst
- kde/frameworks/kglobalaccel.bst
- kde/frameworks/kguiaddons.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kio.bst
- kde/frameworks/karchive.bst
- kde/frameworks/kjobwidgets.bst
- kde/frameworks/knotifications.bst
- kde/frameworks/kservice.bst
- kde/frameworks/kstatusnotifieritem.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/kwindowsystem.bst
- kde/frameworks/kxmlgui.bst
- kde/frameworks/breeze-icons.bst
- kde/frameworks/kirigami.bst
- kde/frameworks/prison.bst
- kde/frameworks/purpose.bst
- kde/plasma/kpipewire.bst
- freedesktop-sdk.bst:components/pipewire.bst
- freedesktop-sdk.bst:components/ffmpeg.bst
- freedesktop-sdk.bst:extensions/codecs-extra/ffmpeg.bst
- freedesktop-sdk.bst:components/dummy-gbm.bst
- freedesktop-sdk.bst:components/libdrm.bst
- freedesktop-sdk.bst:components/libva.bst
- kde/plasma/layer-shell-qt.bst
- kde/libs/kquickimageeditor.bst
- kde/qt6/qt6-qtmultimedia.bst
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
    -DSPECTACLE_ENABLE_OCR=OFF

sources:
- kind: git_repo
  url: kde:plasma/spectacle.git
  track: master
  ref: v6.5.90-117-gf85ee4a9ba20a2f23aa67da4b19c56fb6aa36b6a
- kind: patch
  path: patches/spectacle/0001-disable-ocr-without-external-deps.patch
