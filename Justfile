# List available commands
[group('info')]
default:
    @just --list

# ── Configuration ─────────────────────────────────────────────────────

# Same bst2 container image CI uses -- pinned by SHA for reproducibility
export bst2_image := env("BST2_IMAGE", "registry.gitlab.com/freedesktop-sdk/infrastructure/freedesktop-sdk-docker-images/bst2:f89b4aef847ef040b345acceda15a850219eb8f1")

# ── BuildStream wrapper ──────────────────────────────────────────────
# Runs any bst command inside the bst2 container via podman.
# Usage: just bst build oci/kde-linux/image.bst
#        just bst show oci/kde-linux/stack.bst
[group('dev')]
bst *ARGS:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "${HOME}/.cache/buildstream" "${HOME}/.cargo" "${HOME}/.config/buildstream"

    podman --cgroup-manager=cgroupfs run --rm \
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

# ── Build targets ─────────────────────────────────────────────────────

# Build the KDE Linux OCI image (non-interactive background build with log)
[group('build')]
bst-build TARGET="oci/kde-linux/image.bst":
    #!/usr/bin/env bash
    set -euo pipefail
    LOG=/tmp/kde-build.log
    echo "==> Building {{TARGET}} (log: $LOG)" | tee "$LOG"
    just bst build {{TARGET}} 2>&1 | tee -a "$LOG"

# Tail the build log
[group('build')]
log:
    tail -f /tmp/kde-build.log

# Show element dependency graph
[group('dev')]
show TARGET="oci/kde-linux/stack.bst":
    just bst show {{TARGET}}
