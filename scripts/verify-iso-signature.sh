#!/usr/bin/bash
# Hash the actual bytes: cosign's file input otherwise buffers the whole ISO.
set -euo pipefail
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 ISO BUNDLE EXPECTED_WORKFLOW_IDENTITY" >&2
    exit 2
fi
digest=$(sha256sum -- "$1")
cosign verify-blob --bundle "$2" \
    --certificate-identity "$3" \
    --certificate-oidc-issuer https://token.actions.githubusercontent.com \
    "sha256:${digest%% *}"
