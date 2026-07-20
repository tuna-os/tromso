kind: autotools
description: HP Linux Imaging and Printing (hplip 3.25.8)
# NOTE: hplip is a complex package. It may require additional configuration.
# Known issues:
# - Requires Python 3 with distutils (deprecated in 3.12+; may need patching)
# - net-snmp (SNMP support) is optional; omitted here as it is not in FDO
# - --enable-fax-support requires mDNS/avahi
# - GUI components (hplip-gui) require Qt; omitted here via --disable-gui-build

sources:
- kind: tar
  url: tar_https:downloads.sourceforge.net/project/hplip/hplip/3.25.8/hplip-3.25.8.tar.gz
  ref: 1cf6d6c28735435c8eb6646e83bcfb721e51c4b1f0e8cf9105a6faf96dc9ad25

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- freedesktop-sdk.bst:components/python3.bst
- freedesktop-sdk.bst:components/cups-daemon.bst

depends:
- freedesktop-sdk.bst:components/cups-daemon.bst
- freedesktop-sdk.bst:components/libusb.bst
- freedesktop-sdk.bst:components/python3.bst
- freedesktop-sdk.bst:components/dbus.bst
- freedesktop-sdk.bst:components/avahi.bst
- freedesktop-sdk.bst:components/avahi-libs.bst
- freedesktop-sdk.bst:components/openssl.bst
- kde-linux-deps/sane-backends.bst

variables:
  conf-local: >-
    --disable-foomatic-rip-hplip-install
    --disable-network-build
    --enable-hpcups-install
    --enable-cups-drv-install
    --enable-pp-build
    --disable-gui-build
    --disable-qt5
    --disable-qt4
    --enable-hpijs-install
    --enable-scan-build
    --enable-fax-build
    --disable-doc-build

config:
  configure-commands:
    (<):
    - |
      # Remove pcard from Makefile.in SUBDIRS - pcard module uses Python2 APIs.
      # Must patch Makefile.in (not Makefile.am) since the release tarball has pre-generated
      # Makefile.in and configure uses it directly without re-running automake.
      sed -i '/^SUBDIRS/s/ pcard//' Makefile.in
      # Also remove pcardext from LTLIBRARIES and all pcardext_la_* rules (Python2 API).
      # Must delete ALL lines containing @HPLIP_CLASS_DRIVER_FALSE@.*pcard (including
      # orphaned TAB continuation lines like "\tpcardext_la-fat.lo").
      sed -i '/@HPLIP_CLASS_DRIVER_FALSE@.*pcard/d' Makefile.in
      sed -i '/^pcardext_la_LIBADD\b/d' Makefile.in
      sed -i '/^am__pcardext_la_SOURCES_DIST\b/d' Makefile.in
      sed -i 's/ \$(pcardext_LTLIBRARIES)//' Makefile.in
      # hplip configure.ac line ~16783 has unquoted `test $CFLAGS` which fails when CFLAGS
      # contains flags like -O2. Use [$] in sed to match literal $.
      sed -i 's/test [$]CFLAGS = ""/test "$CFLAGS" = ""/g' configure
    - |
      # hplip 3.25.8 + GCC 15 (C23 default): fix implicit function declaration errors.
      # 1. hpaio.c calls orblite_* functions but doesn't include orblite.h
      sed -i 's|#include "orblitei.h"|#include "orblitei.h"\n#include "orblite.h"|' scan/sane/hpaio.c
      # 2. hpaio.c line 383: SANE_Device*** → const SANE_Device*** (Arch hplip-hpaio-gcc14.patch)
      sed -i 's/SANE_Device\*\*\* devList;/const SANE_Device*** devList;/' scan/sane/hpaio.c
      # 3. orblite.c: SANE_Char** → const SANE_Char** (Arch hplip-hpaio-gcc14.patch)
      sed -i 's/(SANE_Char\*\*)/(const SANE_Char**)/g' scan/sane/orblite.c
      # 4. ledmi.h: fix bb_is_paper_in_adf() → bb_is_paper_in_adf(struct ledm_session*) (Arch hplip-gcc15-stdc23.patch)
      sed -i 's/int bb_is_paper_in_adf();/int bb_is_paper_in_adf(struct ledm_session*);/' scan/sane/ledmi.h
      # 5. http.c and bb_ledm.c use usleep() but don't include unistd.h (GCC 15 C23)
      sed -i '1s/^/#include <unistd.h>\n/' scan/sane/http.c
      sed -i '1s/^/#include <unistd.h>\n/' scan/sane/bb_ledm.c
      # 6. sclpml.c uses gettimeofday() but doesn't include sys/time.h (GCC 15 C23)
      sed -i '1s/^/#include <sys\/time.h>\n/' scan/sane/sclpml.c
      # 7. orblite.c: _DBG is undefined; rename to DBG; add dlfcn.h for dlclose
      sed -i 's/\b_DBG\b/DBG/g' scan/sane/orblite.c
      python3 -c "
      path = 'scan/sane/orblite.c'
      src = open(path).read()
      if '<dlfcn.h>' not in src:
          src = '#include <dlfcn.h>\n' + src
          open(path, 'w').write(src)
      "
      # 8. orblite.c bb_orblite_open: void** vs struct t_SANE** mismatch (Arch hplip-hpaio-gcc14.patch)
      python3 -c "
      path = 'scan/sane/orblite.c'
      src = open(path).read()
      src = src.replace(
          'stat = g_handle->bb_orblite_open(devicename, &g_handle);',
          'void * temp_handle = g_handle;\n\tstat = g_handle->bb_orblite_open(devicename, &temp_handle);\n\tg_handle = temp_handle;'
      )
      open(path, 'w').write(src)
      "
      # 9. pserror.c: 'static column = 0' → 'static int column = 0' (Arch hplip-pserror-gcc14.patch)
      sed -i 's/static column = 0/static int column = 0/' prnt/hpps/pserror.c
      # 10. protocol/hp_ipp.h missing declarations for functions defined in hp_ipp.c
      cat >> protocol/hp_ipp.h << 'EOF'

      /* Forward declarations for GCC 15 C23 compatibility */
      void _releaseCupsInstance(void);
      int addCupsPrinter(char *name, char *device_uri, char *location, char *ppd_file, char *model, char *info);
      int delCupsPrinter(char *pr_name);
      int setDefaultCupsPrinter(char *pr_name);
      int controlCupsPrinter(char *pr_name, int op);
      EOF
  install-commands:
    (>):
    - |
      # Remove udev rules directory; udev rules handled separately
      rm -rf "%{install-root}/etc/udev" || true

public:
  bst:
    overlap-whitelist:
    # hplip and sane-backends both install /etc/sane.d/dll.conf
    - /etc/sane.d/dll.conf
