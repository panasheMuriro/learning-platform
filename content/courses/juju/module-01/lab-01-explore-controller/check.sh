#!/usr/bin/env bash
source "$(dirname "$0")/../../shared/check-helper.sh"

SPECIFIC_TASK="${1:-}"

check_task_1() {
  local version
  version=$(juju version 2>/dev/null || true)
  if [[ -n "$version" ]]; then
    task "task-1" "Check Juju CLI version" true "Juju CLI version: $version"
  else
    task "task-1" "Check Juju CLI version" false "Juju CLI command not found or not responding."
  fi
}

check_task_2() {
  local clouds
  clouds=$(juju clouds 2>/dev/null || true)
  if [[ -n "$clouds" ]]; then
    task "task-2" "List available clouds" true "Available clouds listed successfully."
  else
    task "task-2" "List available clouds" false "Failed to list clouds with 'juju clouds'."
  fi
}

check_task_3() {
  if juju_controller_exists; then
    task "task-3" "Inspect controller status" true "Juju controller is reachable."
  else
    task "task-3" "Inspect controller status" false "No reachable Juju controller found."
  fi
}

if [[ -n "$SPECIFIC_TASK" ]]; then
  case "$SPECIFIC_TASK" in
    task-1) t=$(check_task_1) ;;
    task-2) t=$(check_task_2) ;;
    task-3) t=$(check_task_3) ;;
    *) echo "Unknown task: $SPECIFIC_TASK" >&2; exit 1 ;;
  esac
  p=$(echo "$t" | jq -r '.passed')
  emit_result "$p" "[$t]"
  exit 0
fi

t1=$(check_task_1)
t2=$(check_task_2)
t3=$(check_task_3)

p1=$(echo "$t1" | jq -r '.passed')
p2=$(echo "$t2" | jq -r '.passed')
p3=$(echo "$t3" | jq -r '.passed')

if [[ "$p1" == "true" && "$p2" == "true" && "$p3" == "true" ]]; then
  all_passed=true
else
  all_passed=false
fi

emit_result "$all_passed" "[$t1, $t2, $t3]"
