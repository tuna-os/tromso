# ── BuildStream wrapper ──────────────────────────────────────────────
# Runs any bst command inside the bst2 container via podman.
# Usage: BST_FLAGS="--no-interactive " just bst build oci/tromso.bst
#        just bst show oci/tromso.bst
[group('dev')]
bst *ARGS:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "${HOME}/.cache/buildstream" "${HOME}/.cargo" "${HOME}/.config/buildstream"

    podman --cgroup-manager=cgroupfs run --rm --security-opt label=type:unconfined_t \
        --privileged \
        --device /dev/fuse \
        --network=host \
        -v "{{justfile_directory()}}:/src:rw" \
        -v "${HOME}/.cache/buildstream:/root/.cache/buildstream:rw" \
        -v "${HOME}/.cargo:/root/.cargo:ro" \
        -v "${HOME}/.config/buildstream:/root/.config/buildstream:ro" \
        -w /src \
        "{{bst2_image}}" \
        bash -c 'if [ -t 1 ]; then bst --colors "$@"; else bst --no-colors "$@"; fi' -- ${BST_FLAGS:-} {{ARGS}}

# ── BuildStream via systemd-nspawn (experimental) ──────────────────────
# Run bst2 in systemd-nspawn container instead of podman (less restrictive networking)
# Usage: just bst-nspawn build oci/tromso.bst
[group('dev')]
bst-nspawn *ARGS:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "${HOME}/.cache/buildstream" "${HOME}/.cargo"
    LOG=/tmp/tromso-build.log

    # Extract bst2 OCI image to temporary directory
    echo "==> Extracting bst2 container image..." | tee -a "$LOG"
    CONTAINER_ID=$(podman create "{{bst2_image}}")
    ROOTFS=$(mktemp -d)
    trap "podman rm -f $CONTAINER_ID 2>/dev/null; sudo rm -rf $ROOTFS 2>/dev/null" EXIT

    podman export "$CONTAINER_ID" | tar -x -C "$ROOTFS"
    echo "✓ Image extracted to $ROOTFS" | tee -a "$LOG"

    # Run systemd-nspawn container
    echo "==> Running bst in systemd-nspawn..." | tee -a "$LOG"
    set +e
    sudo systemd-nspawn \
        --directory="$ROOTFS" \
        --bind="{{justfile_directory()}}:/src" \
        --bind="${HOME}/.cache/buildstream:/root/.cache/buildstream" \
        --bind-ro="${HOME}/.cargo:/root/.cargo" \
        --chdir=/src \
        --capability=all \
        /bin/bash -c 'cd /src && bst --colors {{ARGS}}' >> "$LOG" 2>&1
    BST_EXIT=$?
    set -e

    # Also display to console
    tail -50 "$LOG" | grep -A 999999 "Running bst in systemd-nspawn" || true
    exit $BST_EXIT

# ── Build log ─────────────────────────────────────────────────────────
# Run build in background, log to /tmp/tromso-build.log, tail it
[group('build')]
bst-build *ARGS:
    #!/usr/bin/env bash
    set -euo pipefail
    LOG=/tmp/tromso-build.log

    # Clear old log to keep only the most recent run
    if [ -f "$LOG" ]; then
        echo "==> Clearing old build log"
        : > "$LOG"
    fi

    echo "=== Build started at $(date) ===" > "$LOG"
    FETCHERS="${BST_FETCHERS:-$(nproc)}"
    BST_FLAGS="--max-jobs $(($(nproc) / 2)) --fetchers ${FETCHERS} ${BST_FLAGS:-}"
    # When invoked with stdout/stderr redirected, write directly to LOG and don't tail
    # (tailing the same file we write to creates an exponential feedback loop).
    if [ -t 1 ]; then
        BST_FLAGS="--no-interactive " just bst build ${ARGS:-oci/tromso.bst} 2>&1 | tee -a "$LOG"
    else
        echo "Non-interactive: writing directly to $LOG (no tail)" >&2
        BST_FLAGS="--no-interactive " just bst build ${ARGS:-oci/tromso.bst} >> "$LOG" 2>&1
    fi

[group('build')]
log:
    tail -f /tmp/tromso-build.log

# Fetch bst-dashboard at the commit pinned in the Justfile and verify its
# SHA-256 before it is installed in the cache. Files that already verify are
# left alone; a cache from an older (unpinned) download fails the check and is
# replaced. Nothing unverified is ever moved into place or executed.
[private]
_bst-dashboard-fetch force='':
    #!/usr/bin/env bash
    set -euo pipefail
    DIR="${HOME}/.cache/bst-dashboard"
    BASE="https://raw.githubusercontent.com/${bst_dashboard_repo}/${bst_dashboard_rev}/tools"
    mkdir -p "$DIR"
    cache_ok() {
        [ -f "$DIR/bst-dashboard.py" ] && [ -f "$DIR/bst-dashboard.html" ] || return 1
        printf '%s  %s\n' \
            "${bst_dashboard_py_sha256}" "$DIR/bst-dashboard.py" \
            "${bst_dashboard_html_sha256}" "$DIR/bst-dashboard.html" \
            | sha256sum -c --strict --quiet - >/dev/null 2>&1
    }
    if [ -z "{{force}}" ] && cache_ok; then
        exit 0
    fi
    echo "Downloading bst-dashboard @ ${bst_dashboard_rev:0:12}…"
    TMP="$(mktemp -d)"
    trap 'rm -rf "$TMP"' EXIT
    curl -fsSL "$BASE/bst-dashboard.py" -o "$TMP/bst-dashboard.py"
    curl -fsSL "$BASE/bst-dashboard.html" -o "$TMP/bst-dashboard.html"
    printf '%s  %s\n' \
        "${bst_dashboard_py_sha256}" "$TMP/bst-dashboard.py" \
        "${bst_dashboard_html_sha256}" "$TMP/bst-dashboard.html" \
        | sha256sum -c --strict - >&2 \
        || { echo "bst-dashboard checksum mismatch; refusing to install it." >&2; exit 1; }
    mv -f "$TMP/bst-dashboard.py" "$TMP/bst-dashboard.html" "$DIR/"

# Launch live HTML build dashboard at http://localhost:8765
# Downloads the pinned, checksum-verified bst-dashboard.py (see the Justfile)
# on first run; cached at ~/.cache/bst-dashboard/
[group('build')]
dashboard: _bst-dashboard-fetch
    #!/usr/bin/env bash
    set -euo pipefail
    SCRIPT="${HOME}/.cache/bst-dashboard/bst-dashboard.py"
    python3 "$SCRIPT" \
        --log /tmp/tromso-build.log \
        --target oci/tromso.bst \
        --project "{{justfile_directory()}}" &> /tmp/bst-dashboard.log &
    disown
    echo "Dashboard starting (log: /tmp/bst-dashboard.log)"
    for i in $(seq 1 20); do
        sleep 0.3
        if curl -sf http://localhost:8765/ > /dev/null 2>&1; then
            echo "Dashboard ready at http://localhost:8765/"
            xdg-open http://localhost:8765/ 2>/dev/null || true
            break
        fi
    done

# Re-fetch bst-dashboard at the pinned commit and re-verify it. This does NOT
# track a branch: upgrading means bumping the pin in the Justfile in a PR.
[group('build')]
dashboard-update: (_bst-dashboard-fetch "force")
    @echo "Done."

# Analyze multi-runner chunk build durations and auto-tune chunk grouping
[group('build')]
autotune-chunks limit='5':
    python3 scripts/autotune-chunk-grouping.py --limit {{limit}}

# Install bst-dashboard as a systemd user service
[group('build')]
dashboard-service: _bst-dashboard-fetch
    #!/usr/bin/env bash
    set -euo pipefail
    JUSTDIR="{{justfile_directory()}}"
    IMAGE_NAME="{{image_name}}"
    SERVICE_FILE="${HOME}/.config/systemd/user/bst-dashboard.service"
    mkdir -p "$(dirname "$SERVICE_FILE")"
    printf '%s\n' \
      '[Unit]' \
      'Description=BuildStream Build Dashboard' \
      'After=network.target' \
      '' \
      '[Service]' \
      'Type=simple' \
      'Environment=PYTHONUNBUFFERED=1' \
      "ExecStart=/usr/bin/python3 ${HOME}/.cache/bst-dashboard/bst-dashboard.py --log /tmp/${IMAGE_NAME}-build.log --target oci/${IMAGE_NAME}.bst --project ${JUSTDIR}" \
      'Restart=always' \
      'RestartSec=5' \
      '' \
      '[Install]' \
      'WantedBy=default.target' > "$SERVICE_FILE"
    systemctl --user daemon-reload
    systemctl --user enable bst-dashboard.service
    systemctl --user restart bst-dashboard.service
    sudo loginctl enable-linger $USER
    echo "Dashboard service started and enabled (linger enabled)."

# Regenerate include/image-version.yml from the HEAD commit. CI runs this
# before every `bst build` of the shipped image, so /etc/os-release carries
# VERSION_ID="<branch>.<YYYYMMDDHHMM>" (commit date, UTC) instead of the
# committed local default 'l.1'. Only needs HEAD, so a depth-1 checkout works.
[group('build')]
generate-image-version branch='main':
    #!/usr/bin/env bash
    set -euo pipefail

    # os-release VERSION_ID allows only [a-z0-9._-].
    BRANCH=$(printf '%s' "{{branch}}" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9._-' '-')
    IMAGE_VERSION=$(TZ=UTC git log -1 --format=%cd --date=format-local:%Y%m%d%H%M)
    COMMIT=$(git rev-parse HEAD)
    COMMIT_DATE_PRETTY=$(git show -s --format=%ci HEAD)
    # Keep the same filesystem-time the committed default uses: the EROFS
    # image elements need it, and changing it would churn their cache keys.
    FILESYSTEM_TIME=$(sed -n 's/^filesystem-time: *//p' include/image-version.yml)

    printf "# Generated by \`just generate-image-version\` — do not commit.\nimage-version: '%s.%s'\nfilesystem-time: %s\ncommit: '%s'\ncommit-date-pretty: '%s'\n" \
        "$BRANCH" "$IMAGE_VERSION" "${FILESYSTEM_TIME:-1321009871}" "$COMMIT" "$COMMIT_DATE_PRETTY" > include/image-version.yml
    cat include/image-version.yml
