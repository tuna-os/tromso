kind: cmake

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/frameworks/syntax-highlighting.bst

depends:
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/frameworks/syntax-highlighting.bst

variables:
  cmake-local: >-
    -DQT_VERSION_MAJOR=6
    -DBUILD_TESTING=OFF
    -DGAMMARAY_INSTALL_QT_LAYOUT=ON

sources:
- kind: tar
  url: github:KDAB/GammaRay/releases/download/v3.4.0/gammaray-3.4.0.tar.gz
  ref: bcac8aa24671bcfd563213f5cfd9e61cf555b22ee3896e8111a5c3a588aacadf
