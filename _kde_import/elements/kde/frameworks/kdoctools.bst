kind: cmake
description: kdoctools

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qttools.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/frameworks/karchive.bst
- kde/frameworks/ki18n.bst
- freedesktop-sdk.bst:components/docbook-xml.bst
- freedesktop-sdk.bst:components/docbook-xsl.bst
- freedesktop-sdk.bst:components/libxslt.bst
- freedesktop-sdk.bst:components/perl.bst
- kde/libs/perl-uri.bst

variables:
  cmake-local: >-
    -DBUILD_TESTING=OFF
    -DBUILD_PYTHON_BINDINGS=OFF
    -DDocBookXML4_DTD_DIR=/usr/share/xml/docbook/xml-dtd/4.5
    -DDocBookXSL_DIR=/usr/share/xml/docbook/xml/xsl-stylesheets

sources:
- kind: git_repo
  url: kde:frameworks/kdoctools.git
  track: master
  ref: v6.25.0-rc1-1-g1015e3d4ba22bde5f5a580d1aa1cf14f8da7335e
