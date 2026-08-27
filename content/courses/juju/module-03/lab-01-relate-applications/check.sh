#!/usr/bin/env bash
# check.sh — grading script for Lab 1: Relate & Integrate Applications

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

# Task 1: Check model 'lab-relate' exists
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-1" ]; then
  if juju_model_exists "lab-relate"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Create model 'lab-relate'" \
      --arg msg "Model 'lab-relate' exists." \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Create model 'lab-relate'" \
      --arg msg "Model 'lab-relate' not found. Run: juju add-model lab-relate" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 2: Applications 'ingress-proxy' and 'backend-service' deployed
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-2" ]; then
  if ! juju_model_exists "lab-relate"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Deploy 'ingress-proxy' and 'backend-service'" \
      --arg msg "Model 'lab-relate' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  else
    has_ingress=$(juju status -m lab-relate --format json 2>/dev/null | jq -e '.applications | has("ingress-proxy")' 2>/dev/null || echo "false")
    has_backend=$(juju status -m lab-relate --format json 2>/dev/null | jq -e '.applications | has("backend-service")' 2>/dev/null || echo "false")
    if [[ "$has_ingress" == "true" && "$has_backend" == "true" ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-2" --arg name "Deploy 'ingress-proxy' and 'backend-service'" \
        --arg msg "Both 'ingress-proxy' and 'backend-service' are deployed." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-2" --arg name "Deploy 'ingress-proxy' and 'backend-service'" \
        --arg msg "Ensure both applications are deployed: juju deploy haproxy ingress-proxy and juju deploy haproxy backend-service" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  fi
fi

# Task 3: Integration between ingress-proxy:reverseproxy and backend-service:website
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-3" ]; then
  if ! juju_model_exists "lab-relate"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Integrate 'ingress-proxy' with 'backend-service'" \
      --arg msg "Model 'lab-relate' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  else
    has_rel=$(juju status -m lab-relate --format json 2>/dev/null | jq -e '.applications["ingress-proxy"].relations["reverseproxy"][]? | select(."related-application" == "backend-service")' 2>/dev/null || echo "")
    if [[ -n "$has_rel" ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Integrate 'ingress-proxy' with 'backend-service'" \
        --arg msg "Integration established between 'ingress-proxy' and 'backend-service'." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Integrate 'ingress-proxy' with 'backend-service'" \
        --arg msg "Integration not found. Run: juju integrate ingress-proxy:reverseproxy backend-service:website" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  fi
fi

all_passed=$(echo "$tasks" | jq '[.[].passed] | all')
emit_result "$all_passed" "$tasks"