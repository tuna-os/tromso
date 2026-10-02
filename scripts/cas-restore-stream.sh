#!/usr/bin/env bash
# Stream a BuildStream CAS tarball from GHCR straight into the local cache.
#
# Usage: scripts/cas-restore-stream.sh <oras-ref> [<cache-dir>]
#   <oras-ref>   e.g. ghcr.io/tuna-os/tromso/cache-tromso-core:latest
#   <cache-dir>  defaults to ~/.cache/buildstream
#
# Why streaming: `oras pull ... -o .` first writes the whole tarball (up to
# ~28 GB compressed per chunk, 2026-09-10 GHCR sizes) to the runner disk and
# only then extracts it. On a ~100-110 GB GitHub runner that temp file is
# what pushed build_final over the edge in scheduled runs 34072176433,
# 34176106533 and 34298830711 ("No space left on device" from the runner
# itself). `oras blob fetch --output -` pipes the single tarball layer
# through zstd and tar instead, so the compressed bytes never touch disk.
#
# The CAS tarballs are single-layer artifacts (mediaType
# application/vnd.buildstream.cas.tar.zst, title cas-<name>.tar.zst) pushed
# by tuna-os/bst-ci, so `.layers[0].digest` is the blob to fetch.
#
# --exclude=sources: each tarball is a full ~/.cache/buildstream snapshot,
# source downloads included. build_final only needs the built artifacts to
# assemble final_target, and merging every chunk's sources/ tree onto one
# runner disk is what exhausted it in run 33295159787.
#
# Exit status: 0 on success, non-zero if the manifest or blob could not be
# fetched or the extraction failed. Callers decide whether that is fatal.
set -euo pipefail

REF="${1:?usage: $0 <oras-ref> [<cache-dir>]}"
CACHE_DIR="${2:-${HOME}/.cache/buildstream}"

mkdir -p "$CACHE_DIR"

if ! MANIFEST=$(oras manifest fetch "$REF" 2>&1); then
    echo "cas-restore-stream: no manifest for ${REF}: ${MANIFEST}" >&2
    exit 1
fi

DIGEST=$(printf '%s' "$MANIFEST" | jq -r '.layers[0].digest // empty')
SIZE=$(printf '%s' "$MANIFEST" | jq -r '.layers[0].size // 0')
if [ -z "$DIGEST" ]; then
    echo "cas-restore-stream: ${REF} has no layers" >&2
    exit 1
fi

# The ref may already carry a tag; oras accepts <repo>:<tag>@<digest>.
echo "cas-restore-stream: streaming ${REF}@${DIGEST} ($((SIZE / 1024 / 1024)) MiB compressed) into ${CACHE_DIR}"
# ghcr-blob-stream.py rather than `oras blob fetch --output -`: GHCR cuts
# these multi-GB downloads with "PROTOCOL_ERROR" every few minutes and oras
# cannot resume, so a cut threw the whole restore away. The helper resumes
# with HTTP Range and verifies the digest.
python3 "$(dirname "$0")/ghcr-blob-stream.py" "$REF" "$DIGEST" "$SIZE" \
    | zstd -d -T0 \
    | tar --exclude=sources -xf - -C "$CACHE_DIR"
