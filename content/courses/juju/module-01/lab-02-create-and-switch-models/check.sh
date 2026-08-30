#!/usr/bin/env bash
# check.sh — grading script for Lab 2: Create, Configure, and Switch Models

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

# Task 1: Create model 'lab-dev'
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-1" ]; then
  if juju_model_exists "lab-dev"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Create model 'lab-dev'" \
      --arg msg "Model 'lab-dev' exists." \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Create model 'lab-dev'" \
      --arg msg "Model 'lab-dev' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 2: Configure logging-config on 'lab-dev'
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-2" ]; then
  if ! juju_model_exists "lab-dev"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Configure logging-config on 'lab-dev'" \
      --arg msg "Model 'lab-dev' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  else
    val=$(juju model-config -m lab-dev logging-config 2>/dev/null | tr -d '\r\n' || echo "")
    if [[ "$val" == "<root>=INFO" ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-2" --arg name "Configure logging-config on 'lab-dev'" \
        --arg msg "logging-config is set to <root>=INFO on lab-dev." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-2" --arg name "Configure logging-config on 'lab-dev'" \
        --arg msg "logging-config on lab-dev is '$val', expected '<root>=INFO'." \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  fi
fi

# Task 3: Create 'lab-staging' and switch active model to 'lab-dev'
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-3" ]; then
  if ! juju_model_exists "lab-staging"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Create 'lab-staging' and switch active model to 'lab-dev'" \
      --arg msg "Model 'lab-staging' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  else
    current=$(juju_current_model)
    if [[ "$current" == "lab-dev" || "$current" == "admin/lab-dev" ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Create 'lab-staging' and switch active model to 'lab-dev'" \
        --arg msg "Model 'lab-staging' exists and active model is '$current'." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Create 'lab-staging' and switch active model to 'lab-dev'" \
        --arg msg "Active model is '$current', expected 'lab-dev'." \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  fi
fi

all_passed=$(echo "$tasks" | jq '[.[].passed] | all')
emit_result "$all_passed" "$tasks"
