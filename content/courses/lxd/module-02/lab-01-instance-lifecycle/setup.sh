#!/usr/bin/env bash
# setup.sh — environment setup for Lab 1: Instance Lifecycle

set -euo pipefail

WORK_DIR="${1:-$(pwd)}"

# Clean up any leftover 'web' instance from previous runs
if lxc_instance_exists "web" 2>/dev/null; then
  echo "Cleaning up leftover 'web' instance..."
  lxc delete web --force 2>/dev/null || true
fi

echo "Lab 1 environment ready."
echo "Follow the task instructions on the left."
