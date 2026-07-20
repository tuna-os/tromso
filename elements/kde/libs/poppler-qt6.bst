kind: cmake
description: poppler Qt6 bindings

build-depends:
- freedesktop-sdk.bst:components/fontconfig.bst
- freedesktop-sdk.bst:components/icu.bst
- freedesktop-sdk.bst:components/lcms.bst
- freedesktop-sdk.bst:components/jpeg.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- freedesktop-sdk.bst:components/poppler.bst
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/qt6/qt6-qtbase.bst

variables:
  cmake-local: >-
    -DBUILD_TESTING=OFF
    -DENABLE_QT5=OFF
    -DENABLE_QT6=ON
    -DENABLE_GLIB=OFF
    -DENABLE_CPP=OFF
    -DENABLE_UTILS=OFF
    -DENABLE_BOOST=OFF

config:
  install-commands:
    (>):
    - |
      # Remove base libpoppler files that conflict with FDO's poppler.bst
      # Only keep Qt6-specific bindings
      find "%{install-root}" -name "libpoppler.so*" -not -name "libpoppler-qt6*" -delete
      find "%{install-root}" -name "libpoppler.so*debug*" -not -name "libpoppler-qt6*" -delete
      rm -f "%{install-root}%{libdir}/pkgconfig/poppler.pc"
      rm -f "%{install-root}%{libdir}/pkgconfig/poppler-glib.pc"
      rm -rf "%{install-root}%{includedir}/poppler/glib"

depends:
- kde/qt6/qt6-qtbase.bst
- freedesktop-sdk.bst:components/poppler.bst

sources:
- kind: git_repo
  url: freedesktop:poppler/poppler.git
  track: master
  ref: e3d56a0e4b4a243ac9f4ab100325c95386f87521
