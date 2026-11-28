kind: meson
description: gamescope, the fork of the Open Gaming Collective

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-meson.bst
- freedesktop-sdk.bst:components/cmake.bst
- freedesktop-sdk.bst:components/glslang.bst
- freedesktop-sdk.bst:components/spirv-headers.bst
- freedesktop-sdk.bst:components/vulkan-headers.bst
- freedesktop-sdk.bst:components/wayland-protocols.bst
- freedesktop-sdk.bst:components/hwdata.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/lcms.bst
- freedesktop-sdk.bst:components/libavif.bst
- freedesktop-sdk.bst:components/libcap.bst
- freedesktop-sdk.bst:components/libdecor.bst
- core-deps/libdisplay-info.bst
- freedesktop-sdk.bst:components/libdrm.bst
- freedesktop-sdk.bst:components/libei.bst
- freedesktop-sdk.bst:components/libinput.bst
- freedesktop-sdk.bst:components/libseat.bst
- freedesktop-sdk.bst:components/libxkbcommon.bst
- freedesktop-sdk.bst:components/pipewire.bst
- freedesktop-sdk.bst:components/pixman.bst
- freedesktop-sdk.bst:components/sdl2-compat.bst
- freedesktop-sdk.bst:components/systemd-libs.bst
- freedesktop-sdk.bst:components/vulkan-icd-loader.bst
- freedesktop-sdk.bst:components/wayland.bst
- freedesktop-sdk.bst:components/xcb-util-wm.bst
- freedesktop-sdk.bst:components/xorg-lib-x11.bst
- freedesktop-sdk.bst:components/xorg-lib-xcb.bst
- freedesktop-sdk.bst:components/xorg-lib-xcomposite.bst
- freedesktop-sdk.bst:components/xorg-lib-xcursor.bst
- freedesktop-sdk.bst:components/xorg-lib-xdamage.bst
- freedesktop-sdk.bst:components/xorg-lib-xext.bst
- freedesktop-sdk.bst:components/xorg-lib-xfixes.bst
- freedesktop-sdk.bst:components/xorg-lib-xi.bst
- freedesktop-sdk.bst:components/xorg-lib-xrender.bst
- freedesktop-sdk.bst:components/xorg-lib-xtst.bst
- freedesktop-sdk.bst:components/xorg-lib-xxf86vm.bst
- freedesktop-sdk.bst:components/xwayland.bst
- core-deps/xorg-lib-xmu.bst
- ogc/libxres.bst
- ogc/luajit.bst

variables:
  # OpenVR is off: it needs a pre-built SteamVR runtime to be useful.
  meson-local: >-
    --auto-features=auto
    -Ddrm_backend=enabled
    -Drt_cap=enabled
    -Dsdl2_backend=enabled
    --force-fallback-for=wlroots,vkroots,libliftoff,glm,stb
    -Dpipewire=enabled
    -Dinput_emulation=enabled
    -Davif_screenshots=enabled
    -Denable_openvr_support=false
    -Denable_tests=false
    -Dbenchmark=disabled

environment:
  # The WSI layer needs VK_EXT_present_timing revision 3. The headers of the SDK
  # are older. Only this build sees the newer ones.
  CPATH: '%{build-root}/vulkan-headers-new/include'

config:
  configure-commands:
    (<):
    # Meson applies a patch_directory only when it downloads the subproject.
    - |
      cp -r subprojects/packagefiles/glm/. subprojects/glm/
      cp -r subprojects/packagefiles/stb/. subprojects/stb/
      mkdir -p thirdparty/SPIRV-Headers/include
      ln -sfn %{includedir}/spirv thirdparty/SPIRV-Headers/include/spirv
  install-commands:
  - DESTDIR='%{install-root}' meson install -C %{build-dir} --skip-subprojects --no-rebuild
  - '%{install-extra}'

sources:
# Tag 3.17.0-ogc1 of OpenGamingCollective/gamescope. The other refs are its
# submodules and wraps at that commit.
- kind: git_repo
  url: github:OpenGamingCollective/gamescope.git
  ref: 4246b87f49d6116d5f863131dcc401fc52840644
- kind: git_repo
  url: freedesktop:wlroots/wlroots.git
  ref: d783533489e1f75d6886c2ab5c5960090ef268f8
  directory: subprojects/wlroots
- kind: git_repo
  url: freedesktop:emersion/libliftoff.git
  ref: 8b08dc1c14fd019cc90ddabe34ad16596b0691f4
  directory: subprojects/libliftoff
- kind: git_repo
  url: github:Joshua-Ashton/vkroots.git
  ref: 20733b938267dcac60f6ac105dbb757f9cc8df9c
  directory: subprojects/vkroots
- kind: git_repo
  url: github:Joshua-Ashton/reshade.git
  ref: 696b14cd6006ae9ca174e6164450619ace043283
  directory: src/reshade
- kind: git_repo
  url: github:g-truc/glm.git
  ref: 0af55ccecd98d4e5a8d1fad7de25ba429d60e863
  directory: subprojects/glm
- kind: git_repo
  url: github:nothings/stb.git
  ref: 5736b15f7ea0ffb08dd38af21067c314d6a3aae9
  directory: subprojects/stb
- kind: tar
  url: github_files:KhronosGroup/Vulkan-Headers/archive/v1.4.346.tar.gz
  ref: 5bb77f5d7b460e255a9e51affc00d64354986b55cf577d8eab28529cad01fc80
  directory: vulkan-headers-new
