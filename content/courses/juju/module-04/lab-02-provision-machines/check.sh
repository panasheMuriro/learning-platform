#!/usr/bin/env bash
# Check script for Module 04 Lab 02: Machine Provisioning & Placement

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

# Task 1: Model 'lab-machines' exists
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-1" ]; then
  if ! juju_model_exists "lab-machines"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Create model lab-machines" \
      --arg msg "Model 'lab-machines' does not exist. Run: juju add-model lab-machines" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Create model lab-machines" \
      --arg msg "Model 'lab-machines' exists." \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 2: Standalone machine 0 provisioned
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-2" ]; then
  if ! juju_model_exists "lab-machines"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Provision standalone machine" \
      --arg msg "Model 'lab-machines' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  else
    has_m0=$(juju machines -m lab-machines --format json 2>/dev/null | jq -e '.machines["0"]' >/dev/null 2>&1 && echo "yes" || echo "no")
    if [[ "$has_m0" == "yes" ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-2" --arg name "Provision standalone machine" \
        --arg msg "Machine 0 is provisioned in model 'lab-machines'." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-2" --arg name "Provision standalone machine" \
        --arg msg "Machine 0 not found. Run: juju add-machine -m lab-machines" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  fi
fi

# Task 3: Deploy 'custom-node' targeted to machine 0
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-3" ]; then
  if ! juju_model_exists "lab-machines"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Deploy application with placement directive" \
      --arg msg "Model 'lab-machines' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  else
    unit_machine=$(juju status -m lab-machines --format json 2>/dev/null | jq -r '.applications["custom-node"].units["custom-node/0"].machine // empty' 2>/dev/null || echo "")
    if [[ "$unit_machine" == "0" ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Deploy application with placement directive" \
        --arg msg "Application 'custom-node' unit 0 is placed on machine 0." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Deploy application with placement directive" \
        --arg msg "Deploy custom-node to machine 0: juju deploy ubuntu custom-node --to 0 -m lab-machines" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  fi
fi

all_passed=$(echo "$tasks" | jq '[.[].passed] | all')
emit_result "$all_passed" "$tasks"
