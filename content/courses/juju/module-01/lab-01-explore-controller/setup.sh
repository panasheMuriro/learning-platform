#!/usr/bin/env bash
set -euo pipefail

# Clean up prior custom cloud definition if left from earlier runs
juju remove-cloud custom-manual --client 2>/dev/null || true

# Reset update-status-hook-interval on controller model to default (5m)
juju model-config -m controller --reset update-status-hook-interval 2>/dev/null || true

echo "Lab 01 initialized."
