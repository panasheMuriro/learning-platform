#!/usr/bin/env bash
set -euo pipefail

# Clean up prior lab-deploy model if present
juju destroy-model lab-deploy --no-prompt --force --destroy-storage 2>/dev/null || true

echo "Lab 01 initialized."