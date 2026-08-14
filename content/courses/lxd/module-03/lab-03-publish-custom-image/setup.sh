#!/usr/bin/env bash
# setup.sh — environment setup for Lab: Publish a Custom Image
# Picks up from previous labs (container 'app' exists).

set -euo pipefail

WORK_DIR="${1:-$(pwd)}"

# Ensure 'app' container exists (prerequisite from previous labs)
if ! lxc_instance_exists "app" 2>/dev/null; then
  echo "Container 'app' not found. Creating it for this lab..."
  lxc launch ubuntu:24.04 app 2>/dev/null || true
fi

# Clean up leftover instances and images from previous runs
if lxc_instance_exists "app-clone" 2>/dev/null; then
  echo "Cleaning up leftover 'app-clone' instance..."
  lxc delete app-clone --force 2>/dev/null || true
fi

if lxc_image_alias_exists "my-app" 2>/dev/null; then
  echo "Cleaning up leftover 'my-app' image..."
  lxc image delete my-app 2>/dev/null || true
fi

echo "Lab environment ready. Container 'app' exists."
echo "Follow the task instructions on the left."
