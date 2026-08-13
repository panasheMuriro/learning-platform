#!/usr/bin/env bash
# check.sh — grading script for Lab 1: Instance Lifecycle

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

# Task 1: Container 'web' exists and is running
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-1" ]; then
  if lxc_instance_running "web"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Launch container" \
      --arg msg "Container 'web' is running" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Launch container" \
      --arg msg "Container 'web' is not running. Run: lxc launch ubuntu:24.04 web" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 2: Resource limits set (limits.cpu=1, limits.memory=256MiB)
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-2" ]; then
  cpu_ok=false
  mem_ok=false
  if lxc_config_equals "web" "limits.cpu" "1"; then cpu_ok=true; fi
  if lxc_config_equals "web" "limits.memory" "256MiB"; then mem_ok=true; fi
  if $cpu_ok && $mem_ok; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Set resource limits" \
      --arg msg "limits.cpu=1 and limits.memory=256MiB are set" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Set resource limits" \
      --arg msg "Limits not set correctly. Run: lxc config set web limits.cpu=1 limits.memory=256MiB" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 3: Shell access works (bash is available inside 'web')
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-3" ]; then
  if lxc exec web -- bash -c 'echo ok' >/dev/null 2>&1; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Shell access" \
      --arg msg "Shell access to 'web' works" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Shell access" \
      --arg msg "Cannot exec into 'web'. Make sure it's running." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 4: Snapshot 'clean' exists
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-4" ]; then
  if lxc_snapshot_exists "web" "clean"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-4" --arg name "Create snapshot" \
      --arg msg "Snapshot 'clean' exists for 'web'" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-4" --arg name "Create snapshot" \
      --arg msg "Snapshot 'clean' not found. Run: lxc snapshot web clean" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 5: Bash is restored (works again after restore)
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-5" ]; then
  if lxc exec web -- bash -c 'echo restored' >/dev/null 2>&1; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-5" --arg name "Break and restore" \
      --arg msg "Bash is available — restore worked" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-5" --arg name "Break and restore" \
      --arg msg "Bash is not available. Run: lxc restore web clean" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

all_passed=$(echo "$tasks" | jq '[.[].passed] | all')
emit_result "$all_passed" "$tasks"
