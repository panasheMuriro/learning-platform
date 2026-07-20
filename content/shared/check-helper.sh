#!/usr/bin/env bash
# check-helper.sh — shared helper for lab check.sh scripts.
#
# Source this from each lab's check.sh:
#   source "$(dirname "$0")/../../shared/check-helper.sh"
#
# Provides:
#   - emit_result(passed, tasks_json)  — emit the final JSON result
#   - task(id, name, passed, message)  — format a single task result
#   - run_task(id, name, command)      — run a command, auto-determine pass/fail
#   - juju_app_exists(model, app)      — check if a Juju application exists
#   - tf_output(name)                   — get a terraform output value
#   - tf_state_has(resource_type, resource_name) — check terraform state

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
  # Escape message for JSON
  local escaped
  escaped=$(echo "$message" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ')
  printf '{"id": "%s", "name": "%s", "passed": %s, "message": "%s"}' \
    "$id" "$name" "$passed" "$escaped"
}

# Run a command and return a task result based on exit code.
# Usage: run_task <id> <name> <command...>
run_task() {
  local id="$1"
  local name="$2"
  shift 2
  local output
  if output=$("$@" 2>&1); then
    task "$id" "$name" true "$output"
  else
    task "$id" "$name" false "$output"
  fi
}

# Check if a Juju application exists in a model.
# Usage: juju_app_exists <model> <app_name>
# Returns 0 if exists, 1 otherwise.
juju_app_exists() {
  local model="$1"
  local app="$2"
  juju status --model "$model" --format json 2>/dev/null | \
    jq -e ".applications.\"${app}\"" >/dev/null 2>&1
}

# Get a terraform output value.
# Usage: tf_output <name>
tf_output() {
  local name="$1"
  terraform output -raw "$name" 2>/dev/null
}

# Check if a resource exists in terraform state.
# Usage: tf_state_has <resource_type> <resource_name>
tf_state_has() {
  local rtype="$1"
  local rname="$2"
  terraform state list 2>/dev/null | grep -q "^${rtype}.${rname}$"
}

# Check if terraform apply succeeded (no pending changes).
# Usage: tf_is_clean
tf_is_clean() {
  local plan
  plan=$(terraform plan -detailed-exitcode 2>&1) && return 0
  # exit code 0 = clean, 2 = changes pending
  local rc=$?
  [[ $rc -eq 0 ]]
}
