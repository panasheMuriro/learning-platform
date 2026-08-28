#!/usr/bin/env bash
# Check script for Module 08 Lab 02: Terraform Juju Provider IaC Workflow

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
MODEL="tf-iac-lab"

# Task 1: main.tf defines juju_model
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-1" ]; then
  if [ -f "main.tf" ] && grep -q 'resource "juju_model"' main.tf; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Author Terraform HCL Configuration" \
      --arg msg "File 'main.tf' contains juju_model resource definition." \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Author Terraform HCL Configuration" \
      --arg msg "File 'main.tf' missing or does not contain 'resource \"juju_model\"'." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 2: main.tf defines juju_application frontend
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-2" ]; then
  if [ -f "main.tf" ] && grep -q 'resource "juju_application"' main.tf && grep -q 'frontend' main.tf; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Declare Application Resource in HCL" \
      --arg msg "File 'main.tf' declares juju_application for frontend." \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Declare Application Resource in HCL" \
      --arg msg "File 'main.tf' missing 'resource \"juju_application\" \"frontend\"'." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 3: Model and application exist in Juju
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-3" ]; then
  if juju_model_exists "$MODEL"; then
    has_app=$(juju status -m "$MODEL" --format json 2>/dev/null | jq -e '.applications | has("frontend")' 2>/dev/null || echo "false")
    if [[ "$has_app" == "true" ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Provision Model and Application" \
        --arg msg "Model '$MODEL' and application 'frontend' are provisioned." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Provision Model and Application" \
        --arg msg "Application 'frontend' not found in model '$MODEL'. Run: juju deploy ubuntu frontend -m $MODEL" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Provision Model and Application" \
      --arg msg "Model '$MODEL' not found. Run: juju add-model $MODEL" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

all_passed=$(echo "$tasks" | jq 'all(.[]; .passed == true)')
emit_result "$all_passed" "$tasks"
