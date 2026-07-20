kind: autotools

sources:
- kind: tar
  url: github_files:tuxera/ntfs-3g/archive/2022.10.3.tar.gz
  ref: 8bd7749ea9d8534c9f0664d48b576e90b96d45ec8803c9427f6ffaa2f0dde299

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- freedesktop-sdk.bst:components/libgcrypt.bst
- freedesktop-sdk.bst:components/fuse3.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/util-linux.bst

variables:
  conf-local: >-
    --disable-static
    --with-fuse=external
    --enable-posix-acls
    --enable-xattr-mappings

environment:
  FUSE_CFLAGS: "-D_FILE_OFFSET_BITS=64 -I/usr/include/fuse3"
  FUSE_LIBS: "-lfuse3"
