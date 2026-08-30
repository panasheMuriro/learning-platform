#!/usr/bin/env bash
# check.sh — grading script for Lab: Explore Storage Pools

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

# Task 1: lxc storage list works (at least one pool exists)
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-1" ]; then
  count=$(lxc storage list --format csv 2>/dev/null | wc -l)
  if [ "$count" -gt 0 ]; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "List storage pools" \
      --arg msg "Found ${count} storage pool(s)" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "List storage pools" \
      --arg msg "No storage pools found. Run: lxd init --minimal" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 2: Pool 'fast-pool' exists
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-2" ]; then
  if lxc storage show fast-pool >/dev/null 2>&1; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Create directory pool" \
      --arg msg "Storage pool 'fast-pool' exists" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Create directory pool" \
      --arg msg "Pool 'fast-pool' not found. Run: lxc storage create fast-pool dir" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 3: Instance 'storage-test' exists and is on fast-pool
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-3" ]; then
  if lxc_instance_running "storage-test"; then
    pool=$(lxc config device show storage-test 2>/dev/null | grep -A2 'root:' | grep 'pool:' | awk '{print $2}' || true)
    if [ "$pool" = "fast-pool" ]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Launch on new pool" \
        --arg msg "Instance 'storage-test' is running on 'fast-pool'" \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Launch on new pool" \
        --arg msg "Instance 'storage-test' is running but not on 'fast-pool'. Run: lxc launch ubuntu:24.04 storage-test --storage fast-pool" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Launch on new pool" \
      --arg msg "Instance 'storage-test' is not running. Run: lxc launch ubuntu:24.04 storage-test --storage fast-pool" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

all_passed=$(echo "$tasks" | jq '[.[].passed] | all')
emit_result "$all_passed" "$tasks"
