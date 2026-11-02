#!/bin/bash

set -euo pipefail

umask 0077

if [[ "$#" -ge 1 ]]; then
    exec >"${1}"
fi

if command -v head >/dev/null 2>&1; then
    dd if=/dev/urandom bs=32 count=1 status=none | basenc --base32 | head -c 55
else
    key="$(dd if=/dev/urandom bs=32 count=1 status=none | basenc --base32)"
    echo -n "${key:0:55}"
fi
