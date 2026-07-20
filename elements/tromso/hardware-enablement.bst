kind: stack
description: Hardware enablement packages for Aurora (fingerprint, sensors, mobile devices)

depends:
  # Fingerprint authentication
  - kde-linux-deps/fprintd.bst

  # Android device USB access
  - kde-linux-deps/android-udev-rules.bst

  # Sensor support (accelerometer, auto-rotation)
  - kde-linux-deps/iio-sensor-proxy.bst
