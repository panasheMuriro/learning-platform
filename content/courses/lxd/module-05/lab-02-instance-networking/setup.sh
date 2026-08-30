#!/usr/bin/env bash
# setup.sh — environment setup for Lab: Instance Networking

set -euo pipefail

WORK_DIR="${1:-$(pwd)}"

# Clean up leftover instance from previous runs
if lxc_instance_exists "net-app" 2>/dev/null; then
  echo "Cleaning up leftover 'net-app' instance..."
  lxc delete net-app --force 2>/dev/null || true
fi

echo "Lab environment ready. Follow the task instructions on the left."
