kind: pyproject

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-python-flit.bst
- freedesktop-sdk.bst:components/stripper.bst

depends:
- freedesktop-sdk.bst:components/python3.bst

sources:
- kind: tar
  url: pypi:7b/6f/357efd7602486741aa73ffc0617fb310a29b588ed0fd69c2399acbb85b0c/jeepney-0.9.0.tar.gz
  ref: cf0e9e845622b81e4a28df94c40345400256ec608d0e55bb8a3feaa9163f5732
