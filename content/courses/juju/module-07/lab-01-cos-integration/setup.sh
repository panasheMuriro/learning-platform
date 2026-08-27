#!/usr/bin/env bash
set -e

MODEL_NAME="mod7-cos-lab"

if juju show-model "$MODEL_NAME" >/dev/null 2>&1; then
    juju destroy-model "$MODEL_NAME" --yes --destroy-storage --force || true
fi

juju add-model "$MODEL_NAME"
echo "Setup complete: Model $MODEL_NAME created."
