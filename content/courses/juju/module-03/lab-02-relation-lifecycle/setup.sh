#!/usr/bin/env bash
set -euo pipefail

# Clean up prior lab-unrelate model if present
juju destroy-model lab-unrelate --no-prompt --force --destroy-storage 2>/dev/null || true

echo "Lab 02 initialized."