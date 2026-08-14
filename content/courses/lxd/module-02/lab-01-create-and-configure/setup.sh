#!/usr/bin/env bash
# setup.sh — environment setup for Lab: Create & Configure Instances

set -euo pipefail

WORK_DIR="${1:-$(pwd)}"

# Clean up any leftover 'web' instance
if lxc_instance_exists "web" 2>/dev/null; then
  echo "Cleaning up leftover 'web' instance..."
  lxc delete web --force 2>/dev/null || true
fi

echo "Lab environment ready. Follow the task instructions on the left."
