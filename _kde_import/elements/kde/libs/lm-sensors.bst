kind: make

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-make.bst
- freedesktop-sdk.bst:components/bison.bst
- freedesktop-sdk.bst:components/flex.bst
- freedesktop-sdk.bst:components/which.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  make-args: >-
    PREFIX="%{prefix}"
    LIBDIR="%{libdir}"
    SBINDIR="%{bindir}"

sources:
- kind: tar
  url: github:lm-sensors/lm-sensors/archive/V3-6-0.tar.gz
  ref: 0591f9fa0339f0d15e75326d0365871c2d4e2ed8aa1ff759b3a55d3734b7d197
  base-dir: lm-sensors-3-6-0
