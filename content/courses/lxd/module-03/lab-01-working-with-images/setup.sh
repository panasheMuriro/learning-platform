#!/usr/bin/env bash
# setup.sh — environment setup for Lab 1: Working with Images

set -euo pipefail

WORK_DIR="${1:-$(pwd)}"

# Clean up leftover instances and images from previous runs
for name in app app-clone; do
  if lxc_instance_exists "$name" 2>/dev/null; then
    echo "Cleaning up leftover '$name' instance..."
    lxc delete "$name" --force 2>/dev/null || true
  fi
done

if lxc_image_alias_exists "my-app" 2>/dev/null; then
  echo "Cleaning up leftover 'my-app' image..."
  lxc image delete my-app 2>/dev/null || true
fi

echo "Lab 1 environment ready."
echo "Follow the task instructions on the left."
