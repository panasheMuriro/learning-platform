#!/usr/bin/env bash
# check.sh — grading script for Lab 1: Inspect Client, Define Custom Clouds & Configure Controllers

set -euo pipefail

REQUESTED_TASK="${1:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER=""
for candidate in \
  "${SCRIPT_DIR}/../../shared/check-helper.sh" \
  "${SCRIPT_DIR}/check-helper.sh" \
  "${SCRIPT_DIR}/../check-helper.sh" \
  "$(dirname "${SCRIPT_DIR}")/check-helper.sh"; do
  if [ -f "$candidate" ]; then
    HELPER="$candidate"
    break
  fi
done
if [ -z "$HELPER" ]; then
  echo '{"passed": false, "tasks": [{"id":"default","name":"Lab check","passed":false,"message":"check-helper.sh not found"}]}'
  exit 1
fi
source "$HELPER"

tasks="[]"

# Task 1: Register a custom client cloud definition 'custom-manual'
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-1" ]; then
  if juju show-cloud custom-manual --client 2>/dev/null | grep -q "custom-manual"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Register custom client cloud definition" \
      --arg msg "Client cloud 'custom-manual' is registered." \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Register custom client cloud definition" \
      --arg msg "Custom cloud 'custom-manual' not found on client. Run: juju add-cloud custom-manual <file> --client" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 2: Configure update-status-hook-interval on controller model to 10m
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-2" ]; then
  interval=$(juju model-config -m controller update-status-hook-interval 2>/dev/null | tr -d '\r\n' || echo "")
  if [[ "$interval" == "10m" ]]; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Configure update status interval on controller model" \
      --arg msg "update-status-hook-interval is set to 10m on the controller model." \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Configure update status interval on controller model" \
      --arg msg "update-status-hook-interval on controller model is '$interval', expected '10m'." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 3: Inspect controller status
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-3" ]; then
  if juju_controller_exists; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Verify active controller status" \
      --arg msg "Juju controller is reachable." \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Verify active controller status" \
      --arg msg "No reachable Juju controller found." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

all_passed=$(echo "$tasks" | jq '[.[].passed] | all')
emit_result "$all_passed" "$tasks"
