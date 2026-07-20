kind: import

config:
  target: /usr/lib/systemd/system/systemd-pcrlock-make-policy.service.d

sources:
- kind: local
  path: files/kde-linux-system/systemd-pcrlock-workaround.conf
