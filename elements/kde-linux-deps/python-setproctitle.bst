kind: pyproject
description: Python library to customize the process title (setproctitle)

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-python-setuptools.bst

depends:
- freedesktop-sdk.bst:components/python3.bst

sources:
- kind: tar
  url: pypi:8d/48/49393a96a2eef1ab418b17475fb92b8fcfad83d099e678751b05472e69de/setproctitle-1.3.7.tar.gz
  ref: bc2bc917691c1537d5b9bca1468437176809c7e11e5694ca79a9ca12345dcb9e
