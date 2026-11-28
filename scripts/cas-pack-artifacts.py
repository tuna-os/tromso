#!/usr/bin/env python3
"""List the CAS files that a set of BuildStream artifacts needs.

Usage: cas-pack-artifacts.py CACHE_DIR NEWER_THAN_FILE > list   (NUL separated)

An artifact proto below CACHE_DIR/artifacts/refs that is newer than
NEWER_THAN_FILE is a root. From each root the script follows every digest in
the protos (Artifact -> Directory -> file) and prints the paths, relative to
CACHE_DIR, for `tar --null -T -`.

A tar of all new CAS objects also holds the build trees that the sandbox
captured and that no artifact names (18 GiB for a kernel). Stdlib only: the
protos are scanned for digest fields, not parsed against a schema. A wrong
guess adds an object that exists under its own hash, so it costs size only.
"""

import os
import re
import sys
from pathlib import Path

HASH = re.compile(rb"^[0-9a-f]{64}$")
MAX_PROTO = 8 * 1024 * 1024


def varint(data, pos):
    value = shift = 0
    while True:
        if pos >= len(data) or shift > 63:
            raise ValueError
        byte = data[pos]
        pos += 1
        value |= (byte & 0x7F) << shift
        if not byte & 0x80:
            return value, pos
        shift += 7


def fields(data):
    """The (number, wire type, value) list of a message, or ValueError."""
    pos, out = 0, []
    while pos < len(data):
        tag, pos = varint(data, pos)
        number, wire = tag >> 3, tag & 7
        if number == 0:
            raise ValueError
        if wire == 0:
            value, pos = varint(data, pos)
        elif wire == 2:
            size, pos = varint(data, pos)
            if pos + size > len(data):
                raise ValueError
            value, pos = data[pos : pos + size], pos + size
        elif wire == 1:
            value, pos = data[pos : pos + 8], pos + 8
        elif wire == 5:
            value, pos = data[pos : pos + 4], pos + 4
        else:
            raise ValueError
        out.append((number, wire, value))
    return out


def digests(data, depth=0):
    """Every digest (message with field 1 = 64 hex digits) in a message."""
    try:
        parsed = fields(data)
    except ValueError:
        return
    for number, wire, value in parsed:
        if wire != 2:
            continue
        if number == 1 and HASH.match(value):
            yield value.decode()
        elif depth < 12 and len(value) > 60:
            yield from digests(value, depth + 1)


def main(cache, newer):
    stamp = os.stat(newer).st_mtime
    refs = [
        path
        for path in (cache / "artifacts" / "refs").rglob("*")
        if path.is_file() and path.stat().st_mtime > stamp
    ]
    if not refs:
        sys.exit("cas-pack-artifacts: no artifact is newer than the stamp")
    seen, todo, out = set(), [], []
    for path in refs:
        out.append(path.relative_to(cache).as_posix())
        todo.extend(digests(path.read_bytes()))
    while todo:
        digest = todo.pop()
        if digest in seen:
            continue
        seen.add(digest)
        rel = f"cas/objects/{digest[:2]}/{digest[2:]}"
        path = cache / rel
        if not path.is_file():
            continue
        out.append(rel)
        if path.stat().st_size <= MAX_PROTO:
            todo.extend(digests(path.read_bytes()))
    print(f"cas-pack-artifacts: {len(refs)} artifacts, {len(out)} files", file=sys.stderr)
    sys.stdout.write("\0".join(sorted(set(out))) + "\0")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(Path(sys.argv[1]), sys.argv[2])
