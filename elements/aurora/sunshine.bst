kind: cmake
description: Aurora-layer packaging for Sunshine from upstream source

build-depends:
- kde-build-meta.bst:freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst

depends:
- kde-build-meta.bst:freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/avahi.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/curl.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/libcap.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/libdrm.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/libevdev.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/libnotify.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/libpulse.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/libva.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/xorg-lib-x11.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/xorg-lib-xcb.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/xorg-lib-xfixes.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/xorg-lib-xrandr.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/xorg-lib-xtst.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/openssl.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/opus.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/pipewire.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/systemd.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/vulkan-icd-loader.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/which.bst

variables:
  strip-binaries: ""
  cmake-local: >-
    -D BUILD_DOCS=OFF
    -D BUILD_WERROR=ON
    -D CMAKE_INSTALL_PREFIX=/usr
    -D SUNSHINE_EXECUTABLE_PATH=/usr/bin/sunshine
    -D SUNSHINE_ASSETS_DIR=share/sunshine
    -D SUNSHINE_PUBLISHER_NAME='LizardByte'
    -D SUNSHINE_PUBLISHER_WEBSITE='https://app.lizardbyte.dev'
    -D SUNSHINE_PUBLISHER_ISSUE_URL='https://app.lizardbyte.dev/support'
    -D SUNSHINE_ENABLE_CUDA=OFF
    -D CUDA_FAIL_ON_MISSING=OFF
    -D BUILD_TESTS=OFF

sources:
- kind: git_repo
  url: github:LizardByte/Sunshine.git
  track: master
  ref: bdef150c6b3341cdd3048795c37257161d8afff7
