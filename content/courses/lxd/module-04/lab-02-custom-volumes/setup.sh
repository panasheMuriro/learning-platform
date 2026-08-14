#!/usr/bin/env bash
# setup.sh — environment setup for Lab: Custom Volumes

set -euo pipefail

WORK_DIR="${1:-$(pwd)}"

# Clean up leftover instances and volumes from previous runs
for name in data-app data-app-2; do
  if lxc_instance_exists "$name" 2>/dev/null; then
    echo "Cleaning up leftover '$name' instance..."
    lxc delete "$name" --force 2>/dev/null || true
  fi
done

if lxc storage volume show default shared-data >/dev/null 2>&1; then
  echo "Cleaning up leftover 'shared-data' volume..."
  lxc storage volume delete default shared-data 2>/dev/null || true
fi

echo "Lab environment ready. Follow the task instructions on the left."
