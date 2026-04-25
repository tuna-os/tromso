#!/bin/bash
# Rebuild Aurora OCI image with SSH support and create bootable disk

set -euo pipefail

cd "$(dirname "$0")"

echo "=== Step 1: Build Aurora OCI with SSH ==="
echo "Building oci/aurora.bst with openssh.bst dependency..."
just bst-build oci/aurora.bst

echo ""
echo "=== Step 2: Export OCI image ==="
echo "Exporting to podman..."
just export

echo ""
echo "=== Step 3: Verify openssh is included ==="
if sudo podman run --rm localhost/aurora:latest test -f /usr/sbin/sshd; then
    echo "✓ SSH binary found in image"
else
    echo "✗ WARNING: SSH binary not found - check build"
fi

echo ""
echo "=== Step 4: Create bootable disk ==="
echo "Generating bootable disk image with bootc..."
just generate-bootable-image

echo ""
echo "=== Ready to test ==="
echo "Boot the disk and test SSH:"
echo "  just boot-vm              # Start VM with port forwarding"
echo "  ssh -p 2222 root@127.0.0.1  # Connect via SSH (may need to wait for boot)"
