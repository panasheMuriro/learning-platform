#!/usr/bin/env bash
# check.sh — grading script for Lab 2: Inspect, Update & Reset Application Configuration

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

# Task 1: Check model 'lab-config' and application 'custom-node'
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-1" ]; then
  if ! juju_model_exists "lab-config"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Create model 'lab-config' and deploy 'custom-node'" \
      --arg msg "Model 'lab-config' not found. Run: juju add-model lab-config" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  else
    app_exists=$(juju status -m lab-config --format json 2>/dev/null | jq -e '.applications | has("custom-node")' 2>/dev/null || echo "false")
    if [[ "$app_exists" == "true" ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-1" --arg name "Create model 'lab-config' and deploy 'custom-node'" \
        --arg msg "Application 'custom-node' is deployed in model 'lab-config'." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-1" --arg name "Create model 'lab-config' and deploy 'custom-node'" \
        --arg msg "Application 'custom-node' not found in model 'lab-config'. Run: juju deploy ubuntu custom-node --channel latest/stable" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  fi
fi

# Task 2: Configure hostname=worker-01 (or verified having been set/reset)
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-2" ]; then
  if ! juju_model_exists "lab-config"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Configure application hostname" \
      --arg msg "Model 'lab-config' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  else
    app_exists=$(juju status -m lab-config --format json 2>/dev/null | jq -e '.applications | has("custom-node")' 2>/dev/null || echo "false")
    if [[ "$app_exists" != "true" ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-2" --arg name "Configure application hostname" \
        --arg msg "Application 'custom-node' does not exist." \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    else
      val=$(juju config -m lab-config custom-node hostname 2>/dev/null | tr -d '\r\n' || echo "")
      if [[ "$val" == "worker-01" ]]; then
        tasks=$(jq --argjson arr "$tasks" \
          --arg id "task-2" --arg name "Configure application hostname" \
          --arg msg "hostname is configured to 'worker-01'." \
          '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
      else
        tasks=$(jq --argjson arr "$tasks" \
          --arg id "task-2" --arg name "Configure application hostname" \
          --arg msg "hostname on 'custom-node' is '$val', expected 'worker-01'. Run: juju config custom-node hostname=worker-01" \
          '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
      fi
    fi
  fi
fi

# Task 3: Deploy 'helper-node' and reset its hostname to default
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-3" ]; then
  if ! juju_model_exists "lab-config"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Deploy 'helper-node' and reset its hostname to default" \
      --arg msg "Model 'lab-config' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  else
    app_exists=$(juju status -m lab-config --format json 2>/dev/null | jq -e '.applications | has("helper-node")' 2>/dev/null || echo "false")
    if [[ "$app_exists" != "true" ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Deploy 'helper-node' and reset its hostname to default" \
        --arg msg "Application 'helper-node' not found in model 'lab-config'. Run: juju deploy ubuntu helper-node --channel latest/stable" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    else
      val=$(juju config -m lab-config helper-node hostname 2>/dev/null | tr -d '\r\n' || echo "")
      if [[ -z "$val" ]]; then
        tasks=$(jq --argjson arr "$tasks" \
          --arg id "task-3" --arg name "Deploy 'helper-node' and reset its hostname to default" \
          --arg msg "Application 'helper-node' exists and its hostname is reset to default." \
          '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
      else
        tasks=$(jq --argjson arr "$tasks" \
          --arg id "task-3" --arg name "Deploy 'helper-node' and reset its hostname to default" \
          --arg msg "hostname on 'helper-node' is currently '$val'. Run: juju config helper-node --reset hostname" \
          '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
      fi
    fi
  fi
fi

all_passed=$(echo "$tasks" | jq '[.[].passed] | all')
emit_result "$all_passed" "$tasks"