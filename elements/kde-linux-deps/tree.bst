kind: make

sources:
- kind: git_repo
  url: gitlab:OldManProgrammer/unix-tree.git
  track: '2.*'
  ref: 2.2.1-0-g2e37be720b61ea99e34107535e575ccf836c5100

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-make.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

config:
  install-commands:
  - make PREFIX="%{install-root}%{prefix}" MANDIR="%{install-root}%{mandir}" install
