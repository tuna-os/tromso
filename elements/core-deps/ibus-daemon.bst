kind: filter

build-depends:
- gnome-build-meta.bst:sdk-deps/ibus.bst

runtime-depends:
- core-deps/dconf.bst
- gnome-build-meta.bst:sdk/glib.bst
- gnome-build-meta.bst:sdk/gtk+-3.bst
- gnome-build-meta.bst:sdk/libibus.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

config:
  exclude:
    - libibus
