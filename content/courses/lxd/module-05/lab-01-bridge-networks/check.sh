#!/usr/bin/env bash
# check.sh — grading script for Lab: Bridge Networks

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

# Task 1: lxc network list works (at least one network exists)
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-1" ]; then
  count=$(lxc network list --format csv 2>/dev/null | wc -l)
  if [ "$count" -gt 0 ]; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "List networks" \
      --arg msg "Found ${count} network(s)" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "List networks" \
      --arg msg "No networks found. Run: lxd init --minimal" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 2: Network 'test-bridge' exists
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-2" ]; then
  if lxc network show test-bridge >/dev/null 2>&1; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Create bridge" \
      --arg msg "Network 'test-bridge' exists" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Create bridge" \
      --arg msg "Network 'test-bridge' not found. Run: lxc network create test-bridge --type=bridge ipv4.address=10.20.20.1/24 ipv4.nat=true" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 3: Instance 'net-test' exists, running, and on test-bridge
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-3" ]; then
  if lxc_instance_running "net-test" 2>/dev/null; then
    network=$(lxc config device show net-test 2>/dev/null | grep -A5 'eth0:' | grep 'network:' | awk '{print $2}' || true)
    if [ "$network" = "test-bridge" ]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Launch on new network" \
        --arg msg "Instance 'net-test' is running on 'test-bridge'" \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Launch on new network" \
        --arg msg "Instance 'net-test' is running but not on 'test-bridge'. Run: lxc config device set net-test eth0 network=test-bridge && lxc restart net-test" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Launch on new network" \
      --arg msg "Instance 'net-test' is not running. Run: lxc launch ubuntu:24.04 net-test" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

all_passed=$(echo "$tasks" | jq '[.[].passed] | all')
emit_result "$all_passed" "$tasks"
