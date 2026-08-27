#!/usr/bin/env bash
# Check script for Module 06 Lab 02: Pebble Inspection & Container Workload Simulation

set -euo pipefail

# Dynamic helper resolution
check_helper_candidates=(
  "$(pwd)/.grading/check-helper.sh"
  "$(dirname "$0")/../../shared/check-helper.sh"
  "$(pwd)/content/courses/juju/shared/check-helper.sh"
)

helper_found=0
for cand in "${check_helper_candidates[@]}"; do
  if [ -f "$cand" ]; then
    source "$cand"
    helper_found=1
    break
  fi
done

if [ "$helper_found" -eq 0 ]; then
  echo "Error: check-helper.sh not found" >&2
  exit 1
fi

REQUESTED_TASK="${1:-}"
tasks="[]"

# Task 1: Model 'lab-k8s-pebble' exists
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-1" ]; then
  if ! juju_model_exists "lab-k8s-pebble"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Create model lab-k8s-pebble" \
      --arg msg "Model 'lab-k8s-pebble' does not exist. Run: juju add-model lab-k8s-pebble" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Create model lab-k8s-pebble" \
      --arg msg "Model 'lab-k8s-pebble' exists." \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 2: Workload 'container-app' deployed
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-2" ]; then
  if ! juju_model_exists "lab-k8s-pebble"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Deploy container-app" \
      --arg msg "Model 'lab-k8s-pebble' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  else
    has_app=$(juju status -m lab-k8s-pebble --format json 2>/dev/null | jq -e '.applications | has("container-app")' 2>/dev/null || echo "false")
    if [[ "$has_app" == "true" ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-2" --arg name "Deploy container-app" \
        --arg msg "Application 'container-app' is deployed." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-2" --arg name "Deploy container-app" \
        --arg msg "Application 'container-app' not found. Run: juju deploy ubuntu container-app -m lab-k8s-pebble" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  fi
fi

# Task 3: Marker file /tmp/pebble-sim.ready created on unit
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-3" ]; then
  if ! juju_model_exists "lab-k8s-pebble"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Execute remote command on unit" \
      --arg msg "Model 'lab-k8s-pebble' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  else
    file_exists=$(juju exec -m lab-k8s-pebble --unit container-app/0 "test -f /tmp/pebble-sim.ready && echo ok" 2>/dev/null || echo "no")
    if [[ "$file_exists" == *"ok"* ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Execute remote command on unit" \
        --arg msg "Marker file /tmp/pebble-sim.ready found on container-app/0." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Execute remote command on unit" \
        --arg msg "Marker file not found. Run: juju exec -m lab-k8s-pebble --unit container-app/0 'touch /tmp/pebble-sim.ready'" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  fi
fi

all_passed=$(echo "$tasks" | jq '[.[].passed] | all')
emit_result "$all_passed" "$tasks"
