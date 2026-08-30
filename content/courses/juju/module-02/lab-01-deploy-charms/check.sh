#!/usr/bin/env bash
# check.sh — grading script for Lab 1: Deploy Charms from Charmhub

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

# Task 1: Check model 'lab-deploy' exists
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-1" ]; then
  if juju_model_exists "lab-deploy"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Create model 'lab-deploy'" \
      --arg msg "Model 'lab-deploy' exists." \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Create model 'lab-deploy'" \
      --arg msg "Model 'lab-deploy' not found. Run: juju add-model lab-deploy" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 2: Application 'app-server' deployed from ubuntu charm
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-2" ]; then
  if ! juju_model_exists "lab-deploy"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Deploy 'ubuntu' charm as application 'app-server'" \
      --arg msg "Model 'lab-deploy' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  else
    app_exists=$(juju status -m lab-deploy --format json 2>/dev/null | jq -e '.applications | has("app-server")' 2>/dev/null || echo "false")
    charm_name=$(juju status -m lab-deploy --format json 2>/dev/null | jq -r '.applications["app-server"].charm' 2>/dev/null || echo "")
    if [[ "$app_exists" == "true" && "$charm_name" == "ubuntu" ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-2" --arg name "Deploy 'ubuntu' charm as application 'app-server'" \
        --arg msg "Application 'app-server' is deployed using charm 'ubuntu'." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-2" --arg name "Deploy 'ubuntu' charm as application 'app-server'" \
        --arg msg "Application 'app-server' not found with charm 'ubuntu'. Run: juju deploy ubuntu app-server --channel latest/stable" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  fi
fi

# Task 3: Application 'worker-node' deployed from ubuntu charm
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-3" ]; then
  if ! juju_model_exists "lab-deploy"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Deploy a second instance as 'worker-node'" \
      --arg msg "Model 'lab-deploy' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  else
    app_exists=$(juju status -m lab-deploy --format json 2>/dev/null | jq -e '.applications | has("worker-node")' 2>/dev/null || echo "false")
    charm_name=$(juju status -m lab-deploy --format json 2>/dev/null | jq -r '.applications["worker-node"].charm' 2>/dev/null || echo "")
    if [[ "$app_exists" == "true" && "$charm_name" == "ubuntu" ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Deploy a second instance as 'worker-node'" \
        --arg msg "Application 'worker-node' is deployed using charm 'ubuntu'." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Deploy a second instance as 'worker-node'" \
        --arg msg "Application 'worker-node' not found with charm 'ubuntu'. Run: juju deploy ubuntu worker-node --channel latest/stable" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  fi
fi

all_passed=$(echo "$tasks" | jq '[.[].passed] | all')
emit_result "$all_passed" "$tasks"