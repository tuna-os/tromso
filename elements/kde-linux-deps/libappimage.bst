kind: cmake
description: Library for reading and creating AppImage files

sources:
- kind: tar
  url: tar_https:github.com/AppImage/libappimage/archive/refs/tags/v1.0.4-5.tar.gz
  ref: 2c4e18860a790c5959da6eb064cbd07f165fe6a9b15989491a3a3f176d06af31

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- freedesktop-sdk.bst:public-stacks/buildsystem-make.bst
- freedesktop-sdk.bst:components/automake.bst
- freedesktop-sdk.bst:components/autoconf.bst
- freedesktop-sdk.bst:components/libtool.bst
- freedesktop-sdk.bst:components/patch.bst
- freedesktop-sdk.bst:components/librsvg.bst
- freedesktop-sdk.bst:components/libarchive.bst
- freedesktop-sdk.bst:components/xz.bst
- kde-linux-deps/squashfuse.bst
- kde-linux-deps/xdg-utils-cxx.bst
- kde/libs/boost.bst

depends:
- kde-linux-deps/squashfuse.bst
- kde-linux-deps/xdg-utils-cxx.bst
- kde/libs/boost.bst
- freedesktop-sdk.bst:components/libarchive.bst
- freedesktop-sdk.bst:components/xz.bst
- freedesktop-sdk.bst:components/cairo.bst
- freedesktop-sdk.bst:components/glib.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  cmake-local: >-
    -DBUILD_TESTING=OFF
    -DUSE_CCACHE=OFF
    -DINSTALL_DOCS=OFF
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5
    -DUSE_SYSTEM_SQUASHFUSE=ON
    -DUSE_SYSTEM_LIBARCHIVE=ON
    -DUSE_SYSTEM_XZ=ON
    -DUSE_SYSTEM_BOOST=ON
    -DLIBAPPIMAGE_DESKTOP_INTEGRATION_ENABLED=OFF
    -DLIBAPPIMAGE_THUMBNAILER_ENABLED=OFF
    -DUSE_SYSTEM_XDGUTILS=ON

config:
  configure-commands:
    (<):
    - |
      # GCC 15: hashlib.h uses uint8_t but doesn't include <cstdint>; this worked
      # transitively before but GCC 15 is stricter. Also add <vector> and <string>.
      python3 -c "
      path = 'src/libappimage/utils/hashlib.h'
      src = open(path).read()
      if '#include <cstdint>' not in src:
          src = '#include <cstdint>\n#include <vector>\n#include <string>\n' + src
          open(path, 'w').write(src)
          print('Patched hashlib.h')
      "
      # GCC 15: std::stringstream implicit conversion to std::istream& is ambiguous.
      # Use explicit cast to resolve overload in hashlib.cpp.
      python3 -c "
      path = 'src/libappimage/utils/hashlib.cpp'
      src = open(path).read()
      src = src.replace('return md5(ss);', 'return md5(static_cast<std::istream&>(ss));')
      open(path, 'w').write(src)
      print('Patched hashlib.cpp')
      "
