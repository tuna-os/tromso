#!/bin/bash
# Aurora Dakota Build Monitor

MAX_JOBS=4
FETCHERS=64
LOG=/var/tmp/aurora-build.log
KBM_DIR=/var/home/james/dev/kde-build-meta
AURORA_DIR=/var/home/james/dev/kde-linux

log() { echo "[$(date '+%H:%M:%S')] $*"; }

get_available_ram_gb() {
    awk '/^MemAvailable/ {printf "%.1f", $2/1024/1024}' /proc/meminfo
}

get_swap_used_gb() {
    awk '/^SwapTotal/ {t=$2} /^SwapFree/ {f=$2} END {printf "%.1f", (t-f)/1024/1024}' /proc/meminfo
}

restart_build() {
    local jobs=$1
    log "Restarting build with --max-jobs $jobs --fetchers $FETCHERS"
    podman stop aurora-build 2>/dev/null
    podman rm aurora-build 2>/dev/null
    sleep 3
    nohup podman run --name aurora-build --privileged --device /dev/fuse --network=host \
      -v "/var/home/james/dev/kde-linux:/src:rw" \
      -v "/var/home/james/.cache/buildstream:/root/.cache/buildstream:rw" \
      -w /src \
      "registry.gitlab.com/freedesktop-sdk/infrastructure/freedesktop-sdk-docker-images/bst2:f89b4aef847ef040b345acceda15a850219eb8f1" \
      bst --colors --max-jobs $jobs --fetchers $FETCHERS build oci/aurora.bst \
      >> $LOG 2>&1 &
    disown
    log "Build restarted (PID $!)"
    sleep 5
}

get_element_log_dir() {
    # Convert element path like kde/frameworks/kio.bst -> kde-frameworks-kio
    local elem="$1"
    # Remove .bst, replace / with -
    local name="${elem%.bst}"
    name="${name//\//-}"
    echo "gnome/${name}"
}

read_element_log() {
    local logdir="$HOME/.cache/buildstream/logs/$1"
    if [ -d "$logdir" ]; then
        local latest=$(ls -t "$logdir" 2>/dev/null | head -1)
        if [ -n "$latest" ]; then
            cat "$logdir/$latest"
        fi
    fi
}

get_cmake_flags_for_element() {
    # Returns appropriate cmake-local flags for a KDE element
    local elem="$1"
    echo "-DBUILD_TESTING=OFF -DBUILD_PYTHON_BINDINGS=OFF"
}

update_junction() {
    cd "$KBM_DIR"
    local SHA=$(git rev-parse --short=7 HEAD)
    log "Updating junction to kde-build-meta SHA: $SHA"
    
    # Download tarball and get sha256 + base-dir
    local tarball_data
    tarball_data=$(curl -sL "https://github.com/hanthor/kde-build-meta/archive/${SHA}.tar.gz" | tee /var/home/james/dev/kde-linux/kbm_tmp.tar.gz | sha256sum)
    local SHA256=$(echo "$tarball_data" | awk '{print $1}')
    local BASE_DIR=$(tar tzf /var/home/james/dev/kde-linux/kbm_tmp.tar.gz | head -1 | tr -d '/')
    rm -f /var/home/james/dev/kde-linux/kbm_tmp.tar.gz
    
    log "SHA256: $SHA256"
    log "BASE_DIR: $BASE_DIR"
    
    # Update elements/kde-build-meta.bst
    local bst_file="$AURORA_DIR/elements/kde-build-meta.bst"
    
    # Get current url to extract base
    local new_url="https://github.com/hanthor/kde-build-meta/archive/${SHA}.tar.gz"
    
    python3 - "$bst_file" "$new_url" "$SHA256" "$BASE_DIR" << 'PYEOF'
import sys, re

bst_file, new_url, sha256, base_dir = sys.argv[1:]

with open(bst_file) as f:
    content = f.read()

# Update url
content = re.sub(r'(url:\s*)https://github\.com/hanthor/kde-build-meta/archive/[^\s]+\.tar\.gz',
                 f'\\g<1>{new_url}', content)
# Update ref
content = re.sub(r'(ref:\s*)[a-f0-9]+', f'\\g<1>{sha256}', content)
# Update base-dir
content = re.sub(r'(base-dir:\s*)\S+', f'\\g<1>{base_dir}', content)

with open(bst_file, 'w') as f:
    f.write(content)

print(f"Updated {bst_file}")
PYEOF
    
    cd "$AURORA_DIR"
    TMPDIR=/var/tmp git add elements/kde-build-meta.bst
    TMPDIR=/var/tmp git commit -m "Update junction to kde-build-meta ${SHA}

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
    git push origin main
    log "Junction updated and pushed"
}

fix_element() {
    local element_path="$1"  # e.g., kde/frameworks/kio.bst
    local log_content="$2"
    
    local bst_file="$KBM_DIR/elements/${element_path}"
    log "Fixing element: $element_path"
    
    # Analyze the log to determine fix needed
    local fix_applied=false
    
    # Check for missing cmake find_package deps
    if echo "$log_content" | grep -q "Could not find a package configuration file provided by"; then
        local missing_pkg=$(echo "$log_content" | grep -oP 'Could not find a package configuration file provided by "\K[^"]+' | head -1)
        log "Missing cmake package: $missing_pkg"
        # Would need to add to build-depends - this requires specific analysis
    fi
    
    # Check for X11 issues
    if echo "$log_content" | grep -qiE "x11|xcb" && echo "$log_content" | grep -qi "error"; then
        log "Possible X11/XCB issue detected"
    fi
    
    echo "$fix_applied"
}

diagnose_and_fix() {
    log "=== DIAGNOSING BUILD FAILURES ==="
    
    # Get list of failed elements
    local failures=$(grep "FAILURE" "$LOG" | grep -v "^    " | tail -30)
    log "Failures found: $(echo "$failures" | wc -l)"
    echo "$failures"
    
    if [ -z "$failures" ]; then
        # Check if build succeeded
        if grep -q "SUCCESS.*oci/aurora.bst" "$LOG" 2>/dev/null || \
           grep -q "^  SUCCESS" "$LOG" 2>/dev/null; then
            log "BUILD COMPLETE - oci/aurora.bst succeeded!"
            return 0
        fi
        log "No failures found but build didn't succeed. Check log tail:"
        tail -20 "$LOG"
        return 2
    fi
    
    # Extract unique element names from failures
    local elements_to_fix=()
    while IFS= read -r line; do
        # Extract element path from failure line like:  FAILURE kde/frameworks/kio.bst
        local elem=$(echo "$line" | grep -oP '(?<=FAILURE )\S+\.bst' | head -1)
        if [ -n "$elem" ]; then
            elements_to_fix+=("$elem")
        fi
    done <<< "$failures"
    
    log "Elements to fix: ${elements_to_fix[*]}"
    
    # For each failed element, read log and analyze
    local any_fixed=false
    for elem in "${elements_to_fix[@]}"; do
        local logdir_key=$(get_element_log_dir "$elem")
        log "Reading log for $elem (dir: $logdir_key)"
        local elem_log=$(read_element_log "$logdir_key")
        
        if [ -z "$elem_log" ]; then
            log "No log found for $elem in $logdir_key"
            # Try alternate naming
            local alt=$(echo "$elem" | sed 's|kde/||' | sed 's|/|-|g' | sed 's|\.bst||')
            log "Trying alternate: gnome/kde-$alt"
            elem_log=$(read_element_log "gnome/kde-$alt")
        fi
        
        log "Log length for $elem: ${#elem_log} bytes"
        if [ -n "$elem_log" ]; then
            log "Last 50 lines of $elem build log:"
            echo "$elem_log" | tail -50
        fi
    done
    
    return 1
}

# Main monitoring loop
log "=== Aurora Dakota Build Monitor Started ==="
log "Initial settings: --max-jobs $MAX_JOBS --fetchers $FETCHERS"

CYCLE=0
while true; do
    CYCLE=$((CYCLE + 1))
    
    # Check memory
    RAM=$(get_available_ram_gb)
    SWAP=$(get_swap_used_gb)
    log "Cycle $CYCLE | RAM avail: ${RAM}GB | Swap used: ${SWAP}GB | max-jobs: $MAX_JOBS"
    
    # Memory-based scaling
    RAM_INT=$(echo "$RAM" | cut -d. -f1)
    SWAP_INT=$(echo "$SWAP" | cut -d. -f1)
    
    CONTAINER_RUNNING=$(podman ps --filter name=aurora-build --format "{{.Names}}" 2>/dev/null)
    
    if [ -n "$CONTAINER_RUNNING" ]; then
        # Container is running - check memory
        if [ "$RAM_INT" -lt 4 ] || [ "$SWAP_INT" -gt 6 ]; then
            NEW_JOBS=$((MAX_JOBS - 2))
            [ $NEW_JOBS -lt 2 ] && NEW_JOBS=2
            log "⚠️  MEMORY CRITICAL: RAM=${RAM}GB SWAP=${SWAP}GB — reducing max-jobs $MAX_JOBS → $NEW_JOBS"
            MAX_JOBS=$NEW_JOBS
            restart_build $MAX_JOBS
        elif [ "$RAM_INT" -lt 8 ]; then
            log "⚠️  Memory warning: RAM=${RAM}GB (below 8GB)"
        elif [ "$RAM_INT" -gt 16 ] && [ "$MAX_JOBS" -lt 8 ]; then
            NEW_JOBS=$((MAX_JOBS + 2))
            [ $NEW_JOBS -gt 8 ] && NEW_JOBS=8
            log "✅ Memory healthy: RAM=${RAM}GB — bumping max-jobs $MAX_JOBS → $NEW_JOBS"
            MAX_JOBS=$NEW_JOBS
            restart_build $MAX_JOBS
        else
            log "✅ Memory OK — build running normally"
            # Show last build progress line
            local_progress=$(grep -E "FETCH|BUILD|CACHE|Fetching|Building" "$LOG" 2>/dev/null | tail -3)
            if [ -n "$local_progress" ]; then
                echo "$local_progress"
            fi
        fi
    else
        log "Container not running — checking build result"
        diagnose_result=$?
        
        # Check if it completed successfully
        if tail -50 "$LOG" | grep -qE "^  SUCCESS.*oci/aurora|Build finished|Pipeline succeeded"; then
            log "🎉 BUILD COMPLETE! oci/aurora.bst succeeded!"
            exit 0
        fi
        
        # Run diagnosis
        diagnose_and_fix
        DIAG_RESULT=$?
        
        if [ $DIAG_RESULT -eq 0 ]; then
            log "🎉 BUILD COMPLETE!"
            exit 0
        fi
        
        log "Waiting 10s before checking if we should restart..."
        sleep 10
        
        # If container still not running, restart it
        STILL_RUNNING=$(podman ps --filter name=aurora-build --format "{{.Names}}" 2>/dev/null)
        if [ -z "$STILL_RUNNING" ]; then
            log "Container still not running — restarting build (fixes should have been applied externally)"
            restart_build $MAX_JOBS
        fi
    fi
    
    log "Sleeping 120s until next check..."
    sleep 120
done
