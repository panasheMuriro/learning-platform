#!/usr/bin/env bash
# setup.sh — environment setup for Lab 2: Files & Backups

set -euo pipefail

WORK_DIR="${1:-$(pwd)}"

# Ensure a 'web' container exists and is running for this lab
if ! lxc_instance_exists "web" 2>/dev/null; then
  echo "Creating 'web' container for this lab..."
  lxc launch ubuntu:24.04 web 2>/dev/null || true
else
  if ! lxc_instance_running "web" 2>/dev/null; then
    echo "Starting existing 'web' container..."
    lxc start web 2>/dev/null || true
  fi
fi

# Clean up leftover snapshots from previous runs
if lxc_snapshot_exists "web" "backup" 2>/dev/null; then
  lxc delete web/backup 2>/dev/null || true
fi

# Clean up leftover host file
rm -f helloworld.txt 2>/dev/null || true

echo "Lab 2 environment ready."
echo "Follow the task instructions on the left."
