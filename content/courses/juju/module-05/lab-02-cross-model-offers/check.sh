#!/usr/bin/env bash
# Check script for Module 05 Lab 02: Cross-Model Relations & Offers

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

# Task 1: Models 'lab-cmr-provider' and 'lab-cmr-consumer' exist
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-1" ]; then
  prov_exists=$(juju_model_exists "lab-cmr-provider" && echo "yes" || echo "no")
  cons_exists=$(juju_model_exists "lab-cmr-consumer" && echo "yes" || echo "no")
  
  if [[ "$prov_exists" == "yes" && "$cons_exists" == "yes" ]]; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Create provider and consumer models" \
      --arg msg "Both 'lab-cmr-provider' and 'lab-cmr-consumer' exist." \
      '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
  else
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-1" --arg name "Create provider and consumer models" \
      --arg msg "Ensure both models are created: juju add-model lab-cmr-provider && juju add-model lab-cmr-consumer" \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  fi
fi

# Task 2: Provider application deployed and offer exists
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-2" ]; then
  if ! juju_model_exists "lab-cmr-provider"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-2" --arg name "Deploy provider application and create offer" \
      --arg msg "Model 'lab-cmr-provider' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  else
    has_app=$(juju status -m lab-cmr-provider --format json 2>/dev/null | jq -e '.applications | has("provider-app")' 2>/dev/null || echo "false")
    has_offer=$(juju offers -m lab-cmr-provider --format json 2>/dev/null | jq -e '.["proxy-offer"] // empty' >/dev/null 2>&1 && echo "yes" || echo "no")
    if [[ "$has_app" == "true" && "$has_offer" == "yes" ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-2" --arg name "Deploy provider application and create offer" \
        --arg msg "Application 'provider-app' deployed and offer 'proxy-offer' active." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-2" --arg name "Deploy provider application and create offer" \
        --arg msg "Deploy provider-app and create offer: juju deploy haproxy provider-app -m lab-cmr-provider && juju switch lab-cmr-provider && juju offer provider-app:reverseproxy proxy-offer" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  fi
fi

# Task 3: Consumer application deployed and cross-model relation established
if [ -z "$REQUESTED_TASK" ] || [ "$REQUESTED_TASK" = "task-3" ]; then
  if ! juju_model_exists "lab-cmr-consumer"; then
    tasks=$(jq --argjson arr "$tasks" \
      --arg id "task-3" --arg name "Deploy consumer and integrate cross-model offer" \
      --arg msg "Model 'lab-cmr-consumer' does not exist." \
      '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
  else
    has_cons_app=$(juju status -m lab-cmr-consumer --format json 2>/dev/null | jq -e '.applications | has("consumer-app")' 2>/dev/null || echo "false")
    # Check if consumer-app has an active relation or remote integration
    has_cmr_rel=$(juju status -m lab-cmr-consumer --format json 2>/dev/null | jq -e '.applications["consumer-app"].relations["website"][]? | select(.["related-application"] != null)' 2>/dev/null || echo "")
    if [[ "$has_cons_app" == "true" && -n "$has_cmr_rel" ]]; then
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Deploy consumer and integrate cross-model offer" \
        --arg msg "Cross-model integration established for 'consumer-app'." \
        '$arr + [{"id":$id,"name":$name,"passed":true,"message":$msg}]' <<< "$tasks")
    else
      tasks=$(jq --argjson arr "$tasks" \
        --arg id "task-3" --arg name "Deploy consumer and integrate cross-model offer" \
        --arg msg "Deploy consumer-app and integrate offer: juju deploy haproxy consumer-app -m lab-cmr-consumer && juju integrate consumer-app:website lab-cmr-provider.proxy-offer -m lab-cmr-consumer" \
        '$arr + [{"id":$id,"name":$name,"passed":false,"message":$msg}]' <<< "$tasks")
    fi
  fi
fi

all_passed=$(echo "$tasks" | jq '[.[].passed] | all')
emit_result "$all_passed" "$tasks"
