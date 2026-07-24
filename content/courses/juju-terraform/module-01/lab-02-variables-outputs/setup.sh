#!/usr/bin/env bash
# setup.sh — environment setup for Lab 2: Variables & Outputs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${1:-$(pwd)}"

# Copy starter files if they don't exist
if [ -d "${SCRIPT_DIR}/starter" ]; then
  cp -rn "${SCRIPT_DIR}/starter/"* "${WORK_DIR}/" 2>/dev/null || true
fi

# Ensure a Juju controller exists
if ! juju controllers --format json 2>/dev/null | jq -e '.controllers | length > 0' >/dev/null 2>&1; then
  echo "Bootstrapping Juju controller on LXD..."
  juju bootstrap localhost course 2>&1 || true
fi

echo "Lab 2 environment ready."
echo "Create variables.tf, outputs.tf, and update main.tf to use variables."
