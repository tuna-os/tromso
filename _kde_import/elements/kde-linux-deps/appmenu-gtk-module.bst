kind: manual
description: GTK module to export application menus via DBus (appmenu-gtk-module)

sources:
- kind: tar
  url: gitlab_files:vala-panel-project/vala-panel-appmenu/-/archive/25.04/vala-panel-appmenu-25.04.tar.gz
  ref: 48d0be87b260056a65a9056a9be7e190b67a508540ebcb1fc18a67349cca0177

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-meson.bst

depends:
- sdk/gtk+-3.bst
- kde-linux-deps/libdbusmenu-gtk3.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

config:
  build-commands:
  - |
    meson setup _build subprojects/appmenu-gtk-module \
      --prefix='%{prefix}' \
      --libdir='%{libdir}' \
      -Dgtk=3 \
      --buildtype=plain
    ninja -C _build

  install-commands:
  - DESTDIR='%{install-root}' ninja -C _build install
