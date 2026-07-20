kind: manual

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-make.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/perl.bst

config:
  build-commands:
  - perl Makefile.PL PREFIX="%{prefix}" INSTALLDIRS=vendor
  - make

  install-commands:
  - make install DESTDIR="%{install-root}"

sources:
- kind: tar
  url: cpan:authors/id/O/OA/OALDERS/URI-5.34.tar.gz
  ref: de64c779a212ff1821896c5ca2bb69e74767d2674cee411e777deea7a22604a8
