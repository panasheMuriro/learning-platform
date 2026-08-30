#!/usr/bin/env bash
# Check script for Module 06 Lab 01: Kubernetes Cloud Registration & Model Provisioning

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

# Task 1: Model 'lab-k8s-cloud' exists
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-1" ]; then
  if ! juju_model_exists "lab-k8s-cloud"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Create model lab-k8s-cloud" \
      --arg msg "Model 'lab-k8s-cloud' does not exist. Run: juju add-model lab-k8s-cloud" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Create model lab-k8s-cloud" \
      --arg msg "Model 'lab-k8s-cloud' exists." \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 2: Workload 'k8s-sim' deployed
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-2" ]; then
  if ! juju_model_exists "lab-k8s-cloud"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Deploy workload application" \
      --arg msg "Model 'lab-k8s-cloud' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  else
    has_app=$(juju status -m lab-k8s-cloud --format json 2>/dev/null | jq -e '.applications | has("k8s-sim")' 2>/dev/null || echo "false")
    if [[ "$has_app" == "true" ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-2" --arg name "Deploy workload application" \
        --arg msg "Application 'k8s-sim' is deployed." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-2" --arg name "Deploy workload application" \
        --arg msg "Application 'k8s-sim' not found. Run: juju deploy ubuntu k8s-sim -m lab-k8s-cloud" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  fi
fi

# Task 3: Model logging-config set to include DEBUG
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-3" ]; then
  if ! juju_model_exists "lab-k8s-cloud"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Configure model logging level" \
      --arg msg "Model 'lab-k8s-cloud' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  else
    log_cfg=$(juju model-config -m lab-k8s-cloud --format json 2>/dev/null | jq -r '."logging-config".Value // ."logging-config".value // empty' 2>/dev/null || echo "")
    if [[ "$log_cfg" == *"DEBUG"* ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Configure model logging level" \
        --arg msg "Model logging-config is set to: $log_cfg." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Configure model logging level" \
        --arg msg "Model logging-config does not contain DEBUG. Run: juju model-config -m lab-k8s-cloud logging-config='<root>=DEBUG'" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  fi
fi

all_passed=$(echo "$tasks" | jq '[.[].passed] | all')
emit_result "$all_passed" "$tasks"
