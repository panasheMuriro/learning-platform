#!/usr/bin/env bash
set -e

MODEL_NAME="mod8-refresh-lab"

if juju show-model "$MODEL_NAME" >/dev/null 2>&1; then
    juju destroy-model "$MODEL_NAME" -y --destroy-storage --force || true
fi

juju add-model "$MODEL_NAME"

# Clean any previous artifacts
rm -f live-topology.yaml

echo "Setup complete: Model $MODEL_NAME created."

