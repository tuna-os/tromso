kind: autotools

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/libpulse.bst
- freedesktop-sdk.bst:components/libvorbis.bst
- freedesktop-sdk.bst:components/libtool.bst

variables:
  conf-local: >-
    --disable-gtk
    --disable-gtk3
    --disable-gstreamer
    --disable-alsa
    --enable-pulse
    --with-builtin=pulse
    --disable-tdb
    --disable-udev
    --disable-lynx
    --without-systemdsystemunitdir

sources:
- kind: tar
  url: 0pointer:lennart/projects/libcanberra/libcanberra-0.30.tar.xz
  ref: c2b671e67e0c288a69fc33dc1b6f1b534d07882c2aceed37004bf48c601afa72
