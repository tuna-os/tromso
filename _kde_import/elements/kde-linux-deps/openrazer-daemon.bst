kind: manual
description: OpenRazer daemon for Razer peripheral hardware support (userspace only, no DKMS)

sources:
- kind: tar
  url: github_files:openrazer/openrazer/archive/refs/tags/v3.12.2/openrazer-3.12.2.tar.gz
  ref: 21f69290435a77412c31422abfa297506773982cd465a98d0d69d6f46a5030d3

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-make.bst
- freedesktop-sdk.bst:components/python3.bst
- freedesktop-sdk.bst:components/python3-dbus.bst
- freedesktop-sdk.bst:components/pygobject.bst
- kde-linux-deps/python-daemonize.bst
- kde-linux-deps/python-pyudev.bst
- kde-linux-deps/python-setproctitle.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/python3.bst
- freedesktop-sdk.bst:components/python3-dbus.bst
- freedesktop-sdk.bst:components/pygobject.bst
- kde-linux-deps/python-daemonize.bst
- kde-linux-deps/python-pyudev.bst
- kde-linux-deps/python-setproctitle.bst

config:
  build-commands:
  - cd daemon && make
  install-commands:
  - make DESTDIR="%{install-root}" PREFIX=/usr daemon_install
