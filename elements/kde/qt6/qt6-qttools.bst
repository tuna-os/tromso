kind: cmake
description: Qt6 tools module

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/qt6/qt6-qtbase.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- freedesktop-sdk.bst:components/vulkan-headers.bst
- kde/qt6/qt6-qtdeclarative.bst

config:
  # qtdiag/qtdiag6 are hard-linked; break them before the freedesktop-sdk
  # stripper runs (it refuses to process files with multiple hard links)
  install-commands:
    (>):
    - |
      find /buildstream-install/usr/bin -type f -links +1 | while IFS= read -r f; do
        tmp=$(mktemp "${f}.XXXXXX")
        cp -a "$f" "$tmp"
        mv -f "$tmp" "$f"
      done

sources:
- kind: tar
  url: qt:6.10/6.10.3/submodules/qttools-everywhere-src-6.10.3.tar.xz
  ref: 8f00b9e3d1f80973d81cff67684972b89993183ef19924404d5b8ff0f89675b6
