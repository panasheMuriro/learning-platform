#!/usr/bin/env bash
# check.sh — grading script for Lab 2: Files & Backups

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

# Task 1: helloworld.txt exists inside 'web'
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-1" ]; then
  if lxc exec web -- test -f /root/helloworld.txt 2>/dev/null; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Create file inside container" \
      --arg msg "helloworld.txt exists inside 'web'" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Create file inside container" \
      --arg msg "helloworld.txt not found. Run: lxc exec web -- touch /root/helloworld.txt" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 2: helloworld.txt exists on the host with content
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-2" ]; then
  if [ -f "helloworld.txt" ] && grep -q "Hello world" helloworld.txt 2>/dev/null; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Pull and modify file" \
      --arg msg "helloworld.txt on host contains 'Hello world'" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Pull and modify file" \
      --arg msg "helloworld.txt not found or empty on host. Run: lxc file pull web/root/helloworld.txt . && echo 'Hello world' > helloworld.txt" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 3: helloworld.txt inside 'web' contains 'Hello world'
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-3" ]; then
  content=$(lxc exec web -- cat /root/helloworld.txt 2>/dev/null || true)
  if echo "$content" | grep -q "Hello world" 2>/dev/null; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Push file back" \
      --arg msg "helloworld.txt inside 'web' contains 'Hello world'" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Push file back" \
      --arg msg "File not pushed or wrong content. Run: lxc file push helloworld.txt web/root/helloworld.txt" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 4: Snapshot 'backup' exists
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-4" ]; then
  if lxc_snapshot_exists "web" "backup"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-4" --arg name "Create snapshot" \
      --arg msg "Snapshot 'backup' exists for 'web'" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-4" --arg name "Create snapshot" \
      --arg msg "Snapshot 'backup' not found. Run: lxc snapshot web backup" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 5: File restored after snapshot restore
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-5" ]; then
  content=$(lxc exec web -- cat /root/helloworld.txt 2>/dev/null || true)
  if echo "$content" | grep -q "Hello world" 2>/dev/null; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-5" --arg name "Delete and restore" \
      --arg msg "File restored from snapshot — helloworld.txt is back" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-5" --arg name "Delete and restore" \
      --arg msg "File not restored. Run: lxc restore web backup" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

all_passed=$(echo "$tasks" | jq '[.[].passed] | all')
emit_result "$all_passed" "$tasks"
