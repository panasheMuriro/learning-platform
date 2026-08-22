#!/usr/bin/env bash
# check.sh — grading script for Lab 1: Inspect Client, Clouds & Controllers

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

# Task 1: Check Juju CLI version
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-1" ]; then
  version=$(juju version 2>/dev/null || true)
  if [[ -n "$version" ]]; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Check Juju CLI version" \
      --arg msg "Juju CLI version: $version" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Check Juju CLI version" \
      --arg msg "Juju CLI command not found or not responding." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 2: List available clouds
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-2" ]; then
  clouds=$(juju clouds 2>/dev/null || true)
  if [[ -n "$clouds" ]]; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "List available clouds" \
      --arg msg "Available clouds listed successfully." \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "List available clouds" \
      --arg msg "Failed to list clouds with 'juju clouds'." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 3: Inspect controller status
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-3" ]; then
  if juju_controller_exists; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Inspect controller status" \
      --arg msg "Juju controller is reachable." \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Inspect controller status" \
      --arg msg "No reachable Juju controller found." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

all_passed=$(echo "$tasks" | jq '[.[].passed] | all')
emit_result "$all_passed" "$tasks"
