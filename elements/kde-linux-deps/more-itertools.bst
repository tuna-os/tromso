kind: pyproject

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-python-flit.bst
- freedesktop-sdk.bst:components/stripper.bst

depends:
- freedesktop-sdk.bst:components/python3.bst

sources:
- kind: tar
  url: pypi:a2/f7/139d22fef48ac78127d18e01d80cf1be40236ae489769d17f35c3d425293/more_itertools-11.0.2.tar.gz
  ref: 392a9e1e362cbc106a2457d37cabf9b36e5e12efd4ebff1654630e76597df804
