#!/usr/bin/env bash
# setup.sh — environment setup for Lab: Manage Local Images
# Picks up from the previous lab (container 'app' exists).

set -euo pipefail

WORK_DIR="${1:-$(pwd)}"

# Ensure 'app' container exists (prerequisite from previous lab)
if ! lxc_instance_exists "app" 2>/dev/null; then
  echo "Container 'app' not found. Creating it for this lab..."
  lxc launch ubuntu:24.04 app 2>/dev/null || true
fi

# Clean up leftover alias from previous runs
if lxc_image_alias_exists "my-ubuntu" 2>/dev/null; then
  lxc image alias delete my-ubuntu 2>/dev/null || true
fi

echo "Lab environment ready. Container 'app' exists."
echo "Follow the task instructions on the left."
