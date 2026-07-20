kind: autotools
description: Foomatic printer database (20240504)
# NOTE: The FDO freedesktop-sdk already ships foomatic-db as a component of
# cups-daemon (components/foomatic-db.bst). This element exists to track it
# explicitly in the Aurora dep tree. Prefer freedesktop-sdk.bst:components/cups-daemon.bst
# which pulls in foomatic-db transitively. If a newer snapshot is needed,
# update the ref below.

sources:
- kind: git_repo
  url: github:OpenPrinting/foomatic-db.git
  track: master
  ref: 20240504-7-g57e546cb7774c7b03e7090ced65fb1ffd552f33d

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst

depends:
- freedesktop-sdk.bst:components/cups-daemon.bst

variables:
  build-dir: ''

config:
  install-commands:
    (>):
    - |
      find "%{install-root}%{datadir}/cups/model/foomatic-db-ppds" \
        -not -type d -not -name "*.ppd" -not -name "*.ppd.*" -delete
