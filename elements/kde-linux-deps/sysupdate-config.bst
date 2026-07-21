kind: import

sources:
- kind: local
  path: files/kde-linux-system/systemd-presets/50-sysupdate.preset

config:
  target: /usr/lib/systemd/system-preset
