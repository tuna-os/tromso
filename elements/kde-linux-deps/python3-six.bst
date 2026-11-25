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
  url: pypi:94/e7/b2c673351809dca68a0e064b6af791aa332cf192da575fd474ed7d6f16a2/six-1.17.0.tar.gz
  ref: ff70335d468e7eb6ec65b95b99d3a2836546063f63acc5171de367e834932a81
