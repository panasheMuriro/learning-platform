#!/usr/bin/env bash
# check.sh — grading script for Lab: Custom Volumes

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

# Task 1: Custom volume 'shared-data' exists in default pool
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-1" ]; then
  if lxc storage volume show default shared-data >/dev/null 2>&1; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Create custom volume" \
      --arg msg "Custom volume 'shared-data' exists in 'default' pool" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Create custom volume" \
      --arg msg "Volume 'shared-data' not found. Run: lxc storage volume create default shared-data size=1GiB" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 2: Container 'data-app' exists, running, and has test.txt on the volume
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-2" ]; then
  if lxc_instance_running "data-app" 2>/dev/null; then
    content=$(lxc exec data-app -- cat /mnt/data/test.txt 2>/dev/null || true)
    if echo "$content" | grep -q "hello from shared volume" 2>/dev/null; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-2" --arg name "Attach and write data" \
        --arg msg "Container 'data-app' has test.txt on the attached volume" \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-2" --arg name "Attach and write data" \
        --arg msg "test.txt not found or wrong content. Attach the volume and write the file." \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Attach and write data" \
      --arg msg "Container 'data-app' is not running. Run: lxc launch ubuntu:24.04 data-app" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 3: Container 'data-app-2' exists and can read the file from the volume
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-3" ]; then
  if lxc_instance_running "data-app-2" 2>/dev/null; then
    content=$(lxc exec data-app-2 -- cat /mnt/data/test.txt 2>/dev/null || true)
    if echo "$content" | grep -q "hello from shared volume" 2>/dev/null; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Data persists" \
        --arg msg "Data survived instance deletion — file is readable in 'data-app-2'" \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Data persists" \
        --arg msg "File not found in 'data-app-2'. Attach the volume: lxc storage volume attach default shared-data data-app-2 /mnt/data" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Data persists" \
      --arg msg "Container 'data-app-2' is not running. Run: lxc launch ubuntu:24.04 data-app-2" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

all_passed=$(echo "$tasks" | jq '[.[].passed] | all')
emit_result "$all_passed" "$tasks"
