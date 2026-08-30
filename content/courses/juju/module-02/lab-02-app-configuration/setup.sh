#!/usr/bin/env bash
set -euo pipefail

# Clean up prior lab-config model if present
juju destroy-model lab-config --no-prompt --force --destroy-storage 2>/dev/null || true

echo "Lab 02 initialized."