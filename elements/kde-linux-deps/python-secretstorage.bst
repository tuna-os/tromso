kind: pyproject

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-python-setuptools.bst

depends:
- freedesktop-sdk.bst:components/python3.bst
- freedesktop-sdk.bst:components/python3-cryptography.bst
- kde-linux-deps/python-jeepney.bst

config:
  build-commands:
  - python3 -c "from setuptools.build_meta import build_wheel; build_wheel('%{dist-dir}', dict())"

sources:
- kind: tar
  url: pypi:1c/03/e834bcd866f2f8a49a85eaff47340affa3bfa391ee9912a952a1faa68c7b/secretstorage-3.5.0.tar.gz
  ref: f04b8e4689cbce351744d5537bf6b1329c6fc68f91fa666f60a380edddcd11be
