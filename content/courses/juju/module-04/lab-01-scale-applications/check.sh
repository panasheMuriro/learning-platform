#!/usr/bin/env bash
# Check script for Module 04 Lab 01: Scale Applications & Units

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

# Task 1: Model 'lab-scale' exists and 'worker' deployed
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-1" ]; then
  if ! juju_model_exists "lab-scale"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Create model and deploy worker application" \
      --arg msg "Model 'lab-scale' does not exist. Run: juju add-model lab-scale" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  else
    has_worker=$(juju status -m lab-scale --format json 2>/dev/null | jq -e '.applications | has("worker")' 2>/dev/null || echo "false")
    if [[ "$has_worker" == "true" ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-1" --arg name "Create model and deploy worker application" \
        --arg msg "Model 'lab-scale' and application 'worker' exist." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-1" --arg name "Create model and deploy worker application" \
        --arg msg "Application 'worker' not found in model 'lab-scale'. Run: juju deploy ubuntu worker -m lab-scale" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  fi
fi

# Task 2: Scale worker out
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-2" ]; then
  if ! juju_model_exists "lab-scale"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Scale worker out" \
      --arg msg "Model 'lab-scale' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  else
    unit_count=$(juju status -m lab-scale --format json 2>/dev/null | jq -r '.applications.worker.units // {} | keys | length' 2>/dev/null || echo "0")
    if [ "$unit_count" -ge 2 ]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-2" --arg name "Scale worker out" \
        --arg msg "Application 'worker' has multiple units ($unit_count units present)." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-2" --arg name "Scale worker out" \
        --arg msg "Worker has not been scaled out. Run: juju add-unit worker -n 2 -m lab-scale" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  fi
fi

# Task 3: Scale worker in
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-3" ]; then
  if ! juju_model_exists "lab-scale"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Scale worker in" \
      --arg msg "Model 'lab-scale' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  else
    unit_count=$(juju status -m lab-scale --format json 2>/dev/null | jq -r '.applications.worker.units // {} | keys | length' 2>/dev/null || echo "0")
    has_unit_2=$(juju status -m lab-scale --format json 2>/dev/null | jq -e '.applications.worker.units["worker/2"]' >/dev/null 2>&1 && echo "yes" || echo "no")
    if [ "$unit_count" -eq 2 ] && [ "$has_unit_2" = "no" ]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Scale worker in" \
        --arg msg "Worker has exactly 2 units and worker/2 was removed." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Scale worker in" \
        --arg msg "Remove unit worker/2: juju remove-unit worker/2 -m lab-scale" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  fi
fi

all_passed=$(echo "$tasks" | jq '[.[].passed] | all')
emit_result "$all_passed" "$tasks"
