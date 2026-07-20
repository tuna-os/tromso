kind: meson

# Rebuilds PipeWire with JACK support enabled (freedesktop-sdk builds with -Djack=disabled).
# Only the JACK-specific files from this build are included in the image
# via the pipewire-jack.bst filter element.

build-depends:
- freedesktop-sdk.bst:components/alsa-lib.bst
- freedesktop-sdk.bst:components/avahi.bst
- freedesktop-sdk.bst:components/avahi-libs.bst
- freedesktop-sdk.bst:components/bluez.bst
- freedesktop-sdk.bst:components/bluez-libs.bst
- freedesktop-sdk.bst:components/dbus.bst
- freedesktop-sdk.bst:components/gstreamer-plugins-base.bst
- freedesktop-sdk.bst:components/gtk-doc.bst
- freedesktop-sdk.bst:components/libcamera.bst
- freedesktop-sdk.bst:components/libusb.bst
- freedesktop-sdk.bst:components/liblc3.bst
- freedesktop-sdk.bst:components/libpulse.bst
- freedesktop-sdk.bst:components/libmysofa.bst
- freedesktop-sdk.bst:components/patchelf.bst
- freedesktop-sdk.bst:components/python3-docutils.bst
- freedesktop-sdk.bst:components/rtkit.bst
- freedesktop-sdk.bst:components/sbc.bst
- freedesktop-sdk.bst:components/systemd-libs.bst
- freedesktop-sdk.bst:components/systemd.bst
- freedesktop-sdk.bst:components/vulkan-headers.bst
- freedesktop-sdk.bst:components/doxygen.bst
- freedesktop-sdk.bst:components/webrtc-audio-processing.bst
- freedesktop-sdk.bst:components/libebur128.bst
- freedesktop-sdk.bst:public-stacks/buildsystem-meson.bst
- freedesktop-sdk.bst:bootstrap/grep.bst

depends:
- freedesktop-sdk.bst:components/pipewire.bst

variables:
  meson-local: >-
    -Daudiotestsrc=disabled
    -Djack=enabled
    -Droc=disabled
    -Dvideotestsrc=disabled
    -Dvolume=disabled
    -Dvulkan=disabled
    -Ddocs=disabled
    -Dman=disabled
    -Dbluez5-codec-ldac=disabled
    -Dbluez5-codec-aptx=disabled
    -Dbluez5-codec-aac=disabled
    -Dlibcamera=disabled
    -Dpipewire-v4l2=disabled
    -Dlibcanberra=disabled
    -Dbluez5-codec-lc3plus=disabled
    -Dlv2=disabled
    -Dlibjack-path=%{libdir}
    -Djack-devel=true
    -Dudevrulesdir=$(pkg-config --variable=udevdir udev)/rules.d
    -Dsession-managers=[]
    -Dlibffado=disabled
    -Dsdl2=disabled
    -Dsnap=disabled
    -Dfftw=disabled
    -Dbluez5-codec-ldac-dec=disabled
    -Dbluez5-plc-spandsp=disabled
    -Donnxruntime=disabled

public:
  bst:
    split-rules:
      jack:
      - '%{bindir}/pw-jack'
      - '%{libdir}/libjack.so*'
      - '%{libdir}/spa-0.2/jack'
      - '%{libdir}/spa-0.2/jack/**'
      - '%{datadir}/pipewire/jack.conf'

sources:
- kind: git_repo
  url: freedesktop:PipeWire/pipewire.git
  ref: 1.6.1-0-gb7341d068947225fcdf62d39277606e8516d7f52
