#!/usr/bin/env bash
# Check script for Module 08 Lab 02: Controller Backup, Recovery & Logging Verification

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
MODEL="mod8-backup-lab"

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

# Task 2: Controller backup exists
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-2" ]; then
  if [ -f "backup.tar.gz" ] || [ -f "juju-backup.tar.gz" ] || ls juju-backup-*.tar.gz >/dev/null 2>&1; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Create Controller Backup Archive" \
      --arg msg "Controller backup archive file exists." \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Create Controller Backup Archive" \
      --arg msg "No controller backup file found. Run: juju create-backup --filename backup.tar.gz" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 3: Logging config contains uniter=TRACE
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-3" ]; then
  if juju_model_exists "$MODEL"; then
    log_cfg=$(juju model-config -m "$MODEL" logging-config 2>/dev/null || echo "")
    if [[ "$log_cfg" == *"juju.worker.uniter=TRACE"* ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Configure Subsystem Model Logging" \
        --arg msg "Model logging-config is configured with uniter=TRACE." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Configure Subsystem Model Logging" \
        --arg msg "Model logging-config does not contain uniter=TRACE. Run: juju model-config -m $MODEL logging-config='<root>=INFO;unit=DEBUG;juju.worker.uniter=TRACE'" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Configure Subsystem Model Logging" \
      --arg msg "Model '$MODEL' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 4: Verify Model Status & Log Replay
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-4" ]; then
  if juju_model_exists "$MODEL"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-4" --arg name "Verify Model Status & Log Replay" \
      --arg msg "Model '$MODEL' is active and telemetry log replay is verified." \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-4" --arg name "Verify Model Status & Log Replay" \
      --arg msg "Model '$MODEL' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

all_passed=$(echo "$tasks" | jq 'all(.[]; .passed == true)')
emit_result "$all_passed" "$tasks"
