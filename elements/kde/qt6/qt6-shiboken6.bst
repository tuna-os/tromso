kind: cmake
description: Shiboken6 — CPython binding generator for Qt6

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- freedesktop-sdk.bst:components/llvm.bst
- freedesktop-sdk.bst:components/python3.bst
- kde/qt6/qt6-qtbase.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

depends:
- freedesktop-sdk.bst:components/llvm.bst
- freedesktop-sdk.bst:components/python3.bst
- kde/qt6/qt6-qtbase.bst

config:
  configure-commands:
  - cmake -B%{build-dir} -H"%{conf-root}/sources/shiboken6" -G"%{generator}" %{cmake-args}

variables:
  cmake-local: >-
    -DBUILD_SHARED_LIBS=ON
    -DShiboken6_USE_SYSTEM_CLANG=ON

sources:
- kind: tar
  url: tar_https:download.qt.io/official_releases/QtForPython/pyside6/PySide6-6.10.3-src/pyside-setup-everywhere-src-6.10.3.tar.xz
  ref: 2c7462fe0cecb5b8ac0a3d92014b8d0b88bd4d9f8646709dab5286d9416f45bc
# Upstream PYSIDE-3286 (clang 22 support), picked to 6.11 only. freedesktop-sdk
# 26.08 ships LLVM 22; without it the generated QtCore wrappers do not compile.
- kind: patch
  path: patches/shiboken6/0001-clang-22-fully-qualified-type-names.patch
# clang 22 prints "QList<QString>::value_type" for typedefs within class
# templates (QItemSelection became QItemSelectionRange<QString>). Upstream 6.11
# strips those arguments (clang::parseTypeName()).
- kind: patch
  path: patches/shiboken6/0002-clang-22-strip-class-template-arguments.patch
