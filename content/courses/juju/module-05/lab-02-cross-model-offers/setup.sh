#!/bin/bash
set -euo pipefail

# Ensure clean slate
juju destroy-model --no-prompt lab-cmr-consumer --destroy-storage --force --timeout 15s 2>/dev/null || true
juju destroy-model --no-prompt lab-cmr-provider --destroy-storage --force --timeout 15s 2>/dev/null || true
echo "Lab environment ready."
