#!/usr/bin/env python3
"""Stream one GHCR blob to stdout, resuming with HTTP Range after a cut.

Usage: ghcr-blob-stream.py <ref> <digest> <size>
  <ref>     e.g. ghcr.io/tuna-os/xfce-linux/cache-xfce-linux-core:latest
  <digest>  sha256:... of the blob (from the manifest's layer)
  <size>    blob size in bytes (from the manifest's layer)

Why: `oras blob fetch --output -` has no resume. GHCR's blob downloads of
the 10+ GB CAS tarballs get cut with "stream error: stream ID 1;
PROTOCOL_ERROR" a few minutes in (runs 36973935390 and 36805045437, always
on a 5-minute wall-clock boundary), and every cut threw the whole restore
away, so jobs rebuilt from scratch. This reconnects at the byte offset it
reached, and checks the sha256 of the full stream before exiting 0.

Credentials come from the docker/oras auth file written by `oras login`
(~/.docker/config.json), falling back to an anonymous token.
"""

import base64
import hashlib
import http.client
import json
import os
import sys
import time
import urllib.error
import urllib.request

CHUNK = 4 * 1024 * 1024
MAX_ATTEMPTS = 40


def log(msg: str) -> None:
    print(f"ghcr-blob-stream: {msg}", file=sys.stderr, flush=True)


def basic_auth(registry: str) -> str | None:
    for path in (
        os.environ.get("DOCKER_CONFIG", "") and os.path.join(os.environ["DOCKER_CONFIG"], "config.json"),
        os.path.expanduser("~/.docker/config.json"),
        os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/nonexistent"), "containers/auth.json"),
    ):
        if not path or not os.path.isfile(path):
            continue
        try:
            auths = json.load(open(path)).get("auths", {})
        except (OSError, ValueError):
            continue
        for key in (registry, f"https://{registry}"):
            if auths.get(key, {}).get("auth"):
                return auths[key]["auth"]
    return None


def bearer(registry: str, repo: str) -> str:
    req = urllib.request.Request(f"https://{registry}/token?service={registry}&scope=repository:{repo}:pull")
    auth = basic_auth(registry)
    if auth:
        req.add_header("Authorization", f"Basic {auth}")
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.load(resp)["token"]


def main() -> int:
    if len(sys.argv) != 4:
        print(__doc__, file=sys.stderr)
        return 2
    ref, digest, size = sys.argv[1], sys.argv[2], int(sys.argv[3])
    registry, _, rest = ref.partition("/")
    repo = rest.rsplit("@", 1)[0]
    if ":" in repo.rsplit("/", 1)[-1]:
        repo = repo.rsplit(":", 1)[0]
    url = f"https://{registry}/v2/{repo}/blobs/{digest}"

    out = sys.stdout.buffer
    sha = hashlib.sha256()
    offset = 0
    attempt = 0
    token = bearer(registry, repo)
    while offset < size:
        attempt += 1
        if attempt > MAX_ATTEMPTS:
            log(f"giving up after {MAX_ATTEMPTS} attempts at byte {offset}/{size}")
            return 1
        req = urllib.request.Request(url)
        # Not forwarded on the redirect to the signed storage URL.
        req.add_unredirected_header("Authorization", f"Bearer {token}")
        if offset:
            req.add_header("Range", f"bytes={offset}-")
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                if offset and resp.status != 206:
                    log(f"server ignored Range (HTTP {resp.status}); cannot resume")
                    return 1
                while offset < size:
                    buf = resp.read(min(CHUNK, size - offset))
                    if not buf:
                        break
                    out.write(buf)
                    sha.update(buf)
                    offset += len(buf)
        except urllib.error.HTTPError as exc:
            if exc.code == 401:
                token = bearer(registry, repo)
            log(f"HTTP {exc.code} at byte {offset}/{size} (attempt {attempt}); retrying")
            time.sleep(min(30, 2 * attempt))
            continue
        except (OSError, ValueError, http.client.HTTPException) as exc:
            log(f"connection cut at byte {offset}/{size} (attempt {attempt}): {exc}; resuming")
            time.sleep(min(30, 2 * attempt))
            continue
        if offset < size:
            log(f"short read at byte {offset}/{size} (attempt {attempt}); resuming")
    out.flush()
    if offset != size:
        log(f"read {offset} bytes, expected {size}")
        return 1
    got = "sha256:" + sha.hexdigest()
    if got != digest:
        log(f"digest mismatch: got {got}, expected {digest}")
        return 1
    log(f"done: {size} bytes in {attempt} attempt(s), digest verified")
    return 0


if __name__ == "__main__":
    sys.exit(main())
