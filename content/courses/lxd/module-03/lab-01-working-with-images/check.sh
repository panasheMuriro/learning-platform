#!/usr/bin/env bash
# check.sh — grading script for Lab 1: Working with Images

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

# Task 1: lxc image list ubuntu: works (we can't verify output, but check the command runs)
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-1" ]; then
  if lxc image list ubuntu: >/dev/null 2>&1; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "List remote images" \
      --arg msg "lxc image list ubuntu: works" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "List remote images" \
      --arg msg "Failed to list ubuntu: images. Check your network connection." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 2: Container 'app' exists and is running
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-2" ]; then
  if lxc_instance_running "app"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Launch from specific image" \
      --arg msg "Container 'app' is running" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Launch from specific image" \
      --arg msg "Container 'app' is not running. Run: lxc launch ubuntu:24.04 app" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 3: At least one local image exists
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-3" ]; then
  count=$(lxc image list --format csv 2>/dev/null | wc -l)
  if [ "$count" -gt 0 ]; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "List local images" \
      --arg msg "Found ${count} local image(s)" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "List local images" \
      --arg msg "No local images found. Launch a container first: lxc launch ubuntu:24.04 app" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 4: Custom image with alias 'my-app' exists
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-4" ]; then
  if lxc_image_alias_exists "my-app"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-4" --arg name "Publish custom image" \
      --arg msg "Image alias 'my-app' exists" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-4" --arg name "Publish custom image" \
      --arg msg "Image 'my-app' not found. Run: lxc stop app && lxc publish app --alias my-app" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 5: Container 'app-clone' exists and is running
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-5" ]; then
  if lxc_instance_running "app-clone"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-5" --arg name "Launch from custom image" \
      --arg msg "Container 'app-clone' is running from custom image" \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-5" --arg name "Launch from custom image" \
      --arg msg "Container 'app-clone' is not running. Run: lxc launch my-app app-clone" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

all_passed=$(echo "$tasks" | jq '[.[].passed] | all')
emit_result "$all_passed" "$tasks"
