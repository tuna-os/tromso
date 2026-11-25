#!/bin/sh
# Fail when an upstream payload carries a sensitive path nobody reviewed.
# Usage: sh check-upstream-payload.sh <reviewed-paths.txt> [stripped-paths.txt]
# The payload is staged under system_files/shared by BuildStream. Stripped
# paths are reviewed for removal and deleted before staging into the image.
set -eu

list=$1
stripped=${2:-}
root=system_files/shared

paths=$(find "$root" \( -type f -o -type l \) \( \
    -path "$root/etc/sudoers*" -o \
    -path "$root/etc/polkit-1/*" -o \
    -path "$root/usr/share/polkit-1/*" -o \
    -path "$root/usr/lib/systemd/system/*" -o \
    -path "$root/usr/bin/*" -o \
    -path "$root/usr/share/ublue-os/*-setup.hooks.d/*" \
    \) -printf '%P\n')

failed=0
while IFS= read -r path; do
    [ -n "$path" ] || continue
    if grep -Fqx -- "$path" "$list"; then
        continue
    fi
    if [ -n "$stripped" ] && grep -Fqx -- "$path" "$stripped"; then
        continue
    fi
    echo "unreviewed sensitive upstream path: $path" >&2
    failed=1
done <<EOF
$paths
EOF

[ "$failed" -eq 0 ]
