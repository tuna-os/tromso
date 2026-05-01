kind: stack
description: Hardware enablement packages for Aurora (fingerprint, smart cards, sensors, gaming devices)

depends:
  # Fingerprint authentication
  - kde-build-meta.bst:gnomeos-deps/fprintd.bst

  # Smart card readers
  - kde-build-meta.bst:freedesktop-sdk.bst:components/ccid.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/pcsc-lite.bst

  # Android device USB access
  - kde-build-meta.bst:gnomeos-deps/android-udev-rules.bst

  # Sensor support (accelerometer, auto-rotation)
  - kde-build-meta.bst:gnomeos-deps/iio-sensor-proxy.bst

  # Gaming/peripheral devices
  - kde-build-meta.bst:gnomeos-deps/openrazer-daemon.bst

  # USB device access for Apple devices
  - kde-build-meta.bst:freedesktop-sdk.bst:components/usbmuxd.bst

  # Yubikey 2FA support
  - kde-build-meta.bst:freedesktop-sdk.bst:components/pam-u2f.bst

  # Wireless regulatory database
  - kde-build-meta.bst:freedesktop-sdk.bst:components/wireless-regdb.bst
