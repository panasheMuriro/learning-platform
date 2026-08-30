#!/usr/bin/env bash
# setup.sh — environment setup for Lab: Files & Snapshots
# Picks up from previous labs (container 'web' exists and is running).

set -euo pipefail

WORK_DIR="${1:-$(pwd)}"

# Ensure 'web' container exists and is running
if ! lxc_instance_exists "web" 2>/dev/null; then
  echo "Container 'web' not found. Creating it for this lab..."
  lxc launch ubuntu:24.04 web 2>/dev/null || true
elif ! lxc_instance_running "web" 2>/dev/null; then
  echo "Starting existing 'web' container..."
  lxc start web 2>/dev/null || true
fi

# Clean up leftover snapshots from previous runs
if lxc_snapshot_exists "web" "backup" 2>/dev/null; then
  lxc delete web/backup 2>/dev/null || true
fi

# Clean up leftover host file
rm -f helloworld.txt 2>/dev/null || true

echo "Lab environment ready. Container 'web' is running."
echo "Follow the task instructions on the left."
