kind: pyproject

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-python-setuptools.bst

depends:
- freedesktop-sdk.bst:components/python3.bst
- freedesktop-sdk.bst:components/python3-cryptography.bst
- kde-linux-deps/python-dateutil.bst

config:
  build-commands:
  - python3 -c "from setuptools.build_meta import build_wheel; build_wheel('%{dist-dir}', dict())"

sources:
- kind: tar
  url: pypi:bb/96/877a597fc0bd9a3ed33ada8b30a93f9705805dc43a330e048a8bb1078365/python_pskc-1.4.tar.gz
  ref: 4a36381446ca067be728b30e01b4d18dbd9d1ad553bf07c3710abcd87653eefe
