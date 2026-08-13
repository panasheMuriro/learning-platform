#!/usr/bin/env bash
# check.sh — grading script for Lab 1: Install, Initialize & Launch
#
# Runs lxc commands and emits a JSON result.
# Usage:
#   ./check.sh          # grade all tasks
#   ./check.sh task-1   # grade only task-1

set -euo pipefail

REQUESTED_TASK="${1:-}"

# Source the shared helper
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

# Task 1: LXD is installed
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-1" ]; then
  if command -v lxd >/dev/null 2>&1 && lxd --version >/dev/null 2>&1; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" \
      --arg name "LXD installed" \
      --arg msg "LXD $(lxd --version 2>/dev/null | head -1) is installed" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" \
      --arg name "LXD installed" \
      --arg msg "LXD is not installed. Run: sudo snap install lxd" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 2: LXD is initialized (lxc list works without error)
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-2" ]; then
  if lxc list >/dev/null 2>&1; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" \
      --arg name "LXD initialized" \
      --arg msg "LXD is initialized and lxc list works" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" \
      --arg name "LXD initialized" \
      --arg msg "LXD is not initialized. Run: lxd init --minimal" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 3: Container 'first' exists and is running
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-3" ]; then
  if lxc_instance_running "first"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" \
      --arg name "Launch first container" \
      --arg msg "Container 'first' is running" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" \
      --arg name "Launch first container" \
      --arg msg "Container 'first' is not running. Run: lxc launch ubuntu:24.04 first" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 4: Container 'second' exists (created with lxc init)
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-4" ]; then
  if lxc_instance_exists "second"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-4" \
      --arg name "Create stopped container" \
      --arg msg "Container 'second' exists" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-4" \
      --arg name "Create stopped container" \
      --arg msg "Container 'second' does not exist. Run: lxc init ubuntu:24.04 second" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 5: Container 'second' is running (started by the learner)
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-5" ]; then
  if lxc_instance_running "second"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-5" \
      --arg name "Start and inspect" \
      --arg msg "Container 'second' is running" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-5" \
      --arg name "Start and inspect" \
      --arg msg "Container 'second' is not running. Run: lxc start second" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Determine overall pass
all_passed=$(echo "$tasks" | jq '[.[].passed] | all')
emit_result "$all_passed" "$tasks"
