kind: cmake
description: EncFS encrypted virtual filesystem

sources:
- kind: tar
  url: github:vgough/encfs/archive/refs/tags/v1.9.5.tar.gz
  ref: 4709f05395ccbad6c0a5b40a4619d60aafe3473b1a79bafb3aa700b1f756fd63

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- freedesktop-sdk.bst:components/pkg-config.bst
- freedesktop-sdk.bst:components/sed.bst
- freedesktop-sdk.bst:components/python3.bst
- freedesktop-sdk.bst:components/fuse3.bst
- freedesktop-sdk.bst:components/openssl.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/fuse3.bst
- freedesktop-sdk.bst:components/openssl.bst

variables:
  cmake-local: >-
    -DBUILD_UNIT_TESTS=OFF
    -DUSE_INTERNAL_TINYXML=ON
    -DUSE_INTERNAL_EASYLOGGING=ON
    -DENABLE_NLS=OFF
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5
    -DFUSE_INCLUDE_DIR="%{prefix}/include/fuse3"
    -DFUSE_LIBRARIES="%{libdir}/libfuse3.so"

config:
  configure-commands:
  - find . -name CMakeLists.txt | xargs sed -i 's/cmake_minimum_required(VERSION 2\.[0-9]*)/cmake_minimum_required(VERSION 3.5)/'
  - find . -name CMakeLists.txt | xargs sed -i 's/cmake_policy(SET CMP0063 OLD)/cmake_policy(SET CMP0063 NEW)/'
  - |
    # fuse3 changed fuse_unmount(mountpoint, chan) -> fuse_unmount(fuse*); patch to no-op
    sed -i 's/fuse_unmount(mountPoint, nullptr);/(void)mountPoint; \/\/ fuse3: unmount handled by fuse_loop/' \
      encfs/FileUtils.cpp
    # struct utimbuf in namespace encfs {} becomes encfs::utimbuf (incomplete); fix by providing using-decl
    sed -i 's|#include <fuse.h>|#include <fuse.h>\n#include <utime.h>|' encfs/encfs.h
    sed -i 's|namespace encfs {|namespace encfs {\nusing ::utimbuf;|' encfs/encfs.h
    # fuse_fill_dir_flags is a C enum, not a preprocessor macro — defined() is always false
    # Replace with a proper FUSE version check so we use the 5-arg fuse3 readdir filler
    sed -i 's/#if defined(fuse_fill_dir_flags)/#if FUSE_USE_VERSION >= 30/' encfs/encfs.cpp
    # fuse_fill_dir_flags enum: int 0 needs explicit cast in C++
    sed -i 's/filler(buf, name\.c_str(), \&st, 0, 0)/filler(buf, name.c_str(), \&st, 0, (fuse_fill_dir_flags)0)/' \
      encfs/encfs.cpp
  - |
    # Patch main.cpp for FUSE3 API changes using Python for reliable multi-line edits
    python3 << 'PYEOF'
    import re

    with open('encfs/main.cpp', 'r') as f:
        src = f.read()

    # 1. Fix encfs_init: add fuse_config* param and remove async_read (removed in FUSE3)
    src = src.replace(
        'void *encfs_init(fuse_conn_info *conn) {',
        'void *encfs_init(fuse_conn_info *conn, struct fuse_config *cfg) { (void)cfg;'
    )
    src = re.sub(r'\n\s*conn->async_read\s*=.*\n', '\n', src)

    # 2. Add FUSE3 wrapper functions before int main()
    wrappers = """
    // FUSE3 compatibility wrappers: new signatures ignore extra args and delegate
    static int fuse3_getattr(const char *p, struct stat *s, struct fuse_file_info *fi)
        { (void)fi; return encfs_getattr(p, s); }
    static int fuse3_readdir(const char *p, void *b, fuse_fill_dir_t f, off_t o,
        struct fuse_file_info *fi, enum fuse_readdir_flags flags)
        { (void)flags; return encfs_readdir(p, b, f, o, fi); }
    static int fuse3_rename(const char *a, const char *b, unsigned int flags)
        { (void)flags; return encfs_rename(a, b); }
    static int fuse3_chmod(const char *p, mode_t m, struct fuse_file_info *fi)
        { (void)fi; return encfs_chmod(p, m); }
    static int fuse3_chown(const char *p, uid_t u, gid_t g, struct fuse_file_info *fi)
        { (void)fi; return encfs_chown(p, u, g); }
    static int fuse3_truncate(const char *p, off_t o, struct fuse_file_info *fi)
        { (void)fi; return encfs_truncate(p, o); }
    static int fuse3_utimens(const char *p, const struct timespec t[2], struct fuse_file_info *fi)
        { (void)fi; return encfs_utimens(p, t); }
    """
    src = src.replace('\nint main(', wrappers + '\nint main(', 1)

    # 3. Point ops to FUSE3 wrappers
    for old, new in [
        ('encfs_oper.getattr = encfs_getattr', 'encfs_oper.getattr = fuse3_getattr'),
        ('encfs_oper.readdir = encfs_readdir', 'encfs_oper.readdir = fuse3_readdir'),
        ('encfs_oper.rename = encfs_rename',   'encfs_oper.rename = fuse3_rename'),
        ('encfs_oper.chmod = encfs_chmod',     'encfs_oper.chmod = fuse3_chmod'),
        ('encfs_oper.chown = encfs_chown',     'encfs_oper.chown = fuse3_chown'),
        ('encfs_oper.truncate = encfs_truncate', 'encfs_oper.truncate = fuse3_truncate'),
        ('encfs_oper.utimens = encfs_utimens', 'encfs_oper.utimens = fuse3_utimens'),
    ]:
        src = src.replace(old, new)

    # 4. Remove FUSE2-only ops (removed in FUSE3)
    src = re.sub(r'\n\s*encfs_oper\.utime\s*=.*\n',    '\n', src)
    src = re.sub(r'\n\s*encfs_oper\.ftruncate\s*=.*\n', '\n', src)
    src = re.sub(r'\n\s*encfs_oper\.fgetattr\s*=.*\n',  '\n', src)

    with open('encfs/main.cpp', 'w') as f:
        f.write(src)
    print("encfs/main.cpp patched for FUSE3")
    PYEOF
  - cmake -B%{build-dir} -H"%{conf-root}" -G"%{generator}" %{cmake-args} -DCMAKE_C_FLAGS="-DFUSE_USE_VERSION=31" -DCMAKE_CXX_FLAGS="-DFUSE_USE_VERSION=31"
