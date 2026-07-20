kind: manual
description: Boost C++ Libraries (headers + compiled components for filesystem/thread/chrono/program_options)

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-make.bst

variables:
  strip-binaries: ''

config:
  configure-commands:
  - ./bootstrap.sh --prefix=/usr --with-libraries=filesystem,thread,chrono,program_options,system,date_time,atomic

  build-commands:
  - ./b2 -j%{max-jobs} variant=release link=shared threading=multi runtime-link=shared cxxstd=17

  install-commands:
  - ./b2 -j%{max-jobs} variant=release link=shared threading=multi runtime-link=shared cxxstd=17 install --prefix=%{install-root}/usr

sources:
- kind: tar
  url: boost_io:release/1.87.0/source/boost_1_87_0.tar.bz2
  ref: af57be25cb4c4f4b413ed692fe378affb4352ea50fbe294a11ef548f4d527d89
  base-dir: boost_1_87_0
