kind: cmake
description: kcalc - KDE calculator

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/frameworks/kdoctools.bst
- kde/qt6/qt6-qtbase.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kcrash.bst
- kde/frameworks/kcolorscheme.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kconfigwidgets.bst
- kde/frameworks/kguiaddons.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/knotifications.bst
- kde/frameworks/kxmlgui.bst
- kde/frameworks/kiconthemes.bst
- kde/frameworks/kcodecs.bst
- kde/frameworks/karchive.bst
- kde/frameworks/breeze-icons.bst
- kde/frameworks/kglobalaccel.bst
- kde/frameworks/kitemviews.bst
- kde/frameworks/kcompletion.bst
- kde/frameworks/kwidgetsaddons.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- freedesktop-sdk.bst:components/gmp.bst
- freedesktop-sdk.bst:components/mpfr.bst
- core-deps/mpc.bst

variables:
  cmake-local: >-
    -DBUILD_TESTING=OFF
    -DCMAKE_DISABLE_FIND_PACKAGE_KF6DocTools=ON
    -DKF_SKIP_PO_PROCESSING=ON
    -DCMAKE_EXE_LINKER_FLAGS="-Wl,--copy-dt-needed-entries"

sources:
- kind: git_repo
  url: kde:utilities/kcalc.git
  track: master
  ref: v24.01.90-426-gf181bf6d85335b4457adca2829cc5aa263918049
