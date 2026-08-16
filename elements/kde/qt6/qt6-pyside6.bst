kind: cmake
description: PySide6 — Qt for Python bindings

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- freedesktop-sdk.bst:components/python3.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtremoteobjects.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qttools.bst
- kde/qt6/qt6-shiboken6.bst
- freedesktop-sdk.bst:components/mesa-headers.bst

depends:
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtremoteobjects.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qttools.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/qt6/qt6-shiboken6.bst

config:
  configure-commands:
  - cmake -B%{build-dir} -H"%{conf-root}/sources/pyside6" -G"%{generator}" %{cmake-args}

# Qt is installed under /usr, which clang treats as a system-header path, so
# shiboken skips the Qt headers and builds a half-empty code model ("Class
# QTransform not found", qRed/qRgb/qRgba/qIsGray/qPixelFormat "not defined").
# Force shiboken to process the Qt include dirs anyway (same workaround used by
# Yocto meta-qt6 and Flatpak builds of PySide6 against system Qt).
variables:
  # BUILD_TESTS=OFF: PySide6's self-test target (pysidetest) generates wrapper
  # code referencing PySide::Signal against this repo's Qt6 headers, which fails
  # to compile and was taking the whole variant build down with it. The bindings
  # themselves are unaffected; only the upstream test suite is skipped.
  cmake-local: >-
    -DBUILD_SHARED_LIBS=ON
    -DPYSIDE_TREAT_QT_INCLUDE_DIRS_AS_NON_SYSTEM=ON
    -DBUILD_TESTS=OFF

# PySide6's per-module CMakeLists hard-code the generated *_wrapper.cpp files,
# including the private RHI/QShader types. The old qt6-pyside6 patch demoted
# those types to primitive-type, which makes shiboken skip wrapper generation
# and then fail the compile step (e.g. missing qshaderversion_wrapper.cpp).
# With PYSIDE_TREAT_QT_INCLUDE_DIRS_AS_NON_SYSTEM enabled above, shiboken now
# parses the QtCore/QtGui headers it needs, so build against the pristine
# upstream typesystem instead of patching it.
sources:
- kind: tar
  url: tar_https:download.qt.io/official_releases/QtForPython/pyside6/PySide6-6.10.3-src/pyside-setup-everywhere-src-6.10.3.tar.xz
  ref: 2c7462fe0cecb5b8ac0a3d92014b8d0b88bd4d9f8646709dab5286d9416f45bc
