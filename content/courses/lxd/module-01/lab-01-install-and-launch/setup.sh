#!/usr/bin/env bash
# setup.sh — environment setup for Lab 1: Install, Initialize & Launch
#
# Run when the lab starts or when "Reset" is clicked.
# Best-effort: ensures LXD is available. If it's not installed, the learner
# will install it as part of the lab tasks.

set -euo pipefail

WORK_DIR="${1:-$(pwd)}"

# Check if LXD is installed
if ! command -v lxd >/dev/null 2>&1; then
  echo "LXD is not installed."
  echo "You'll install it as part of Task 1: sudo snap install lxd"
  echo ""
else
  echo "LXD $(lxd --version 2>/dev/null | head -1) is installed."

  # Check if LXD is initialized
  if ! lxc list >/dev/null 2>&1; then
    echo "LXD is not yet initialized."
    echo "You'll initialize it as part of Task 2: lxd init --minimal"
  else
    echo "LXD is initialized and ready."
  fi
fi

# Clean up any leftover instances from previous runs
existing=$(lxc list --format csv -c n 2>/dev/null | grep -E '^(first|second)$' || true)
if [ -n "$existing" ]; then
  echo "Cleaning up leftover instances from previous runs..."
  for name in $existing; do
    lxc delete "$name" --force 2>/dev/null || true
  done
fi

echo ""
echo "Lab 1 environment ready."
echo "Follow the task instructions on the left."
