kind: import

sources:
- kind: local
  path: files/kde-linux-system/iscsi-config/50-iscsi.preset

config:
  target: /usr/lib/systemd/system-preset
