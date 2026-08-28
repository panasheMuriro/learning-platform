#!/usr/bin/env bash
# Check script for Module 08 Lab 01: Declarative Juju Bundles & Overlays

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
MODEL="mod8-bundle-lab"

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

# Task 2: bundle.yaml created with web-app and db-service
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-2" ]; then
  if [ -f "bundle.yaml" ] && grep -q "web-app:" bundle.yaml && grep -q "db-service:" bundle.yaml; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Create Declarative Bundle Manifest" \
      --arg msg "File 'bundle.yaml' correctly defines web-app and db-service." \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Create Declarative Bundle Manifest" \
      --arg msg "File 'bundle.yaml' missing or does not contain required application definitions." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 3: Both apps deployed in model
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-3" ]; then
  if juju_model_exists "$MODEL"; then
    has_web=$(juju status -m "$MODEL" --format json 2>/dev/null | jq -e '.applications | has("web-app")' 2>/dev/null || echo "false")
    has_db=$(juju status -m "$MODEL" --format json 2>/dev/null | jq -e '.applications | has("db-service")' 2>/dev/null || echo "false")
    if [[ "$has_web" == "true" && "$has_db" == "true" ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Deploy the Bundle Manifest" \
        --arg msg "Applications 'web-app' and 'db-service' are deployed in $MODEL." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Deploy the Bundle Manifest" \
        --arg msg "Applications not fully deployed. Run: juju deploy ./bundle.yaml -m $MODEL" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Deploy the Bundle Manifest" \
      --arg msg "Model '$MODEL' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 4: exported-bundle.yaml exists
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-4" ]; then
  if [ -f "exported-bundle.yaml" ] && grep -q "applications:" exported-bundle.yaml; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-4" --arg name "Export Live Model Topology" \
      --arg msg "File 'exported-bundle.yaml' contains valid exported model bundle." \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-4" --arg name "Export Live Model Topology" \
      --arg msg "File 'exported-bundle.yaml' not found or empty. Run: juju export-bundle --filename exported-bundle.yaml" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

all_passed=$(echo "$tasks" | jq 'all(.[]; .passed == true)')
emit_result "$all_passed" "$tasks"
