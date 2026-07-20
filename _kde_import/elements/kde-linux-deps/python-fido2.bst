kind: pyproject

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-python-poetry.bst
- freedesktop-sdk.bst:components/stripper.bst

depends:
- freedesktop-sdk.bst:components/python3.bst
- freedesktop-sdk.bst:components/python3-cryptography.bst

config:
  build-commands:
  - python3 -c "from poetry.core.masonry.api import build_wheel; build_wheel('%{dist-dir}', None)"

sources:
- kind: tar
  url: pypi:09/34/4837e2f5640baf61d8abd6125ccb6cc60b4b2933088528356ad6e781496f/fido2-2.2.0.tar.gz
  ref: 0d8122e690096ad82afde42ac9d6433a4eeffda64084f36341ea02546b181dd1
