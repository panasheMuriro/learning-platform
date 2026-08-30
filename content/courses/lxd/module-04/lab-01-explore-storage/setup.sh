#!/usr/bin/env bash
# setup.sh — environment setup for Lab: Explore Storage Pools

set -euo pipefail

WORK_DIR="${1:-$(pwd)}"

# Clean up leftover pool and instance from previous runs
if lxc_instance_exists "storage-test" 2>/dev/null; then
  echo "Cleaning up leftover 'storage-test' instance..."
  lxc delete storage-test --force 2>/dev/null || true
fi

if lxc storage show fast-pool >/dev/null 2>&1; then
  echo "Cleaning up leftover 'fast-pool' storage pool..."
  lxc storage delete fast-pool 2>/dev/null || true
fi

echo "Lab environment ready. Follow the task instructions on the left."
