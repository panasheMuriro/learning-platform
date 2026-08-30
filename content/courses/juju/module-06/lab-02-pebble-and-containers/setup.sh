#!/bin/bash
set -euo pipefail

# Ensure clean slate
juju destroy-model --no-prompt lab-k8s-pebble --destroy-storage --force --timeout 15s 2>/dev/null || true
echo "Lab environment ready."