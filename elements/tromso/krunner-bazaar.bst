kind: cmake
description: Aurora KRunner plugin for searching Flatpak apps via Bazaar

build-depends:
- kde-build-meta.bst:freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/gettext.bst
- kde-build-meta.bst:kde/frameworks/extra-cmake-modules.bst
- kde-build-meta.bst:kde/qt6/qt6-qtbase.bst
- kde-build-meta.bst:kde/frameworks/kconfig.bst
- kde-build-meta.bst:kde/frameworks/kcoreaddons.bst
- kde-build-meta.bst:kde/frameworks/ki18n.bst
- kde-build-meta.bst:kde/frameworks/krunner.bst

variables:
  cmake-local: -DBUILD_TESTING=OFF

config:
  configure-commands:
  - |
    LD_LIBRARY_PATH="/usr/lib" \
    cmake -B_builddir -H"." -G"Ninja" \
      -DCMAKE_VERBOSE_MAKEFILE=ON \
      -DCMAKE_INSTALL_PREFIX:PATH="%{prefix}" \
      -DCMAKE_INSTALL_LIBDIR:PATH="%{lib}" \
      %{cmake-local}

sources:
- kind: git_repo
  url: github:bazaar-org/krunner-bazaar.git
  track: v1.3.0
  ref: dbed96fa4c2e709c38432eb63e58289636f01b33
