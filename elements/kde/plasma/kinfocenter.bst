kind: cmake
description: kinfocenter

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/frameworks/kdoctools.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- freedesktop-sdk.bst:components/libdrm.bst
- freedesktop-sdk.bst:components/libusb.bst
- freedesktop-sdk.bst:components/linux-pam-base.bst
- freedesktop-sdk.bst:components/libpulse.bst
- freedesktop-sdk.bst:components/vulkan-headers.bst

- kde/frameworks/kconfig.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kcmutils.bst
- kde/frameworks/kio.bst
- kde/frameworks/kservice.bst
- kde/frameworks/solid.bst
- kde/frameworks/kauth.bst
- kde/frameworks/kconfigwidgets.bst
- kde/frameworks/kcodecs.bst
- kde/frameworks/kirigami.bst
- kde/plasma/systemsettings.bst

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
    -DENABLE_OPENGL_BACKEND=OFF
    -DENABLE_VULKAN_BACKEND=OFF
    -DENABLE_ABOUT_DISTRO=OFF
    -DCMAKE_DISABLE_FIND_PACKAGE_Sensors=ON

sources:
- kind: git_repo
  url: kde:plasma/kinfocenter.git
  track: master
  ref: 4661524934085c1745ed1d2316269e1b74fbe681
- kind: patch
  path: patches/kinfocenter/0003-disable-vulkan-backend.patch
