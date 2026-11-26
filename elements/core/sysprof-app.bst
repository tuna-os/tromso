kind: filter

build-depends:
- gnome-build-meta.bst:sdk-deps/sysprof.bst

runtime-depends:
- gnome-build-meta.bst:sdk-deps/libpanel.bst
- gnome-build-meta.bst:sdk/adwaita-icon-theme.bst
- gnome-build-meta.bst:sdk/glib.bst
- gnome-build-meta.bst:sdk/gtk.bst
- gnome-build-meta.bst:sdk/json-glib.bst
- gnome-build-meta.bst:sdk/libadwaita.bst
- gnome-build-meta.bst:sdk/libdex.bst
- freedesktop-sdk.bst:components/libunwind.bst
- freedesktop-sdk.bst:components/polkit.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

config:
  exclude:
  - sysprof-agent

public:
  bst:
    # This might overlap with sysprof-minimal as due to some pkgcofnig/meson
    # quirkyness sysprof-capture ends up in Requires.private and now
    # is a runtime dependency of glib so other modules can find the .pc file
    # even though its a statically build dependency
    # see: gnome-build-meta.bst:sdk/glib.bst
    overlap-whitelist:
    - '%{includedir}/sysprof-6/*.h'
    - '%{libdir}/libsysprof-capture-4.a'
    - '%{libdir}/pkgconfig/sysprof-capture-4.pc'
    - "%{project_licensedir}/sysprof"
    - "%{project_licensedir}/sysprof/**"
