#!/usr/bin/env bash
# setup.sh — environment setup for Lab: Launch Your First Container
# Picks up from the previous lab (LXD is installed and initialized).

set -euo pipefail

WORK_DIR="${1:-$(pwd)}"

# Verify LXD is ready (prerequisite from previous lab)
if ! lxc list >/dev/null 2>&1; then
  echo "⚠ LXD is not initialized. Complete the 'Install & Initialize' lab first,"
  echo "  or run: lxd init --minimal"
  exit 0
fi

# Clean up any leftover instances from previous runs
existing=$(lxc list --format csv -c n 2>/dev/null | grep -E '^(first|second)$' || true)
if [ -n "$existing" ]; then
  echo "Cleaning up leftover instances from previous runs..."
  for name in $existing; do
    lxc delete "$name" --force 2>/dev/null || true
  done
fi

echo "Lab environment ready. LXD is initialized."
echo "Follow the task instructions on the left."
