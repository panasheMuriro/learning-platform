#!/usr/bin/env bash
# check.sh — grading script for Lab 2: Variables & Outputs

set -euo pipefail

# Source the shared helper — try multiple paths to work from both the content
# repo and the lab working directory (where the backend copies check.sh)
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

# Task 1: variables.tf exists and has the required variables
if [ -f "variables.tf" ] && grep -q 'variable.*"model_name"' variables.tf && grep -q 'variable.*"charm_name"' variables.tf && grep -q 'variable.*"unit_count"' variables.tf; then
  tasks=$(jq --argjson arr "$tasks" --arg id "task-1" --arg name "Define variables" --arg msg "All required variables found in variables.tf" '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
else
  tasks=$(jq --argjson arr "$tasks" --arg id "task-1" --arg name "Define variables" --arg msg "Missing required variables in variables.tf (need model_name, charm_name, unit_count)" '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
fi

# Task 2: main.tf uses variables (var.model_name, var.charm_name)
if grep -q 'var\.model_name' main.tf 2>/dev/null && grep -q 'var\.charm_name' main.tf 2>/dev/null; then
  tasks=$(jq --argjson arr "$tasks" --arg id "task-2" --arg name "Use variables in main.tf" --arg msg "Variables are referenced in main.tf" '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
else
  tasks=$(jq --argjson arr "$tasks" --arg id "task-2" --arg name "Use variables in main.tf" --arg msg "main.tf should reference var.model_name and var.charm_name" '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
fi

# Task 3: outputs.tf exists and has required outputs
if [ -f "outputs.tf" ] && grep -q 'output.*"model_uuid"' outputs.tf && grep -q 'output.*"app_name"' outputs.tf; then
  tasks=$(jq --argjson arr "$tasks" --arg id "task-3" --arg name "Define outputs" --arg msg "Required outputs found in outputs.tf" '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
else
  tasks=$(jq --argjson arr "$tasks" --arg id "task-3" --arg name "Define outputs" --arg msg "Missing required outputs (need model_uuid, app_name)" '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
fi

# Task 4: terraform init succeeded
if [ -d ".terraform" ]; then
  tasks=$(jq --argjson arr "$tasks" --arg id "task-4" --arg name "terraform init" --arg msg "Provider initialized" '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
else
  tasks=$(jq --argjson arr "$tasks" --arg id "task-4" --arg name "terraform init" --arg msg "Run 'terraform init' first" '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
fi

# Task 5: Model exists in state
if tf_state_has "juju_model" "lab"; then
  tasks=$(jq --argjson arr "$tasks" --arg id "task-5" --arg name "Model created" --arg msg "juju_model.lab exists in state" '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
else
  tasks=$(jq --argjson arr "$tasks" --arg id "task-5" --arg name "Model created" --arg msg "juju_model.lab not in state. Run 'terraform apply'." '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
fi

# Task 6: Application exists in state
if tf_state_has "juju_application" "app"; then
  tasks=$(jq --argjson arr "$tasks" --arg id "task-6" --arg name "Application deployed" --arg msg "juju_application.app exists in state" '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
else
  tasks=$(jq --argjson arr "$tasks" --arg id "task-6" --arg name "Application deployed" --arg msg "juju_application.app not in state. Run 'terraform apply'." '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
fi

# Task 7: terraform output works and returns model_name
if output=$(terraform output model_name 2>/dev/null); then
  tasks=$(jq --argjson arr "$tasks" --arg id "task-7" --arg name "Outputs work" --arg msg "terraform output model_name returns: ${output}" '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
else
  tasks=$(jq --argjson arr "$tasks" --arg id "task-7" --arg name "Outputs work" --arg msg "terraform output model_name failed. Define outputs and apply." '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
fi

all_pass=$(echo "$tasks" | jq '[.[].passed] | all')
emit_result "$all_pass" "$tasks"
