#!/usr/bin/env bash
# Check script for Module 08 Lab 01: Charm Refresh, Lifecycle & Migration Preparation

set -euo pipefail

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
MODEL="mod8-refresh-lab"

# Task 1: Model exists
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-1" ]; then
  if juju_model_exists "$MODEL"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Create and Switch to Model" \
      --arg msg "Model '$MODEL' exists." \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Create and Switch to Model" \
      --arg msg "Model '$MODEL' not found. Run: juju add-model $MODEL" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 2: service-node deployed
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-2" ]; then
  if juju_model_exists "$MODEL"; then
    has_app=$(juju status -m "$MODEL" --format json 2>/dev/null | jq -e '.applications | has("service-node")' 2>/dev/null || echo "false")
    if [[ "$has_app" == "true" ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-2" --arg name "Deploy Workload Application" \
        --arg msg "Application 'service-node' is deployed." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-2" --arg name "Deploy Workload Application" \
        --arg msg "Application 'service-node' not found. Run: juju deploy ubuntu service-node -m $MODEL" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Deploy Workload Application" \
      --arg msg "Model '$MODEL' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 3: Perform Charm Refresh verified
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-3" ]; then
  if juju_model_exists "$MODEL"; then
    has_app=$(juju status -m "$MODEL" --format json 2>/dev/null | jq -e '.applications | has("service-node")' 2>/dev/null || echo "false")
    if [[ "$has_app" == "true" ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Perform Charm Refresh" \
        --arg msg "Application 'service-node' is ready and refreshed." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Perform Charm Refresh" \
        --arg msg "Application 'service-node' not found in model '$MODEL'." \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Perform Charm Refresh" \
      --arg msg "Model '$MODEL' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 4: Export Live Model Topology Bundle
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-4" ]; then
  if [ -f "live-topology.yaml" ] && grep -q "service-node:" live-topology.yaml; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-4" --arg name "Export Live Model Topology Bundle" \
      --arg msg "File 'live-topology.yaml' contains exported bundle topology." \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-4" --arg name "Export Live Model Topology Bundle" \
      --arg msg "File 'live-topology.yaml' not found or does not contain service-node. Run: juju export-bundle --filename live-topology.yaml" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

all_passed=$(echo "$tasks" | jq 'all(.[]; .passed == true)')
emit_result "$all_passed" "$tasks"
