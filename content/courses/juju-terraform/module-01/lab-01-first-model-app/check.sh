#!/usr/bin/env bash
# check.sh — grading script for Lab 1: First Model + Application
#
# Runs real terraform/juju commands and emits a JSON result.
# The backend parses this output to record progress.
#
# Usage: ./check.sh

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

# Task 1: Provider is configured
if grep -q 'source.*=.*"juju/juju"' main.tf 2>/dev/null; then
  tasks=$(jq --argjson arr "$tasks" \
    --arg id "task-1" \
    --arg name "Provider configured" \
    --arg msg "Juju provider found in main.tf" \
    '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
else
  tasks=$(jq --argjson arr "$tasks" \
    --arg id "task-1" \
    --arg name "Provider configured" \
    --arg msg "Juju provider not found in main.tf" \
    '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
fi

# Task 2: terraform init succeeded (check .terraform dir exists)
if [ -d ".terraform" ]; then
  tasks=$(jq --argjson arr "$tasks" \
    --arg id "task-2" \
    --arg name "terraform init" \
    --arg msg "Provider initialized" \
    '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
else
  tasks=$(jq --argjson arr "$tasks" \
    --arg id "task-2" \
    --arg name "terraform init" \
    --arg msg "Run 'terraform init' first" \
    '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
fi

# Task 3: juju_model resource exists in state
if tf_state_has "juju_model" "development"; then
  tasks=$(jq --argjson arr "$tasks" \
    --arg id "task-3" \
    --arg name "Create juju_model" \
    --arg msg "Model 'development' exists in state" \
    '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
else
  tasks=$(jq --argjson arr "$tasks" \
    --arg id "task-3" \
    --arg name "Create juju_model" \
    --arg msg "Model 'development' not in state. Run 'terraform apply'." \
    '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
fi

# Task 4: juju_application resource exists in state
if tf_state_has "juju_application" "ubuntu"; then
  tasks=$(jq --argjson arr "$tasks" \
    --arg id "task-4" \
    --arg name "Deploy ubuntu charm" \
    --arg msg "Application 'ubuntu' exists in state" \
    '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
else
  tasks=$(jq --argjson arr "$tasks" \
    --arg id "task-4" \
    --arg name "Deploy ubuntu charm" \
    --arg msg "Application 'ubuntu' not in state. Run 'terraform apply'." \
    '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
fi

# Task 5: Application is active in Juju
if juju_app_exists "development" "ubuntu"; then
  tasks=$(jq --argjson arr "$tasks" \
    --arg id "task-5" \
    --arg name "Verify with juju status" \
    --arg msg "Application 'ubuntu' is active in model 'development'" \
    '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
else
  tasks=$(jq --argjson arr "$tasks" \
    --arg id "task-5" \
    --arg name "Verify with juju status" \
    --arg msg "Application 'ubuntu' not found in model 'development'" \
    '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
fi

# Determine overall pass
all_pass=$(echo "$tasks" | jq '[.[].passed] | all')
emit_result "$all_pass" "$tasks"
