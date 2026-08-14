#!/usr/bin/env bash
# check.sh — grading script for Lab: Create & Configure Instances

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

# Task 2: Resource limits set
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

# Task 3: Commands run inside container
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-3" ]; then
  if lxc exec web -- nproc >/dev/null 2>&1; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Verify limits" \
      --arg msg "Commands run successfully inside 'web'" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Verify limits" \
      --arg msg "Cannot exec into 'web'. Make sure it's running." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

all_passed=$(echo "$tasks" | jq '[.[].passed] | all')
emit_result "$all_passed" "$tasks"
