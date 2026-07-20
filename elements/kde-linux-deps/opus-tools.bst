kind: autotools

sources:
- kind: git_repo
  url: github:xiph/opus-tools
  track: v*
  ref: v0.2-0-g0c1337f57e5b87fd23421904303fed3e575ce354

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- kde-linux-deps/libopusenc.bst

depends:
- freedesktop-sdk.bst:components/opus.bst
- freedesktop-sdk.bst:components/opusfile.bst
- freedesktop-sdk.bst:components/libogg.bst
- freedesktop-sdk.bst:components/libflac.bst
- kde-linux-deps/libopusenc.bst
