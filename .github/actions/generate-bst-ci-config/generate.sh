#!/usr/bin/env bash
# Write buildstream-ci.conf (and, when credentials exist, client.crt /
# client.key) into the workspace root, which the Justfile mounts at /src
# inside the bst2 container. Consume with `--config /src/buildstream-ci.conf`.
#
# Ported from RazorfinOS-org/cosmic-build-meta's generate-bst-ci-config
# composite action for tuna-os/tromso#311. Two deliberate differences:
#
#   1. The logic lives in a script rather than inline in action.yml, so
#      tests/pytest/test_bst_ci_config.py can run it directly and shellcheck
#      can lint it.
#   2. Without credentials it reproduces the committed buildstream-ci.conf
#      byte for byte. That file is not dead weight — tuna-os/bst-ci's
#      multirunner-build.yml reads it from the caller's checkout for the plan,
#      core and chunk jobs, and this repo cannot change that workflow. Byte
#      equality is what makes this change a provable no-op until a CASD client
#      certificate exists; the test asserts it.
#
# Environment:
#   ENABLE_REMOTE_EXECUTION  "true" routes build actions through the executor
#   ENABLE_PUSH              "false" makes the mTLS caches read-only
#   CASD_CLIENT_CERT         PEM client certificate, empty when unavailable
#   CASD_CLIENT_KEY          PEM client key, empty when unavailable
#   GITHUB_WORKSPACE         output directory; defaults to $PWD

set -euo pipefail

WORKSPACE_ROOT="${GITHUB_WORKSPACE:-$PWD}"
CONF="$WORKSPACE_ROOT/buildstream-ci.conf"

CACHE_ENDPOINT="https://cache.projectbluefin.io:11002"
ANON_ENDPOINT="https://cache.freedesktop-sdk.io:11001"

ENABLE_REMOTE_EXECUTION="${ENABLE_REMOTE_EXECUTION:-false}"
ENABLE_PUSH="${ENABLE_PUSH:-true}"

have_creds=false
if [ -n "${CASD_CLIENT_CERT:-}" ] && [ -n "${CASD_CLIENT_KEY:-}" ]; then
    have_creds=true
fi

# Fail closed. A run that asked for remote execution and silently got a
# local-only config would look like a slow success, which is exactly the
# failure mode the six-hour builds already have.
if [ "$ENABLE_REMOTE_EXECUTION" = "true" ] && [ "$have_creds" = "false" ]; then
    echo "::error::remote execution was requested but CASD client credentials are missing"
    exit 1
fi

if [ "$have_creds" = "true" ]; then
    printf '%s\n' "$CASD_CLIENT_CERT" >"$WORKSPACE_ROOT/client.crt"
    printf '%s\n' "$CASD_CLIENT_KEY" >"$WORKSPACE_ROOT/client.key"
    chmod 0600 "$WORKSPACE_ROOT/client.crt" "$WORKSPACE_ROOT/client.key"
fi

push_flag=true
if [ "$ENABLE_PUSH" != "true" ]; then
    push_flag=false
fi

# Shared by every remote service entry below.
connection_config() {
    cat <<'EOF'
    connection-config:
      keepalive-time: 180
      retry-limit: 5
      retry-delay: 1000
      request-timeout: 180
EOF
}

client_auth() {
    cat <<'EOF'
    auth:
      client-key: /src/client.key
      client-cert: /src/client.crt
EOF
}

# Scheduler and build counts. The local-only values are this repo's current
# ones and must not change: bst-ci's chunk jobs read the committed file. The
# remote-execution values are razorfin's, copied rather than invented, because
# theirs are the ones measured at 18-22 minutes. Under remote execution the
# runner no longer compiles anything, so `builders` (elements in flight) is
# the knob that matters and `max-jobs` follows the executor rather than the
# runner's four cores.
if [ "$ENABLE_REMOTE_EXECUTION" = "true" ]; then
    fetchers=32
    builders=2
    max_jobs=8
else
    fetchers=12
    builders=1
    max_jobs=0
fi

{
    cat <<EOF
# BuildStream config used by CI (mounted at /src inside the bst2 container).
# Single-runner jobs override scheduler counts via BST_FLAGS when needed.
scheduler:
  on-error: continue
  fetchers: ${fetchers}
  builders: ${builders}
  network-retries: 3
logging:
  message-format: '[%{wallclock}][%{elapsed}][%{key}][%{element}] %{action} %{message}'
  error-lines: 80
build:
  max-jobs: ${max_jobs}
  retry-failed: True
EOF

    # Anonymous reads of cache.freedesktop-sdk.io already come from
    # project.conf; these entries add the mTLS endpoint that can also be
    # written to, and repeat the anonymous one so ordering is explicit.
    if [ "$have_creds" = "true" ]; then
        for section in artifacts source-caches; do
            echo "${section}:"
            echo "  servers:"
            echo "  - url: ${CACHE_ENDPOINT}"
            echo "    push: ${push_flag}"
            connection_config
            client_auth
            echo "  - url: ${ANON_ENDPOINT}"
            echo "    push: false"
            connection_config
        done
    fi

    echo "cache:"
    echo "  cache-buildtrees: never"

    if [ "$ENABLE_REMOTE_EXECUTION" = "true" ]; then
        # A cache storage-service makes the runner's casd remote-backed, so
        # artifact payloads stay on the BuildBox host instead of landing on a
        # ~100 GB runner. Leave it out of fetch-only jobs: `just export` has to
        # materialise the final artifact locally.
        echo "  storage-service:"
        echo "    url: ${CACHE_ENDPOINT}"
        connection_config
        client_auth
        echo "remote-execution:"
        echo "  execution-service:"
        echo "    url: ${CACHE_ENDPOINT}"
        connection_config
        client_auth
        echo "  storage-service:"
        echo "    url: ${CACHE_ENDPOINT}"
        connection_config
        client_auth
        echo "  action-cache-service:"
        echo "    url: ${CACHE_ENDPOINT}"
        echo "    push: true"
        connection_config
        client_auth
    fi
} >"$CONF"

echo "Remote execution enabled: ${ENABLE_REMOTE_EXECUTION}"
echo "CASD credentials present: ${have_creds}"
echo "=== BuildStream CI config ==="
cat "$CONF"
