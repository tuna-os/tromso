#!/usr/bin/env bash
# Boot gate of the OGC variant: install the image to an ext4 composefs disk,
# boot it in QEMU with lockdown on, and test the kernel, the modules and a
# Plasma session.
#
# Usage: ogc-boot-test.sh <image-ref in root's podman storage> <output dir>
#
# The kernel argument lockdown=integrity makes a valid signature mandatory for
# each module that the test loads. Needs root, KVM, OVMF and 30 GB of disk.
set -euo pipefail

IMAGE=${1:?image} OUT=${2:?output directory}
PORT=2322
RELEASE=$(python3 -c 'import json;print(json.load(open("files/ogc/manifest.json"))["kernel_release"])')
mkdir -p "$OUT"
OUT=$(realpath "$OUT")
WORK=$(mktemp -d -p "${BOOT_TEST_DIR:-/var/tmp}" ogc-boot.XXXXXX)
QEMU_PID=
cleanup() {
  [ -z "$QEMU_PID" ] || kill "$QEMU_PID" 2>/dev/null || true
  rm -rf "$WORK"
}
trap cleanup EXIT

echo "== install"
truncate -s 30G "$WORK/disk.raw"
# Install from an OCI layout, as fisherman does on the live medium.
skopeo copy "containers-storage:$IMAGE" "oci:$WORK/oci"
podman run --rm --privileged --pid=host --security-opt label=type:unconfined_t \
  -v /dev:/dev -v "$WORK:/data" \
  "$IMAGE" bootc install to-disk --via-loopback /data/disk.raw --source-imgref oci:/data/oci \
  --composefs-backend --bootloader systemd --filesystem ext4 --generic-image --wipe \
  --karg lockdown=integrity --karg console=tty0 --karg console=ttyS0 \
  --karg systemd.firstboot=no --karg systemd.journald.forward_to_console=1 \
  2>&1 | tee "$OUT/install.log"

ssh-keygen -q -t ed25519 -N '' -f "$WORK/key"
code='' vars=''
for d in /usr/share/OVMF /usr/share/edk2/ovmf; do
  for s in _4M ''; do
    if [ -z "$code" ] && [ -f "$d/OVMF_CODE$s.fd" ]; then
      code=$d/OVMF_CODE$s.fd vars=$d/OVMF_VARS$s.fd
    fi
  done
done
cp "$vars" "$WORK/vars.fd"

echo "== boot"
qemu-system-x86_64 -machine q35,accel=kvm -cpu host -m 6G -smp 4 \
  -drive "if=pflash,format=raw,readonly=on,file=$code" \
  -drive "if=pflash,format=raw,file=$WORK/vars.fd" \
  -drive "file=$WORK/disk.raw,format=raw,if=virtio,cache=unsafe" \
  -device virtio-vga -display none \
  -netdev "user,id=n,hostfwd=tcp:127.0.0.1:$PORT-:22" -device virtio-net-pci,netdev=n \
  -smbios "type=11,value=io.systemd.credential.binary:ssh.authorized_keys.root=$(base64 -w0 "$WORK/key.pub")" \
  -serial "file:$OUT/serial.log" -monitor "unix:$WORK/mon,server,nowait" &
QEMU_PID=$!

guest() {
  ssh -i "$WORK/key" -p "$PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR -o ConnectTimeout=5 root@127.0.0.1 "$@"
}
shot() {
  printf 'screendump %s/%s.ppm\n' "$WORK" "$1" \
    | python3 -c 'import socket,sys,time;s=socket.socket(socket.AF_UNIX);s.connect(sys.argv[1]);s.sendall(sys.stdin.buffer.read());time.sleep(3)' "$WORK/mon"
  if command -v convert >/dev/null; then
    convert "$WORK/$1.ppm" "$OUT/$1.png"
  else
    cp "$WORK/$1.ppm" "$OUT/"
  fi
}

for _ in $(seq 120); do
  guest true 2>/dev/null && break
  kill -0 "$QEMU_PID"
  sleep 5
done
if ! guest true; then
  shot no-ssh
  tail -60 "$OUT/serial.log"
  exit 1
fi

echo "== kernel and modules"
guest bash -s <<'EOF' 2>&1 | tee "$OUT/kernel.txt"
uname -a
cat /proc/cmdline
findmnt -no SOURCE,FSTYPE,OPTIONS / /sysroot
echo "lockdown: $(cat /sys/kernel/security/lockdown)"
echo "lsm: $(cat /sys/kernel/security/lsm)"
echo "sig_enforce: $(cat /sys/module/module/parameters/sig_enforce)"
echo "sched_ext: $(cat /sys/kernel/sched_ext/state)"
ls -l /dev/ntsync
for c in memory dmem; do grep -qw $c /sys/fs/cgroup/cgroup.controllers && echo "cgroup controller: $c"; done
sysctl vm.max_map_count kernel.split_lock_mitigate net.ipv4.tcp_congestion_control
gamescope --version 2>&1 | head -3
mangohud --version
systemctl is-active dmemcg-booster-system.service
systemctl --failed --no-legend
EOF
grep -q " $RELEASE " "$OUT/kernel.txt"
grep -q 'lockdown:.*\[integrity\]' "$OUT/kernel.txt"
grep -q '/dev/ntsync' "$OUT/kernel.txt"

echo "== load each out-of-tree module"
mods=$(python3 -c 'import json;print(*json.load(open("files/ogc/manifest.json"))["out_of_tree_modules"])')
# A driver can refuse a machine that does not have its device (ENODEV). A bad
# signature, a wrong kernel or a missing symbol is a failure.
guest bash -s -- "$mods" <<'EOF' 2>&1 | tee "$OUT/modules.txt"
for m in $1; do
  if out=$(modprobe -v "$m" 2>&1); then
    echo "LOADED $m signer=$(modinfo -F signer "$m") vermagic=$(modinfo -F vermagic "$m" | cut -d' ' -f1)"
  elif grep -q 'No such device' <<<"$out"; then
    echo "NODEV $m"
  else
    echo "FAILED $m: $out"
  fi
done
echo "tainted: $(cat /proc/sys/kernel/tainted)"
EOF
guest lsmod >"$OUT/lsmod.txt"
if grep -q '^FAILED' "$OUT/modules.txt"; then
  guest dmesg | tail -40
  exit 1
fi

echo "== an unsigned module must not load"
guest bash -s <<'EOF' 2>&1 | tee "$OUT/unsigned.txt"
ko=$(modinfo -n v4l2loopback)
rmmod v4l2loopback
zstd -dcq "$ko" >/tmp/signed.ko
python3 - <<'P'
d = open("/tmp/signed.ko", "rb").read()
t = b"~Module signature appended~\n"
assert d.endswith(t)
n = int.from_bytes(d[-len(t) - 4:-len(t)], "big")
open("/tmp/unsigned.ko", "wb").write(d[:-len(t) - 12 - n])
P
if insmod /tmp/unsigned.ko; then echo UNSIGNED-LOADED; else echo UNSIGNED-REFUSED; fi
EOF
grep -q UNSIGNED-REFUSED "$OUT/unsigned.txt"

echo "== Plasma session"
shot greeter
guest bash -s <<'EOF'
useradd -m -G wheel tester
mkdir -p /etc/sddm.conf.d
session=$(ls /usr/share/wayland-sessions | grep -i plasma | head -1)
printf '[Autologin]\nUser=tester\nSession=%s\n' "${session%.desktop}" >/etc/sddm.conf.d/99-test.conf
systemctl restart sddm
EOF
plasma=
for _ in $(seq 36); do
  sleep 5
  if guest pgrep -u tester -x plasmashell >/dev/null 2>&1; then plasma=yes; break; fi
done
sleep 30
shot plasma
guest 'loginctl list-sessions --no-legend; ps -u tester -o comm= | sort -u | tr "\n" " "; journalctl -b -p err --no-pager | tail -40' \
  >"$OUT/session.txt" 2>&1 || true
cat "$OUT/session.txt"
[ "$plasma" = yes ]
echo "ogc-boot-test: pass"
