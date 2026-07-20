kind: pyproject

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-python-setuptools.bst

depends:
- freedesktop-sdk.bst:components/python3.bst

config:
  build-commands:
  - python3 -c "from setuptools.build_meta import build_wheel; build_wheel('%{dist-dir}', dict())"

sources:
- kind: tar
  url: pypi:af/50/4763cd07e722bb6285316d390a164bc7e479db9d90daa769f22578f698b4/jaraco_context-6.1.2.tar.gz
  ref: f1a6c9d391e661cc5b8d39861ff077a7dc24dc23833ccee564b234b81c82dfe3
