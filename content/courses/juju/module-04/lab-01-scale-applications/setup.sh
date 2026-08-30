#!/bin/bash
set -euo pipefail

# Ensure clean slate
juju destroy-model --no-prompt lab-scale --destroy-storage --force 2>/dev/null || true
echo "Lab environment ready."
