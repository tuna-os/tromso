kind: cmake
description: systemsettings

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/frameworks/kglobalaccel.bst
- kde/frameworks/karchive.bst
- kde/frameworks/breeze-icons.bst
- kde/qt6/qt6-qtbase.bst
- kde/frameworks/kdoctools.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/frameworks/kauth.bst
- kde/frameworks/kcrash.bst
- kde/frameworks/kitemviews.bst
- kde/frameworks/kitemmodels.bst
- kde/frameworks/kcmutils.bst
- kde/frameworks/kconfigwidgets.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kio.bst
- kde/frameworks/kservice.bst
- kde/frameworks/kiconthemes.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/kwindowsystem.bst
- kde/frameworks/kxmlgui.bst
- kde/frameworks/kdbusaddons.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kguiaddons.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kirigami.bst
- kde/frameworks/krunner.bst
- kde/frameworks/kcodecs.bst
- kde/plasma/plasma-activities.bst
- kde/plasma/plasma-activities-stats.bst

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
  url: kde:plasma/systemsettings.git
  track: master
  ref: v6.5.90-72-g619b5afc32d91974e920f7e4fef6c896e68c2952
