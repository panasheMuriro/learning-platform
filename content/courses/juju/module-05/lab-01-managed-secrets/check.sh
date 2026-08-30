#!/usr/bin/env bash
# Check script for Module 05 Lab 01: Managed Secrets Lifecycle

set -euo pipefail

# Dynamic helper resolution
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

# Task 1: Model 'lab-secrets' exists and 'web-service' application is deployed
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-1" ]; then
  if ! juju_model_exists "lab-secrets"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Create model and deploy web-service" \
      --arg msg "Model 'lab-secrets' does not exist. Run: juju add-model lab-secrets" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  else
    has_app=$(juju status -m lab-secrets --format json 2>/dev/null | jq -e '.applications | has("web-service")' 2>/dev/null || echo "false")
    if [[ "$has_app" == "true" ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-1" --arg name "Create model and deploy web-service" \
        --arg msg "Model 'lab-secrets' and application 'web-service' exist." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-1" --arg name "Create model and deploy web-service" \
        --arg msg "Application 'web-service' not found. Run: juju deploy ubuntu web-service -m lab-secrets" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  fi
fi

# Task 2: Secret 'app-token' exists
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-2" ]; then
  if ! juju_model_exists "lab-secrets"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Create managed secret" \
      --arg msg "Model 'lab-secrets' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  else
    has_secret=$(juju list-secrets -m lab-secrets --format json 2>/dev/null | jq -e '.[] | select(.name == "app-token")' >/dev/null 2>&1 && echo "yes" || echo "no")
    if [[ "$has_secret" == "yes" ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-2" --arg name "Create managed secret" \
        --arg msg "Secret 'app-token' created in model 'lab-secrets'." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-2" --arg name "Create managed secret" \
        --arg msg "Secret 'app-token' not found. Run: juju add-secret app-token token=supersecret123 -m lab-secrets" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  fi
fi

# Task 3: Secret 'app-token' granted to 'web-service'
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-3" ]; then
  if ! juju_model_exists "lab-secrets"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Grant secret to web-service" \
      --arg msg "Model 'lab-secrets' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  else
    has_grant=$(juju show-secret app-token -m lab-secrets --format json 2>/dev/null | jq -e '.[].access[]? | select(.target == "application-web-service" or .target == "web-service")' >/dev/null 2>&1 && echo "yes" || echo "no")
    if [[ "$has_grant" == "yes" ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Grant secret to web-service" \
        --arg msg "Secret 'app-token' is granted to application 'web-service'." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Grant secret to web-service" \
        --arg msg "Secret 'app-token' not granted to 'web-service'. Run: juju grant-secret app-token web-service -m lab-secrets" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  fi
fi

all_passed=$(echo "$tasks" | jq '[.[].passed] | all')
emit_result "$all_passed" "$tasks"
