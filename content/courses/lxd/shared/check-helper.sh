#!/usr/bin/env bash
# check-helper.sh — shared helper for LXD lab check.sh scripts.
#
# Source this from each lab's check.sh:
#   source "$(dirname "$0")/../../shared/check-helper.sh"
#
# Provides:
#   - emit_result(passed, tasks_json)       — emit the final JSON result
#   - task(id, name, passed, message)       — format a single task result
#   - lxc_instance_exists(name)             — check if an instance exists
#   - lxc_instance_running(name)            — check if an instance is RUNNING
#   - lxc_instance_stopped(name)            — check if an instance is STOPPED
#   - lxc_instance_type(name, expected)     — check instance type (container/vm)
#   - lxc_config_get(name, key)             — get a config value
#   - lxc_config_equals(name, key, value)   — check config matches a value
#   - lxc_snapshot_exists(instance, snap)   — check if a snapshot exists
#   - lxc_image_exists(fingerprint_or_alias) — check if a local image exists
#   - lxc_image_alias_exists(alias)         — check if an image alias exists

set -euo pipefail

# Emit the final grade result as JSON on stdout.
# Usage: emit_result <passed:bool> <tasks_json_array>
emit_result() {
  local passed="$1"
  local tasks="$2"
  cat <<EOF
{"passed": ${passed}, "tasks": ${tasks}}
EOF
}

# Format a single task result as a JSON object.
# Usage: task <id> <name> <passed:bool> <message>
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

# Check if an LXD instance exists.
# Usage: lxc_instance_exists <name>
# Returns 0 if exists, 1 otherwise.
lxc_instance_exists() {
  local name="$1"
  lxc list "$name" --format csv -c n 2>/dev/null | grep -qx "$name"
}

# Check if an LXD instance is in RUNNING state.
# Usage: lxc_instance_running <name>
lxc_instance_running() {
  local name="$1"
  lxc list "$name" --format csv -c s 2>/dev/null | grep -qx "RUNNING"
}

# Check if an LXD instance is in STOPPED state.
# Usage: lxc_instance_stopped <name>
lxc_instance_stopped() {
  local name="$1"
  lxc list "$name" --format csv -c s 2>/dev/null | grep -qx "STOPPED"
}

# Check the type of an instance (container or vm).
# Usage: lxc_instance_type <name> <expected_type>
lxc_instance_type() {
  local name="$1"
  local expected="$2"
  local actual
  actual=$(lxc list "$name" --format csv -c t 2>/dev/null | head -1)
  [ "$actual" = "$expected" ]
}

# Get a config value for an instance.
# Usage: lxc_config_get <name> <key>
lxc_config_get() {
  local name="$1"
  local key="$2"
  lxc config get "$name" "$key" 2>/dev/null
}

# Check if a config value matches an expected value.
# Usage: lxc_config_equals <name> <key> <expected_value>
lxc_config_equals() {
  local name="$1"
  local key="$2"
  local expected="$3"
  local actual
  actual=$(lxc_config_get "$name" "$key")
  [ "$actual" = "$expected" ]
}

# Check if a snapshot exists for an instance.
# Usage: lxc_snapshot_exists <instance> <snapshot_name>
lxc_snapshot_exists() {
  local instance="$1"
  local snapshot="$2"
  lxc info "$instance" 2>/dev/null | grep -q "Name: ${snapshot}$"
}

# Check if a local image exists by fingerprint or alias.
# Usage: lxc_image_exists <fingerprint_or_alias>
lxc_image_exists() {
  local id="$1"
  lxc image list "$id" --format csv -c f 2>/dev/null | grep -q .
}

# Check if a local image alias exists.
# Usage: lxc_image_alias_exists <alias>
lxc_image_alias_exists() {
  local alias="$1"
  lxc image list --format csv -c a 2>/dev/null | grep -qx "$alias"
}
