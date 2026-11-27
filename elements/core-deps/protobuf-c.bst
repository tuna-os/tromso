kind: autotools

sources:
- kind: tar
  url: 
    github_files:protobuf-c/protobuf-c/releases/download/v1.5.2/protobuf-c-1.5.2.tar.gz

  ref: e2c86271873a79c92b58fef7ebf8de1aa0df4738347a8bd5d4e65a80a16d0d24
- kind: patch
  path: patches/protobuf-c/compatibility_with_protobuf_34.x.patch

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/protobuf.bst

variables:
  # protobuf 36 and abseil (freedesktop-sdk 26.08) need C++17, but configure
  # ends up with plain -std=gnu++11 and then fails on the header probe and on
  # abseil's btree. Select C++17 explicitly and skip the probe that cannot see
  # the header.
  conf-local: >-
    CXX="%{triplet}-g++ -std=c++17"
    ac_cv_header_google_protobuf_compiler_command_line_interface_h=yes

public:
  bst:
    split-rules:
      devel:
        (>):
        - '%{bindir}/*'
