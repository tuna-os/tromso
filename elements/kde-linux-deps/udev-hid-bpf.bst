kind: manual
description: Pre-compiled BPF-based HID device quirks and udev rules (udev-hid-bpf)

sources:
- kind: tar
  url: tar_https:gitlab.freedesktop.org/api/v4/projects/16971/packages/generic/udev-hid-bpf/2.2.0-20251121/udev-hid-bpf_2.2.0-20251121.tar.xz
  ref: 811f58e33923174f21f78c843355804a2b55a9f8f6b3b4b59878991e7acfae61

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/libbpf.bst
- freedesktop-sdk.bst:components/systemd.bst

build-depends:
- freedesktop-sdk.bst:components/findutils.bst

variables:
  strip-binaries: ''

config:
  install-commands:
  - install -Dm755 bin/udev-hid-bpf %{install-root}/usr/bin/udev-hid-bpf
  - find lib/firmware -type d -exec install -dm755 %{install-root}/usr/{} \;
  - find lib/firmware -type f -exec install -Dm644 {} %{install-root}/usr/{} \;
  - install -Dm644 lib/udev/rules.d/81-hid-bpf.rules -t %{install-root}/usr/lib/udev/rules.d/
  - install -Dm644 lib/udev/hwdb.d/81-hid-bpf-stable.hwdb -t %{install-root}/usr/lib/udev/hwdb.d/
  - install -Dm644 lib/udev/hwdb.d/81-hid-bpf-testing.hwdb -t %{install-root}/usr/lib/udev/hwdb.d/
  - install -Dm644 share/man/man1/udev-hid-bpf.1 -t %{install-root}/usr/share/man/man1/
