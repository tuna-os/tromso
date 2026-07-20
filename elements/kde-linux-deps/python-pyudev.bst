kind: pyproject
description: Python binding to libudev (pyudev)

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-python-setuptools.bst

depends:
- freedesktop-sdk.bst:components/python3.bst
- freedesktop-sdk.bst:components/systemd.bst

sources:
- kind: tar
  url: github_files:pyudev/pyudev/archive/v0.24.4/pyudev-0.24.4.tar.gz
  ref: 7f2e9f14151c314b0c252313e933138a4901baa25505e20c71e77080ee8a90f7
