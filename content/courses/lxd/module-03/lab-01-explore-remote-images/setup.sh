#!/usr/bin/env bash
# setup.sh — environment setup for Lab: Explore Remote Images

set -euo pipefail

WORK_DIR="${1:-$(pwd)}"

# Clean up leftover 'app' instance
if lxc_instance_exists "app" 2>/dev/null; then
  echo "Cleaning up leftover 'app' instance..."
  lxc delete app --force 2>/dev/null || true
fi

echo "Lab environment ready. Follow the task instructions on the left."
