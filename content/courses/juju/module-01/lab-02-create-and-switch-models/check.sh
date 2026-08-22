#!/usr/bin/env bash
source "$(dirname "$0")/../../shared/check-helper.sh"

SPECIFIC_TASK="${1:-}"

check_task_1() {
  if juju_model_exists "lab-dev"; then
    task "task-1" "Create model 'lab-dev'" true "Model 'lab-dev' exists."
  else
    task "task-1" "Create model 'lab-dev'" false "Model 'lab-dev' does not exist."
  fi
}

check_task_2() {
  if ! juju_model_exists "lab-dev"; then
    task "task-2" "Configure logging-config on 'lab-dev'" false "Model 'lab-dev' does not exist."
    return
  fi
  local val
  val=$(juju model-config -m lab-dev logging-config 2>/dev/null | tr -d '\r\n' || echo "")
  if [[ "$val" == "<root>=INFO" ]]; then
    task "task-2" "Configure logging-config on 'lab-dev'" true "logging-config is set to <root>=INFO on lab-dev."
  else
    task "task-2" "Configure logging-config on 'lab-dev'" false "logging-config on lab-dev is '$val', expected '<root>=INFO'."
  fi
}

check_task_3() {
  local has_staging current
  if ! juju_model_exists "lab-staging"; then
    task "task-3" "Create 'lab-staging' and switch active model to 'lab-dev'" false "Model 'lab-staging' does not exist."
    return
  fi
  current=$(juju_current_model)
  if [[ "$current" == "lab-dev" || "$current" == "admin/lab-dev" ]]; then
    task "task-3" "Create 'lab-staging' and switch active model to 'lab-dev'" true "Model 'lab-staging' exists and active model is '$current'."
  else
    task "task-3" "Create 'lab-staging' and switch active model to 'lab-dev'" false "Active model is '$current', expected 'lab-dev'."
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
