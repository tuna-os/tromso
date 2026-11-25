#!/usr/bin/env bash
# Stream a BuildStream CAS tarball from GHCR straight into the local cache.
#
# Usage: scripts/cas-restore-stream.sh <oras-ref> [<cache-dir>]
#   <oras-ref>   e.g. ghcr.io/tuna-os/tromso/cache-tromso-core:latest
#   <cache-dir>  defaults to ~/.cache/buildstream
#
# The restore itself is `cas_transport.py restore` from tuna-os/bst-ci, the
# repository that produces these archives. It owns the archive format, the
# restore filter (sources, logs, staging, tmp, sockets), the resumable
# GHCR download, the digest check and the object check of cas_untar.py.
# This repository keeps no copy of any of them (tuna-os/tromso#472).
#
# Why streaming: `oras pull ... -o .` first writes the whole tarball (up to
# ~28 GB compressed per chunk, 2026-09-10 GHCR sizes) to the runner disk and
# only then extracts it, which exhausted the build_final runner in runs
# 34072176433, 34176106533 and 34298830711. cas_transport.py pipes the blob
# through zstd and the untar, so the compressed bytes never touch disk.
#
# Exit status: 0 on success. 1 if <oras-ref> has no manifest, so a caller
# can fall back to another tag (build-final.yml tries the cache-key tag,
# then :latest). Non-zero if the fetch, the digest check or the extraction
# failed. Callers decide whether that is fatal.
set -euo pipefail

REF="${1:?usage: $0 <oras-ref> [<cache-dir>]}"
CACHE_DIR="${2:-${HOME}/.cache/buildstream}"

# The fetch is by commit, so git checks the content. Keep this commit equal
# to the multirunner-build.yml pin or newer.
BST_CI_COMMIT=a3face86dff4d4c82260b5bc59b4fa8fb8cfdd1d
if [ -z "${CAS_TRANSPORT:-}" ]; then
    BST_CI="${HOME}/.cache/bst-ci/restore-${BST_CI_COMMIT}"
    CAS_TRANSPORT="${BST_CI}/scripts/cas_transport.py"
    if [ ! -f "$CAS_TRANSPORT" ] || [ ! -f "${BST_CI}/scripts/cas_untar.py" ]; then
        rm -rf "$BST_CI"
        git init -q "$BST_CI"
        git -C "$BST_CI" fetch -q --depth 1 https://github.com/tuna-os/bst-ci "$BST_CI_COMMIT"
        git -C "$BST_CI" checkout -q FETCH_HEAD
    fi
fi

# `cas_transport.py restore` treats a missing manifest as a cold cache and
# exits 0. Callers here need to tell that apart, so check first.
if ! python3 "$CAS_TRANSPORT" exists "$REF"; then
    echo "cas-restore-stream: no manifest for ${REF}" >&2
    exit 1
fi

echo "cas-restore-stream: streaming ${REF} into ${CACHE_DIR}"
python3 "$CAS_TRANSPORT" restore "$REF" "$CACHE_DIR"
