kind: autotools
description: UDF filesystem tools (mkudffs, udfinfo, udflabel, etc.)

sources:
- kind: tar
  url: github_files:pali/udftools/releases/download/2.3/udftools-2.3.tar.gz
  ref: 750dcf5c797765eb42265e0a56d1a99f97f94b7f6f4534263a5410503f0caf59

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  conf-local: --without-readline
