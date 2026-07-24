#!/usr/bin/env bash
# check.sh — grading script for Lab 3: Plan/Apply/Destroy Lifecycle
#
# This lab is about practicing the lifecycle. The check verifies:
# 1. terraform init was run
# 2. State was created at some point (state file exists)
# 3. The config is valid (terraform validate)
# 4. The learner has destroyed their resources (state should be empty or model gone)
#
# Note: This lab is more about the journey than the end state.

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

# Task 1: terraform init succeeded
if [ -d ".terraform" ]; then
  tasks=$(jq --argjson arr "$tasks" --arg id "task-1" --arg name "terraform init" --arg msg "Provider initialized (.terraform/ exists)" '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
else
  tasks=$(jq --argjson arr "$tasks" --arg id "task-1" --arg name "terraform init" --arg msg "Run 'terraform init' first" '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
fi

# Task 2: terraform.tfstate file exists (proves apply was run at some point)
if [ -f "terraform.tfstate" ]; then
  tasks=$(jq --argjson arr "$tasks" --arg id "task-2" --arg name "terraform apply" --arg msg "State file exists — apply was run" '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
else
  tasks=$(jq --argjson arr "$tasks" --arg id "task-2" --arg name "terraform apply" --arg msg "No terraform.tfstate file. Run 'terraform apply'." '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
fi

# Task 3: Config is valid
if output=$(terraform validate 2>&1); then
  tasks=$(jq --argjson arr "$tasks" --arg id "task-3" --arg name "Config valid" --arg msg "terraform validate passed" '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
else
  tasks=$(jq --argjson arr "$tasks" --arg id "task-3" --arg name "Config valid" --arg msg "terraform validate failed: ${output}" '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
fi

# Task 4: State has been cleaned up (destroy was run)
# After destroy, state should have 0 resources
state_count=$(terraform state list 2>/dev/null | wc -l || echo "0")
if [ "$state_count" -eq 0 ]; then
  tasks=$(jq --argjson arr "$tasks" --arg id "task-4" --arg name "terraform destroy" --arg msg "State is empty — destroy was run successfully" '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
else
  tasks=$(jq --argjson arr "$tasks" --arg id "task-4" --arg name "terraform destroy" --arg msg "State still has ${state_count} resources. Run 'terraform destroy'." '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
fi

# Task 5: The lab-03 model no longer exists in Juju (proves cleanup)
if ! juju show-model lab-03 >/dev/null 2>&1; then
  tasks=$(jq --argjson arr "$tasks" --arg id "task-5" --arg name "Model cleaned up" --arg msg "Model 'lab-03' no longer exists in Juju" '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
else
  tasks=$(jq --argjson arr "$tasks" --arg id "task-5" --arg name "Model cleaned up" --arg msg "Model 'lab-03' still exists. Run 'terraform destroy'." '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
fi

all_pass=$(echo "$tasks" | jq '[.[].passed] | all')
emit_result "$all_pass" "$tasks"
