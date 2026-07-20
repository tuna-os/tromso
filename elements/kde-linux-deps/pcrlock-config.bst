kind: import

sources:
- kind: local
  path: files/kde-linux-system/systemd-presets/80-pcrlock.preset

config:
  target: /usr/lib/systemd/system-preset
