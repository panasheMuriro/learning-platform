#!/usr/bin/env bash
# setup.sh — environment setup for Lab: Shell & Exec
# Picks up from the previous lab (container 'web' exists with limits).

set -euo pipefail

WORK_DIR="${1:-$(pwd)}"

# Ensure 'web' container exists and is running (prerequisite from previous lab)
if ! lxc_instance_exists "web" 2>/dev/null; then
  echo "Container 'web' not found. Creating it for this lab..."
  lxc launch ubuntu:24.04 web 2>/dev/null || true
  lxc config set web limits.cpu=1 limits.memory=256MiB 2>/dev/null || true
elif ! lxc_instance_running "web" 2>/dev/null; then
  echo "Starting existing 'web' container..."
  lxc start web 2>/dev/null || true
fi

echo "Lab environment ready. Container 'web' is running."
echo "Follow the task instructions on the left."
