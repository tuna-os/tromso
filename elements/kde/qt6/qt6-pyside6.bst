kind: cmake
description: PySide6 — Qt for Python bindings

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- freedesktop-sdk.bst:components/python3.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qttools.bst
- kde/qt6/qt6-shiboken6.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

depends:
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qttools.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/qt6/qt6-shiboken6.bst

config:
  configure-commands:
  - cmake -B%{build-dir} -H"%{conf-root}/sources/pyside6" -G"%{generator}" %{cmake-args}

variables:
  cmake-local: >-
    -DBUILD_SHARED_LIBS=ON

sources:
- kind: tar
  url: tar_https:download.qt.io/official_releases/QtForPython/pyside6/PySide6-6.10.3-src/pyside-setup-everywhere-src-6.10.3.tar.xz
  ref: 2c7462fe0cecb5b8ac0a3d92014b8d0b88bd4d9f8646709dab5286d9416f45bc
