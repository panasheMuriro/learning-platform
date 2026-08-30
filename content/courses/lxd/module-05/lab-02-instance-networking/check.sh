#!/usr/bin/env bash
# check.sh — grading script for Lab: Instance Networking

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

# Task 1: Instance 'net-app' exists and is running
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-1" ]; then
  if lxc_instance_running "net-app" 2>/dev/null; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "View network devices" \
      --arg msg "Instance 'net-app' is running" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "View network devices" \
      --arg msg "Instance 'net-app' is not running. Run: lxc launch ubuntu:24.04 net-app" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 2: Instance 'net-app' has eth1 device
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-2" ]; then
  if lxc config device show net-app 2>/dev/null | grep -q 'eth1:'; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Add second NIC" \
      --arg msg "Instance 'net-app' has eth1 device" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Add second NIC" \
      --arg msg "eth1 not found. Run: lxc config device add net-app eth1 nic network=lxdbr0" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 3: Instance can ping 8.8.8.8 (internet connectivity)
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-3" ]; then
  if lxc exec net-app -- ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Test connectivity" \
      --arg msg "Instance 'net-app' can reach the internet (ping 8.8.8.8 succeeded)" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Test connectivity" \
      --arg msg "Cannot ping 8.8.8.8 from 'net-app'. Check the network and NAT settings." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

all_passed=$(echo "$tasks" | jq '[.[].passed] | all')
emit_result "$all_passed" "$tasks"
