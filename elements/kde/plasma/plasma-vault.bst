kind: cmake
description: plasma-vault

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kservice.bst
- kde/frameworks/kio.bst
- kde/frameworks/kwindowsystem.bst
- kde/frameworks/kdeclarative.bst
- kde/frameworks/knotifications.bst
- kde/frameworks/kstatusnotifieritem.bst
- kde/frameworks/kitemmodels.bst
- kde/frameworks/kpackage.bst
- kde/frameworks/kirigami.bst
- kde/frameworks/networkmanager-qt.bst
- kde/plasma/libplasma.bst
- kde/plasma/plasma-activities.bst
- kde/plasma/libksysguard.bst
- kde/qt6/qt6-qtdeclarative.bst
- freedesktop-sdk.bst:components/libgcrypt.bst
- freedesktop-sdk.bst:components/libassuan.bst

variables:
  cmake-local: >-
    -DBUILD_TESTING=OFF
    -DBUILD_HTML_DOCS=OFF
    -DBUILD_MAN_DOCS=OFF
    -DBUILD_QTHELP_DOCS=OFF
    -DBUILD_DOC=OFF
    -DKF_SKIP_PO_PROCESSING=ON
    -DBUILD_QT5=OFF
    -DBUILD_WITH_QT6=ON
    -DQT_MAJOR_VERSION=6

sources:
- kind: git_repo
  url: kde:plasma/plasma-vault.git
  track: Plasma/6.6
  ref: 32546c0eb00637477f21ca7510ad5bcedfd70933
