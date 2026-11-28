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
  # abseil 20260817 (freedesktop-sdk 26.08) needs C++20, but configure.ac
  # calls AX_CXX_COMPILE_STDCXX(17), which appends -std=c++17 to CXX, so a
  # CXX override cannot win. CXXFLAGS comes last on the automake compile
  # line, so put -std=c++20 there. Also skip the header probe that cannot see
  # the header.
  conf-local: >-
    CXXFLAGS="${CXXFLAGS} -std=c++20"
    ac_cv_header_google_protobuf_compiler_command_line_interface_h=yes

public:
  bst:
    split-rules:
      devel:
        (>):
        - '%{bindir}/*'
