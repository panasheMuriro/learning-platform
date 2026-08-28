#!/usr/bin/env bash
set -e

MODEL_NAME="mod8-bundle-lab"

if juju show-model "$MODEL_NAME" >/dev/null 2>&1; then
    juju destroy-model "$MODEL_NAME" --yes --destroy-storage --force || true
fi

juju add-model "$MODEL_NAME"

# Clean up any leftover bundle files in lab directory
mkdir -p /tmp/juju-bundle-lab
cd /tmp/juju-bundle-lab
rm -f bundle.yaml prod-overlay.yaml exported-bundle.yaml

echo "Setup complete: Model $MODEL_NAME created."
