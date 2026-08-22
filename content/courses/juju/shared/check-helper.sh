#!/usr/bin/env bash
# check-helper.sh — shared helper for Juju lab check.sh scripts.
#
# Source this from each lab's check.sh:
#   source "$(dirname "$0")/../../shared/check-helper.sh"

set -euo pipefail

# Emit the final grade result as JSON on stdout.
emit_result() {
  local passed="$1"
  local tasks="$2"
  cat <<EOF
{"passed": ${passed}, "tasks": ${tasks}}
EOF
}

# Format a single task result as a JSON object.
task() {
  local id="$1"
  local name="$2"
  local passed="$3"
  local message="$4"
  local escaped
  escaped=$(echo "$message" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ')
  printf '{"id": "%s", "name": "%s", "passed": %s, "message": "%s"}' \
    "$id" "$name" "$passed" "$escaped"
}

# Check if a Juju controller exists and is reachable.
juju_controller_exists() {
  local name="${1:-}"
  if [[ -z "$name" ]]; then
    juju controllers --format json 2>/dev/null | jq -e '.controllers | length > 0' >/dev/null 2>&1
  else
    juju controllers --format json 2>/dev/null | jq -e ".controllers | has(\"$name\")" >/dev/null 2>&1
  fi
}

# Check if a Juju model exists.
juju_model_exists() {
  local model_name="$1"
  juju models --format json 2>/dev/null | jq -e ".models[] | select(.name == \"$model_name\" or .name == \"admin/$model_name\")" >/dev/null 2>&1
}

# Check current active model.
juju_current_model() {
  juju models --format json 2>/dev/null | jq -r '."current-model"' 2>/dev/null || echo ""
}

# Check if a model configuration key equals a value.
juju_model_config_equals() {
  local model_name="$1"
  local key="$2"
  local expected="$3"
  local val
  val=$(juju model-config -m "$model_name" "$key" 2>/dev/null | tr -d '\r\n' || echo "")
  [[ "$val" == "$expected" ]]
}

# Check if an application exists in a model.
juju_app_exists() {
  local model_name="$1"
  local app_name="$2"
  juju status -m "$model_name" --format json 2>/dev/null | jq -e ".applications | has(\"$app_name\")" >/dev/null 2>&1
}
