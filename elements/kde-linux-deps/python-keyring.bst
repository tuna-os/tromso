kind: pyproject

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-python-setuptools.bst
- freedesktop-sdk.bst:components/python3-setuptools-scm.bst

depends:
- freedesktop-sdk.bst:components/python3.bst
- kde-linux-deps/more-itertools.bst
- kde-linux-deps/python-jaraco-classes.bst
- kde-linux-deps/python-jaraco-context.bst
- kde-linux-deps/python-jaraco-functools.bst
- kde-linux-deps/python-secretstorage.bst

config:
  build-commands:
  - python3 -c "from setuptools.build_meta import build_wheel; build_wheel('%{dist-dir}', dict())"

sources:
- kind: tar
  url: pypi:43/4b/674af6ef2f97d56f0ab5153bf0bfa28ccb6c3ed4d1babf4305449668807b/keyring-25.7.0.tar.gz
  ref: fe01bd85eb3f8fb3dd0405defdeac9a5b4f6f0439edbb3149577f244a2e8245b
