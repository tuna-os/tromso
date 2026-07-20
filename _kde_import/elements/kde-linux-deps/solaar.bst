kind: pyproject
description: Logitech device manager for Linux (Unifying/Bolt receivers)

sources:
- kind: tar
  url: github:pwr-Solaar/Solaar/archive/refs/tags/1.1.19.tar.gz
  ref: 9392a75bfe9faf14f1e9e5c1a29bfef9d5d8552529c870bdd026915f965230f2

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-python-setuptools.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/python3.bst
- freedesktop-sdk.bst:components/python3-dbus.bst
- freedesktop-sdk.bst:components/pygobject.bst
- freedesktop-sdk.bst:components/libgudev.bst

variables:
  strip-binaries: ''
