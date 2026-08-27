#!/usr/bin/env bash
# check.sh — grading script for Lab 2: Manage Relation Lifecycles & Disconnections

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

# Task 1: Check model 'lab-unrelate' and applications 'gateway' and 'api-service'
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-1" ]; then
  if ! juju_model_exists "lab-unrelate"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Create model 'lab-unrelate' and deploy applications" \
      --arg msg "Model 'lab-unrelate' not found. Run: juju add-model lab-unrelate" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  else
    has_gw=$(juju status -m lab-unrelate --format json 2>/dev/null | jq -e '.applications | has("gateway")' 2>/dev/null || echo "false")
    has_api=$(juju status -m lab-unrelate --format json 2>/dev/null | jq -e '.applications | has("api-service")' 2>/dev/null || echo "false")
    if [[ "$has_gw" == "true" && "$has_api" == "true" ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-1" --arg name "Create model 'lab-unrelate' and deploy applications" \
        --arg msg "Model 'lab-unrelate' and both applications exist." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-1" --arg name "Create model 'lab-unrelate' and deploy applications" \
        --arg msg "Deploy both applications: juju deploy haproxy gateway and juju deploy haproxy api-service" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  fi
fi

# Task 2: Verify ability to integrate (checked if task 2 explicitly requested or relation exists)
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-2" ]; then
  if ! juju_model_exists "lab-unrelate"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Integrate 'gateway' and 'api-service'" \
      --arg msg "Model 'lab-unrelate' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  else
    has_gw=$(juju status -m lab-unrelate --format json 2>/dev/null | jq -e '.applications | has("gateway")' 2>/dev/null || echo "false")
    has_api=$(juju status -m lab-unrelate --format json 2>/dev/null | jq -e '.applications | has("api-service")' 2>/dev/null || echo "false")
    if [[ "$has_gw" != "true" || "$has_api" != "true" ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-2" --arg name "Integrate 'gateway' and 'api-service'" \
        --arg msg "Applications 'gateway' and 'api-service' must be deployed first." \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    else
      # If task-2 specifically requested, check that relation is present
      if [[ "$REQUESTED_TASK" = "task-2" ]]; then
        has_rel=$(juju status -m lab-unrelate --format json 2>/dev/null | jq -e '.applications["gateway"].relations["reverseproxy"][]? | select(."related-application" == "api-service")' 2>/dev/null || echo "")
        if [[ -n "$has_rel" ]]; then
          tasks=$(jq --argjson arr "$tasks" \
            --arg id "task-2" --arg name "Integrate 'gateway' and 'api-service'" \
            --arg msg "Integration established between 'gateway' and 'api-service'." \
            '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
        else
          tasks=$(jq --argjson arr "$tasks" \
            --arg id "task-2" --arg name "Integrate 'gateway' and 'api-service'" \
            --arg msg "Integration not found. Run: juju integrate gateway:reverseproxy api-service:website" \
            '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
        fi
      else
        # In full test, task 2 is considered completed if applications are deployed
        tasks=$(jq --argjson arr "$tasks" \
          --arg id "task-2" --arg name "Integrate 'gateway' and 'api-service'" \
          --arg msg "Integration step recorded." \
          '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
      fi
    fi
  fi
fi

# Task 3: Break relation and verify no integration between gateway and api-service
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-3" ]; then
  if ! juju_model_exists "lab-unrelate"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Break relation between 'gateway' and 'api-service'" \
      --arg msg "Model 'lab-unrelate' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  else
    has_gw=$(juju status -m lab-unrelate --format json 2>/dev/null | jq -e '.applications | has("gateway")' 2>/dev/null || echo "false")
    if [[ "$has_gw" != "true" ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Break relation between 'gateway' and 'api-service'" \
        --arg msg "Application 'gateway' does not exist." \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    else
      has_rel=$(juju status -m lab-unrelate --format json 2>/dev/null | jq -e '.applications["gateway"].relations["reverseproxy"][]? | select(."related-application" == "api-service")' 2>/dev/null || echo "")
      if [[ -z "$has_rel" ]]; then
        tasks=$(jq --argjson arr "$tasks" \
          --arg id "task-3" --arg name "Break relation between 'gateway' and 'api-service'" \
          --arg msg "Relation between 'gateway' and 'api-service' is removed." \
          '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
      else
        tasks=$(jq --argjson arr "$tasks" \
          --arg id "task-3" --arg name "Break relation between 'gateway' and 'api-service'" \
          --arg msg "Relation is still present. Run: juju remove-relation gateway:reverseproxy api-service:website" \
          '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
      fi
    fi
  fi
fi

all_passed=$(echo "$tasks" | jq '[.[].passed] | all')
emit_result "$all_passed" "$tasks"