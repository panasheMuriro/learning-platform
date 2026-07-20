# Authoring Labs

This guide explains how to create new labs for the Juju + Terraform course.

## Lab structure

Each lab is a directory under `content/module-XX/lab-XX-name/`:

```
content/module-01/lab-01-first-model-app/
  lab.md          # Instructions shown in browser
  starter/        # Files copied into learner's workspace
    main.tf
    variables.tf
  check.sh        # Grading script (runs terraform/juju, emits JSON)
  setup.sh         # Environment setup (copies starter files, bootstraps if needed)
```

## 1. Write lab.md

Write instructions in Markdown. Follow the KodeKloud pedagogical patterns:

- **Numbered tasks** — break the lab into small steps
- **Collapsible hints** — use `<details><summary>Hint</summary>...</details>`
- **Error-driven tasks** — sometimes present a broken config and ask learners to fix it
- **Verify steps** — always end with a verification command (`juju status`, `terraform output`)

Example:
```markdown
## Task 1: Create a Juju model

Add a `juju_model` resource named "development" to `main.tf`.

<details>
<summary>💡 Hint</summary>

\`\`\`hcl
resource "juju_model" "development" {
  name = "development"
}
\`\`\`
</details>
```

## 2. Create starter files

Put partial or empty HCL files in `starter/`. These are copied into the
learner's working directory when the lab starts.

- `main.tf` — the main config (often with TODOs)
- `variables.tf` — variable definitions
- `versions.tf` — provider requirements (optional)

## 3. Write check.sh

The grading script. It runs real `terraform`/`juju` commands and emits a JSON
result that the backend parses.

**Source the shared helper:**
```bash
source "$(dirname "$0")/../../shared/check-helper.sh"
```

**Available helpers:**
- `tf_state_has <type> <name>` — check if a resource exists in terraform state
- `juju_app_exists <model> <app>` — check if a Juju application exists
- `tf_output <name>` — get a terraform output value
- `task <id> <name> <passed> <message>` — format a single task result
- `emit_result <passed> <tasks_json>` — emit the final JSON

**Required output format:**
```json
{
  "passed": true,
  "tasks": [
    {
      "id": "task-1",
      "name": "Create juju_model",
      "passed": true,
      "message": "Model 'development' exists in state"
    }
  ]
}
```

See `content/module-01/lab-01-first-model-app/check.sh` for a full example.

## 4. Write setup.sh

The environment setup script. Run when the lab starts or when "Reset" is clicked.

Typical setup.sh:
```bash
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${1:-$(pwd)}"

# Copy starter files
cp -rn "${SCRIPT_DIR}/starter/"* "${WORK_DIR}/" 2>/dev/null || true

# Ensure a Juju controller exists
if ! juju controllers --format json 2>/dev/null | jq -e '.controllers | length > 0' >/dev/null 2>&1; then
  juju bootstrap localhost course 2>&1 || true
fi

echo "Lab environment ready."
```

## 5. Register the lab in outline.json

Add the lab to the module's `labs` array in `content/outline.json`:

```json
{
  "id": "lab-04-my-new-lab",
  "title": "My New Lab"
}
```

## 6. Test your lab

1. Start the Workshop: `workshop launch`
2. Open the browser, navigate to your lab
3. Follow your own instructions to complete the lab
4. Click **Check** — verify it passes with a correct solution
5. Break your solution — verify **Check** fails with helpful messages

## Pedagogical guidelines

- **One concept per task** — don't combine too many things in one step
- **Progressive complexity** — start easy, build up
- **Reference earlier labs** — "This is similar to Task 3 in Lab 1…"
- **State literacy** — have learners inspect `terraform.tfstate` and `juju status`
- **Error-driven learning** — present broken configs and ask learners to fix them
- **Real tooling** — `check.sh` runs actual `terraform`/`juju`, not static checks
