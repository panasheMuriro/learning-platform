#!/usr/bin/env bash
set -e

MODEL_NAME="tf-iac-lab"

if juju show-model "$MODEL_NAME" >/dev/null 2>&1; then
    juju destroy-model "$MODEL_NAME" --yes --destroy-storage --force || true
fi

rm -f main.tf terraform.tfstate terraform.tfstate.backup

echo "Setup complete: Ready for Terraform IaC lab."
