#!/usr/bin/env bash
# setup.sh — environment setup for Lab: Bridge Networks

set -euo pipefail

WORK_DIR="${1:-$(pwd)}"

# Clean up leftover instances and networks from previous runs
if lxc_instance_exists "net-test" 2>/dev/null; then
  echo "Cleaning up leftover 'net-test' instance..."
  lxc delete net-test --force 2>/dev/null || true
fi

if lxc network show test-bridge >/dev/null 2>&1; then
  echo "Cleaning up leftover 'test-bridge' network..."
  lxc network delete test-bridge 2>/dev/null || true
fi

echo "Lab environment ready. Follow the task instructions on the left."
