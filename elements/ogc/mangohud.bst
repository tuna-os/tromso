kind: meson
description: MangoHud and mangoapp

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-meson.bst
- freedesktop-sdk.bst:components/glslang.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- freedesktop-sdk.bst:components/python3-mako.bst
- ogc/nlohmann-json.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/libdbus.bst
- freedesktop-sdk.bst:components/libdrm.bst
- freedesktop-sdk.bst:components/libglvnd.bst
- freedesktop-sdk.bst:components/libxkbcommon.bst
- freedesktop-sdk.bst:components/vulkan-icd-loader.bst
- freedesktop-sdk.bst:components/wayland.bst
- freedesktop-sdk.bst:components/xorg-lib-x11.bst
- ogc/glfw.bst

variables:
  meson-local: >-
    -Dmangoapp=true
    -Dmangohudctl=true
    -Duse_system_spdlog=disabled
    -Dwith_wayland=enabled
    -Dwith_xnvctrl=disabled
    -Dtests=disabled
    -Dmangoplot=disabled

config:
  configure-commands:
    (<):
    - |
      cp -r subprojects/packagefiles/imgui-1.91.6/. subprojects/imgui-1.91.6/
      cp -r subprojects/packagefiles/vulkan-headers/. subprojects/Vulkan-Headers-1.4.346/
      cp -r subprojects/packagefiles/vulkan-utility-libraries/. subprojects/Vulkan-Utility-Libraries-1.4.346/
      cp -r implot-wrap/. subprojects/implot-0.16/
      cp -r spdlog-wrap/. subprojects/spdlog-1.14.1/
  install-commands:
  - DESTDIR='%{install-root}' meson install -C %{build-dir} --skip-subprojects --no-rebuild
  - '%{install-extra}'

sources:
- kind: git_repo
  url: github:flightlessmango/MangoHud.git
  ref: v0.8.4-0-g992103e4fb744897826de04ea00a2f71e7018214
# The SHA-256 values are those of the wrap files of that tag.
- kind: tar
  url: github_files:ocornut/imgui/archive/refs/tags/v1.91.6.tar.gz
  ref: c5fbc5dcab1d46064001c3b84d7a88812985cde7e0e9ced03f5677bec1ba502a
  directory: subprojects/imgui-1.91.6
- kind: tar
  url: github_files:KhronosGroup/Vulkan-Headers/archive/v1.4.346.tar.gz
  ref: 5bb77f5d7b460e255a9e51affc00d64354986b55cf577d8eab28529cad01fc80
  directory: subprojects/Vulkan-Headers-1.4.346
- kind: tar
  url: github_files:KhronosGroup/Vulkan-Utility-Libraries/archive/v1.4.346.tar.gz
  ref: 372eb525103ecb4e3a04d030b2a9778ebc67853bbdc82ce6747de3757d432ad9
  directory: subprojects/Vulkan-Utility-Libraries-1.4.346
- kind: zip
  url: github_files:epezent/implot/archive/refs/tags/v0.16.zip
  ref: 24f772c688f6b8a6e19d7efc10e4923a04a915f13d487b08b83553aa62ae1708
  directory: subprojects/implot-0.16
- kind: zip
  url: github_files:mesonbuild/wrapdb/releases/download/implot_0.16-1/implot_0.16-1_patch.zip
  ref: 1c6b1462066a5452fa50c1da1dd47fed841f28232972c82d778f2962936568c7
  directory: implot-wrap
# The spdlog of the image is a static library without PIC.
- kind: tar
  url: github_files:gabime/spdlog/archive/refs/tags/v1.14.1.tar.gz
  ref: 1586508029a7d0670dfcb2d97575dcdc242d3868a259742b69f100801ab4e16b
  directory: subprojects/spdlog-1.14.1
- kind: zip
  url: github_files:mesonbuild/wrapdb/releases/download/spdlog_1.14.1-1/spdlog_1.14.1-1_patch.zip
  ref: ae878e732330ea1048f90d7e117c40c0cd2a6fb8ae5492c7955818ce3aaade6c
  directory: spdlog-wrap
