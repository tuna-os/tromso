kind: autotools

description: QEMU guest agent for virtual machine integration

sources:
- kind: tar
  url: qemu:qemu-10.1.3.tar.xz
  ref: fbaa7a0d7a9a1deb5695b125916746ec28fe0de6275d4454f3e3bbaf8b339b53

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-make.bst
- freedesktop-sdk.bst:public-stacks/buildsystem-meson.bst
- freedesktop-sdk.bst:components/python3.bst
- freedesktop-sdk.bst:components/pkg-config.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/glib.bst
- freedesktop-sdk.bst:components/fuse3.bst

variables:
  # QEMU uses a custom configure wrapper; override conf-args entirely
  # (no --exec-prefix or --disable-static which QEMU rejects)
  conf-args: >-
    --target-list=
    --prefix="%{prefix}"
    --bindir="%{bindir}"
    --sbindir="%{sbindir}"
    --sysconfdir="%{sysconfdir}"
    --datadir="%{datadir}"
    --includedir="%{includedir}"
    --libdir="%{libdir}"
    --libexecdir="%{libexecdir}"
    --localstatedir="%{localstatedir}"
    --mandir="%{mandir}"
    --infodir="%{infodir}"
    --host=%{triplet}
    --build=%{triplet}
    --disable-werror
    --disable-docs
    --enable-fuse
    --disable-blkio
    --disable-virtfs
