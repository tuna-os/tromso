kind: import

config:
  target: /usr/lib/systemd/system/ldconfig.service.d/

sources:
- kind: local
  path: files/kde-linux-system/always-ldconfig.conf
