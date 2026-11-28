kind: meson
description: vkBasalt, a Vulkan post-processing layer (off until ENABLE_VKBASALT=1)

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-meson.bst
- freedesktop-sdk.bst:components/glslang.bst
- freedesktop-sdk.bst:components/spirv-headers.bst
- freedesktop-sdk.bst:components/vulkan-headers.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/vulkan-icd-loader.bst
- freedesktop-sdk.bst:components/xorg-lib-x11.bst

environment:
  # GCC 15 does not include <cstdint> by itself.
  CXXFLAGS: '%{target_flags} -include cstdint'

sources:
- kind: git_repo
  url: github:DadSchoorse/vkBasalt.git
  ref: v0.3.2.9-0-g44e0b7ef31c1ec9565508289e74199ea2702d6b1
