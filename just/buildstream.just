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

# Launch live HTML build dashboard at http://localhost:8765
# Downloads bst-dashboard.py from GitHub on first run; cached at ~/.cache/bst-dashboard/
[group('build')]
dashboard:
    #!/usr/bin/env bash
    set -euo pipefail
    SCRIPT="${HOME}/.cache/bst-dashboard/bst-dashboard.py"
    if [ ! -f "$SCRIPT" ]; then
        echo "Downloading bst-dashboard (run 'just dashboard-update' to upgrade)…"
        mkdir -p "$(dirname "$SCRIPT")"
        curl -fsSL https://raw.githubusercontent.com/hanthor/buildstream-dashboard/main/bst-dashboard.py \
            -o "$SCRIPT"
    fi
    python3 "$SCRIPT" \
        --log /tmp/tromso-build.log \
        --target oci/tromso.bst \
        --project "{{justfile_directory()}}" &>/tmp/bst-dashboard.log &
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

# Pull the latest bst-dashboard from GitHub
[group('build')]
dashboard-update:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "${HOME}/.cache/bst-dashboard"
    echo "Updating bst-dashboard…"
    curl -fsSL https://raw.githubusercontent.com/hanthor/buildstream-dashboard/main/bst-dashboard.py \
        -o "${HOME}/.cache/bst-dashboard/bst-dashboard.py"
    echo "Done."

# Install bst-dashboard as a systemd user service
[group('build')]
dashboard-service:
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
      "ExecStart=/usr/bin/python3 ${JUSTDIR}/bst-dashboard.py --log /tmp/${IMAGE_NAME}-build.log --target oci/${IMAGE_NAME}.bst --project ${JUSTDIR}" \
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

