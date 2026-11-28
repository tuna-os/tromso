kind: manual
description: LuaJIT (script engine of gamescope)

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-make.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  # The build asks git for the time of the commit. The sandbox has no git
  # history, so the value is here: the commit time of the ref.
  relver: '1795119671'
  make-args: >-
    PREFIX=%{prefix}
    INSTALL_LIB=%{install-root}%{libdir}
    INSTALL_PKGCONFIG=%{install-root}%{libdir}/pkgconfig
    CFLAGS="${CFLAGS}"
    DESTDIR=%{install-root}

config:
  build-commands:
  - |
    rm -rf .git
    echo '%{relver}' >.relver
    make %{make-args} amalg
  install-commands:
  - make %{make-args} install
  - rm -f '%{install-root}%{libdir}'/*.a
  - |
    sed -i "s|^libdir=.*|libdir=%{libdir}|" '%{install-root}%{libdir}/pkgconfig/luajit.pc'

sources:
- kind: git_repo
  url: github:LuaJIT/LuaJIT.git
  ref: 96f7b297326e9fd454b7186c6858b2773f94a0dc
