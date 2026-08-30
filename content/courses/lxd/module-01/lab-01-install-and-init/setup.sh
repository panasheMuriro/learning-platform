#!/usr/bin/env bash
# setup.sh — environment setup for Lab: Install & Initialize LXD

set -euo pipefail

WORK_DIR="${1:-$(pwd)}"

if ! command -v lxd >/dev/null 2>&1; then
  echo "LXD is not installed."
  echo "You'll install it as part of Task 1: sudo snap install lxd"
else
  echo "LXD $(lxd --version 2>/dev/null | head -1) is installed."
  if ! lxc list >/dev/null 2>&1; then
    echo "LXD is not yet initialized."
    echo "You'll initialize it as part of Task 2: lxd init --minimal"
  else
    echo "LXD is initialized and ready."
  fi
fi

echo ""
echo "Lab environment ready. Follow the task instructions on the left."
