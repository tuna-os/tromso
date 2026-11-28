#!/usr/bin/env bash
# Compose the kernel configuration of the OGC variant and check the result.
#
#   bazzite.config        the .config of the signed OGC package that Bazzite
#                         installs: the base, so no driver of Bazzite is lost
#   tromso.config         options of the default Tromso kernel that the base
#                         does not have
#   ogc.config.set/unset  the OGC fragments, as published
#   tromso-policy.config  signatures, lockdown, compression, boot path
#
# Run in the kernel tree:
#   merge-config.sh prepare <dir with the files>   writes .config
#   merge-config.sh check   <dir with the files>   after `make olddefconfig`
set -euo pipefail
mode=$1 dir=$2

lines() { # symbol=value for the set lines, symbol=n for the unset lines
  sed -nE -e 's/^(CONFIG_[A-Za-z0-9_]+=.*)$/\1/p' \
    -e 's/^# (CONFIG_[A-Za-z0-9_]+) is not set$/\1=n/p' "$1"
}

case "$mode" in
prepare)
  {
    cat "$dir/bazzite.config" "$dir/tromso.config" "$dir/ogc.config.set"
    echo
    sed -nE 's/^(CONFIG_[A-Za-z0-9_]+)$/# \1 is not set/p' "$dir/ogc.config.unset"
    cat "$dir/tromso-policy.config"
  } | awk '
    { s = "" }
    /^CONFIG_[A-Za-z0-9_]+=/ { s = $0; sub(/=.*/, "", s) }
    /^# CONFIG_[A-Za-z0-9_]+ is not set$/ { s = $2 }
    s == "" { next }
    !(s in last) { order[++n] = s }
    { last[s] = $0 }
    END { for (i = 1; i <= n; i++) print last[order[i]] }' >.config
  ;;
check)
  declare -A have=()
  while IFS='=' read -r k v; do have[$k]=$v; done < <(lines .config)
  bad=0
  fail() { echo "kernel config: $*" >&2; bad=1; }

  # 1. Policy: exact values.
  while IFS='=' read -r k v; do
    [ "${have[$k]:-n}" = "$v" ] || fail "policy: $k is ${have[$k]:-n}, want $v"
  done < <(lines "$dir/tromso-policy.config")

  # 2. Nothing that Bazzite enables may be lost, and nothing that the default
  #    Tromso kernel enables. The allow list holds the reason for each
  #    exception.
  for f in bazzite.config tromso.config; do
    while IFS='=' read -r k v; do
      case "$v" in y | m) ;; *) continue ;; esac
      case "${have[$k]:-n}" in y | m) continue ;; esac
      grep -qE "^$k( |$)" "$dir/allow-missing.txt" && continue
      fail "$f: $k=$v is not in the result"
    done < <(lines "$dir/$f")
  done
  exit "$bad"
  ;;
*) echo "usage: merge-config.sh prepare|check DIR" >&2; exit 2 ;;
esac
