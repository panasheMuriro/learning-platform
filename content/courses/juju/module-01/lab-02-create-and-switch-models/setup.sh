#!/usr/bin/env bash
set -euo pipefail

# Clean up prior test models if necessary
juju destroy-model lab-dev --yes --force --destroy-storage 2>/dev/null || true
juju destroy-model lab-staging --yes --force --destroy-storage 2>/dev/null || true

echo "Lab 02 environment ready."
