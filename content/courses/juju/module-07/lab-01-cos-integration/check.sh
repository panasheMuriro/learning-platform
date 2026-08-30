#!/usr/bin/env bash
# Check script for Module 07 Lab 01: COS Machine Telemetry & Subsystem Logging

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
MODEL="mod7-cos-lab"

# Task 1: Model exists
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-1" ]; then
  if juju_model_exists "$MODEL"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Create and Switch to Lab Model" \
      --arg msg "Model '$MODEL' exists." \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Create and Switch to Lab Model" \
      --arg msg "Model '$MODEL' not found. Run: juju add-model $MODEL" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 2: Logging config has uniter=TRACE
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-2" ]; then
  if juju_model_exists "$MODEL"; then
    log_cfg=$(juju model-config -m "$MODEL" logging-config 2>/dev/null || echo "")
    if [[ "$log_cfg" == *"juju.worker.uniter=TRACE"* ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-2" --arg name "Configure Subsystem Model Logging" \
        --arg msg "Model logging-config is configured with uniter=TRACE." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-2" --arg name "Configure Subsystem Model Logging" \
        --arg msg "Model logging-config does not contain uniter=TRACE. Run: juju model-config -m $MODEL logging-config='<root>=INFO;unit=DEBUG;juju.worker.uniter=TRACE'" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Configure Subsystem Model Logging" \
      --arg msg "Model '$MODEL' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 3: web-app deployed
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-3" ]; then
  if juju_model_exists "$MODEL"; then
    has_app=$(juju status -m "$MODEL" --format json 2>/dev/null | jq -e '.applications | has("web-app")' 2>/dev/null || echo "false")
    if [[ "$has_app" == "true" ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Deploy Workload Application" \
        --arg msg "Application 'web-app' is deployed." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Deploy Workload Application" \
        --arg msg "Application 'web-app' not found. Run: juju deploy ubuntu web-app -m $MODEL" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Deploy Workload Application" \
      --arg msg "Model '$MODEL' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 4: grafana-agent deployed
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-4" ]; then
  if juju_model_exists "$MODEL"; then
    has_app=$(juju status -m "$MODEL" --format json 2>/dev/null | jq -e '.applications | has("grafana-agent")' 2>/dev/null || echo "false")
    if [[ "$has_app" == "true" ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-4" --arg name "Deploy Grafana Agent Subordinate" \
        --arg msg "Application 'grafana-agent' is deployed." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-4" --arg name "Deploy Grafana Agent Subordinate" \
        --arg msg "Application 'grafana-agent' not found. Run: juju deploy grafana-agent -m $MODEL" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-4" --arg name "Deploy Grafana Agent Subordinate" \
      --arg msg "Model '$MODEL' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 5: Relation between web-app and grafana-agent
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-5" ]; then
  if juju_model_exists "$MODEL"; then
    has_rel=$(juju status -m "$MODEL" --format json 2>/dev/null | jq -e '[.relations // {} | to_entries[] | select((.value.endpoints[]?.application == "web-app") and (.value.endpoints[]?.application == "grafana-agent"))] | length > 0' 2>/dev/null || echo "false")
    if [[ "$has_rel" == "true" ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-5" --arg name "Integrate Workload with Grafana Agent" \
        --arg msg "Relation between web-app and grafana-agent is active." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-5" --arg name "Integrate Workload with Grafana Agent" \
        --arg msg "Relation between web-app and grafana-agent not found. Run: juju integrate web-app:cos-agent grafana-agent:cos-agent -m $MODEL" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-5" --arg name "Integrate Workload with Grafana Agent" \
      --arg msg "Model '$MODEL' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

all_passed=$(echo "$tasks" | jq 'all(.[]; .passed == true)')
emit_result "$all_passed" "$tasks"

